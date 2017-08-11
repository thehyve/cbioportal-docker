# Set up LDAP locally for testing #

TODO: introduce that LDAP is a directory database

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

TODO: mention object classes and associate attributes with classes

To add user entries to this database, create an LDIF file defining
their uniquely qualified ‘distinguished names’ (`dn`), their surnames
(`sn`), and their ‘common names’ (`cn`), among any other attributes.

```ldif
dn: cn=Foo Vanderfoo,dc=cbio,dc=local
objectclass: inetOrgPerson
objectclass: organizationalPerson
sn: Vanderfoo
cn: Foo Vanderfoo
cn: Van the Man

dn: cn=Bar Barson,dc=cbio,dc=local
objectclass: inetOrgPerson
objectclass: organizationalPerson
sn: Barson
cn: Bar Barson
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
