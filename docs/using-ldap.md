# Set up LDAP locally for testing #

LDAP is a protocol to access services representing data in the shape
of a directory. Roughly, a directory is a browsable hierarchy of
_entries_, each of which can have a number of _attributes_. The
semantics of the attributes is defined in a schema. This information
model is rather different from the table-based one you might be
familiar with from relational databases. It is often used to represent
details of persons grouped by units of an organisation, or
specifically for those persons' user account details.

I forked the Docker image building context for
[`dinkel/openldap`](https://hub.docker.com/r/dinkel/openldap/);
my version with a few adjustments can be found
[on GitHub](https://github.com/fedde-s/docker-openldap/tree/master).
It can be built directly from the Git repository.

```shell
docker build -t openldap:withtools https://github.com/fedde-s/docker-openldap.git#master
```

Create an isolated Docker network in which the container can
communicate with other containers, unless you want to reuse an
existing one.

```shell
docker network create authnet
```

Run the `slapd` server in a container connected to this network,
initialising it with a domain and and admin user password and giving
it read-write access to persistent data volumes for its configuration
and data.

```shell
docker run -d --restart=always \
    --name=ldap-server \
    --net=authnet \
    -v ldap-conf:/etc/ldap \
    -v ldap-data:/var/lib/ldap \
    -e SLAPD_PASSWORD=mysecretpassword \
    -e SLAPD_DOMAIN=cbio.local \
    openldap:withtools
```

To add user entries to this database, create an LDIF file defining
their uniquely qualified _distinguished names_ (`dn`), the _object
class_ of the entries that you use to represent your user details,
and any _attributes_ that have been defined to make sense for these
object classes. A nicely browsable list of commonly used classes can
be found [here](http://www.zytrax.com/books/ldap/ape/). The
distinguished name places the entries somewhere in the tree, often in
terms of internet domain components (`dc`) and organisational units
(`ou`).

In this example, the `inetOrgPerson` class requires them to have
surnames (the `sn` attribute), and common names (`cn`), and states
that it makes sense for them to have email addresses (`mail`) and user
IDs (`uid`), among other attributes.

```ldif
dn: ou=people,dc=cbio,dc=local
objectclass: organizationalUnit
ou: people

dn: uid=foo,ou=people,dc=cbio,dc=local
objectclass: inetOrgPerson
uid: foo
sn: Vanderfoo
cn: Foo Vanderfoo
cn: Foo Tiberius Vanderfoo

dn: uid=bar,ou=people,dc=cbio,dc=local
objectclass: inetOrgPerson
uid: bar
sn: Barson
cn: Bar Barson
mail: bar@cbio.local
```

These users can then be loaded into the database by running ldapadd in
a container that has read access to the ldif file, binding to the
database using simple authentication (`-x`) with a password prompt
(`-W`) for the admin user, identified by the user's distinguished
name.

```shell
docker run --rm -it \
    --net=authnet \
    -v "$PWD/<your_file_name>.ldif:/in.ldif:ro" \
    openldap:withtools \
    ldapadd -H ldap://ldap-server -xWD cn=admin,dc=cbio,dc=local -f /in.ldif
```

Next, the users should be granted passwords so that they can log
in. This will (for now) set the `userPassword` attributes of the user
entries, storing salted SHA-1 hashes. The following command will
prompt for a password for the first user in the example file above,
while (again) authenticating as the admin user to make the change:

```shell
docker run --rm -it \
    --net=authnet \
    openldap:withtools \
    ldappasswd -H ldap://ldap-server -xWD cn=admin,dc=cbio,dc=local -S \
        uid=foo,ou=people,dc=cbio,dc=local
```

You can use the `ldapsearch` command to look at the data in the
database. The command line below will list the surnames and common
names of any entries that have a surname starting with _van_ within
our domain, displayed in a minimal format (specified by `-LLL`).

```shell
docker run --rm -it \
    --net=authnet \
    openldap:withtools \
    ldapsearch -H ldap://ldap-server -xWD cn=admin,dc=cbio,dc=local \
        -LLL -b dc=cbio,dc=local '(sn=van*)' sn cn
```

The argument to `-b` specifies the subtree to be searched, the
parenthesised text is a filter string (other operators are available
for more complex queries), and the enumeration of attribute types
specifies which attributes to display. The latter two both default to
displaying all if left out.

See the man page on the
[`ldapmodify(1)`](https://manpages.debian.org/stretch/ldap-utils/ldapmodify.1.en.html)
command to modify entries according to specifications in the LDIF
format, or try `ldapdelete(1)` to delete individual entries or
recursively delete subtrees.

TODO: suggest a bind role with read-only access
