# cbioportal-docker
Download docker from www.docker.com. Make sure to assign enough memory to Docker when using Docker for Windows (Windows 10 Pro) or Docker for Mac (macOS Yosemite 10.10.3 or above). In macOS this can be set when clicked on the Docker icon -> Preferences... -> Adjust the Memory slider. By default it's set to 2 GB, which is too low and causes problems when loading multiple studies.

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
