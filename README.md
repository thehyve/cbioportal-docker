# cbioportal-docker

Download and install Docker from www.docker.com.

#### Notes for non-Linux systems

##### Docker for Mac/Windows (newer versions)
Make sure to assign enough memory to Docker when using Docker for Windows (Windows 10 Pro 64-bit) or Docker for Mac (Mac OS X Yosemite 10.10.3 or above). In Mac OS X this can be set when clicked on the Docker icon -> Preferences... -> Adjust the Memory slider. By default it's set to 2 GB, which is too low and causes problems when loading multiple studies.

##### Docker-machine (older versions)
Because the Docker Engine daemon uses Linux-specific kernel features, you can’t run Docker Engine natively in Windows or Mac OS X. In versions of these systems that do not support the newer lightweight virtualisation technologies mentioned above, you must instead use the Docker Machine command, `docker-machine`. This creates and attaches to a small Linux VM on your machine, which hosts Docker Engine.

The Docker Quickstart Terminal in the Docker Toolbox will automatically create a default VM for you (`docker-machine create`), boot it up (`docker-machine start`) and set environment variables in the running shell to transparently forward the docker commands to the VM (`eval $(docker-machine env)`). Do note however, that forwarded ports in the docker commands will pertain to the VM and not your Windows/OS X system. The local cBioPortal and MySQL servers will not be available on `localhost` or `127.0.0.1`, but on the address printed by the command `docker-machine ip`, unless you configure VirtualBox to further forward the port to the host system.

#### Step 1 - Setup network
Create a network in order for the cBioPortal container and mysql database to communicate.
```
docker network create cbio-net
```

#### Step 2 - Run mysql with seed database
Download the seed database from https://github.com/cBioPortal/cbioportal/blob/master/docs/Downloads.md#seed-database

This command imports the seed database file into a database stored in
`/path_to_save_mysql_db/db_files/` (:warning: this should be an absolute path in command below), before starting the MySQL server.

```
docker run -d --name "cbioDB" \
  --restart=always \
  --net=cbio-net \
  -p 8306:3306 \
  -e MYSQL_ROOT_PASSWORD=P@ssword1 \
  -e MYSQL_USER=cbio \
  -e MYSQL_PASSWORD=P@ssword1 \
  -e MYSQL_DATABASE=cbioportal \
  -v /path_to_save_mysql_db/db_files/:/var/lib/mysql/ \
  -v /path_to_seed_database/cbioportal-seed.sql.gz:/docker-entrypoint-initdb.d/cbioportal-seed.sql.gz:ro \
  mysql
```

#### Step 3 - Build the Docker image containing cBioPortal
Checkout the repository, enter the directory and run build the image.

```
git clone https://github.com/thehyve/cbioportal-docker.git
docker build -t custom/cbioportal .
```

Alternatively, if you do not wish to change anything in the Dockerfile or the properties, you can run:

```
docker build -t cbioportal https://github.com/thehyve/cbioportal-docker.git
```

#### Step 4 - Run the cBioPortal container
```
docker run -d --name="cbioportal" \
  --restart=always \
  --net=cbio-net \
  -p 8081:8080 \
  custom/cbioportal
```

cBioPortal can now be reached at http://localhost:8081/cbioportal/

Activity of Docker containers can be seen with:
```
docker ps -a
```

## Uninstalling cBioPortal
First we stop the Docker containers.
```
docker stop cbioDB
docker stop cbioportal
```

Then we remove the Docker containers.
```
docker rm cbioDB
docker rm cbioportal
```

Cached Docker images can be seen with:
```
docker images
```

Finally we remove the cached Docker images.
```
docker rmi mysql
docker rmi custom/cbioportal
```

## Data Loading & More commands

For more uses of the cBioPortal image, see [example_commands.md](example_commands.md)
