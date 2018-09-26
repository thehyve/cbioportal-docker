# cbioportal-docker @ The Hyve #

The [cBioPortal](https://github.com/cBioPortal/cbioportal) project documents a setup to deploy a cBioPortal server using Docker, in [this section of the documentation](https://cbioportal.readthedocs.io/en/latest/#docker). As cBioPortal traditionally does not distinguish between build-time and deploy-time configuration, the setup documented there builds the application at runtime, and suggests running auxiliary commands in the same container as the webserver. The above approach may sacrifice a few advantages of using Docker by going against some of its idioms. For this reason, the project you are currently looking at documents an alternative setup, which builds a ready-to-run cBioPortal application into a Docker image.

To get started, download and install Docker from www.docker.com.

[Notes for non-Linux systems](docs/notes-for-non-linux.md)

## Usage instructions ##

### Step 1 - Setup network ###
Create a network in order for the cBioPortal container and mysql database to communicate.
```
docker network create cbio-net
```

### Step 2 - Run mysql with seed database ###
Start a MySQL server. The command below stores the database in a folder named
`/<path_to_save_mysql_db>/db_files/`. This should be an absolute path, that
does *not* point to a directory already containing database files.

```
docker run -d --restart=always \
  --name=cbioDB \
  --net=cbio-net \
  -e MYSQL_ROOT_PASSWORD='P@ssword1' \
  -e MYSQL_USER=cbio \
  -e MYSQL_PASSWORD='P@ssword1' \
  -e MYSQL_DATABASE=cbioportal \
  -v /<path_to_save_mysql_db>/db_files/:/var/lib/mysql/ \
  mysql:5.7
```

Download the seed database from the
[cBioPortal Datahub](https://github.com/cBioPortal/datahub/blob/master/seedDB/README.md),
and use the command below to upload the seed data to the server started above.

Make sure to replace
`/<path_to_seed_database>/seed-cbioportal_<genome_build>_<seed_version>.sql.gz`
with the path and name of the downloaded seed database. Again, this should be
an absolute path.

```
docker run \
  --name=load-seeddb \
  --net=cbio-net \
  -e MYSQL_USER=cbio \
  -e MYSQL_PASSWORD='P@ssword1' \
  -v /<path_to_seed_database>/cgds.sql:/mnt/cgds.sql:ro \
  -v /<path_to_seed_database>/seed-cbioportal_<genome_build>_<seed_version>.sql.gz:/mnt/seed.sql.gz:ro \
  mysql:5.7 \
  sh -c 'cat /mnt/cgds.sql | mysql -hcbioDB -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" cbioportal \
      && zcat /mnt/seed.sql.gz |  mysql -hcbioDB -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" cbioportal'
```

Follow the logs of this step to ensure that no errors occur. If any error
occurs, make sure to check it. A common cause is pointing the `-v` parameters
above to folders or files that do not exist.

### Step 3 - Build the Docker image containing cBioPortal ###
Run the command below to build the latest version.

```
docker build -t cbioportal-image https://github.com/thehyve/cbioportal-docker.git
```

If you want to build an image based on a different branch, you can read
[this](docs/adjusting_configuration.md#use-a-different-cbioportal-branch).

### Step 4 - Update the database schema ###

Obtain the [`portal.properties`](https://github.com/thehyve/cbioportal-docker/blob/master/portal.properties).
configuration file for the Docker setup from this repository.

Update the seeded database schema to match the cBioPortal version
in the image, by running the following command. Note that this will
most likely make your database irreversibly incompatible with older
versions of the portal code.

```
docker run --rm -it --net cbio-net \
    -v /<path_to_config_file>/portal.properties:/cbioportal/portal.properties:ro \
    cbioportal-image \
    migrate_db.py -p /cbioportal/portal.properties -s /cbioportal/db-scripts/src/main/resources/migration.sql
```

### Step 5 - Run the cBioPortal web server ###

Add any cBioPortal configuration in `portal.properties` as appropriate—see
the documentation on the
[main properties](https://github.com/cBioPortal/cbioportal/blob/master/docs/portal.properties-Reference.md)
and the
[skin properties](https://github.com/cBioPortal/cbioportal/blob/master/docs/Customizing-your-instance-of-cBioPortal.md).
Then start the web server as follows.

```
docker run -d --restart=always \
    --name=cbioportal-container \
    --net=cbio-net \
    -v /<path_to_config_file>/portal.properties:/cbioportal/portal.properties:ro \
    -e CATALINA_OPTS='-Xms2g -Xmx4g' \
    -p 8081:8080 \
    cbioportal-image
```

On server systems that can easily spare 4 GiB or more of memory,
set the `-Xms` and `-Xmx` options to the same number. This should
increase performance of certain memory-intensive web services such
as computing the data for the co-expression tab. If you are using
MacOS or Windows, make sure to take a look at [these
notes](docs/notes-for-non-linux.md) to allocate more memory for the
virtual machine in which all Docker processes are running.

cBioPortal can now be reached at <http://localhost:8081/cbioportal/>

Activity of Docker containers can be seen with:
```
docker ps -a
```

## Data loading & more commands ##
For more uses of the cBioPortal image, see [this file](docs/example_commands.md)

To build images from development source
rather than stable releases or snapshots, see
[development.md](docs/development.md).

To Dockerize a Keycloak authentication service alongside cBioPortal,
see [this file](docs/using-keycloak.md).

## Uninstalling cBioPortal ##
First we stop the Docker containers.
```
docker stop cbioDB
docker stop cbioportal-container
```

Then we remove the Docker containers.
```
docker rm cbioDB
docker rm cbioportal-container
```

Cached Docker images can be seen with:
```
docker images
```

Finally we remove the cached Docker images.
```
docker rmi mysql:5.7
docker rmi cbioportal-image
```
