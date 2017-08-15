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

TODO: add passwords, ldappasswd?

TODO: document `ldapsearch` for searching the tree and `ldapdelete` for deleting entries
