### Importing data ###

Use this command to validate a dataset in the folder `./study-dir`, connecting
to the web API of the container `cbioportal-container`, and import it into the
database configured in the image, saving an html report of the validation to
`~/Desktop/report.html`.  Note that the paths given to the `-v` option must be
absolute paths.

```shell
docker run --rm --net cbio-net \
    -v "$PWD"/study-dir:/study:ro \
    -v "$HOME"/Desktop:/outdir \
    cbioportal-image \
    metaImport.py -u http://cbioportal-container:8080/cbioportal -s /study --html=/outdir/report.html
```
:warning: after importing a study, remember to restart `cbioportal-container` to see the study in the home page. Run `docker restart cbioportal-container`

### Importing data (method 2) ###

Similar to the method above, but here you open a bash on the container itself and execute the commands there. 

###### Step 1 (one time only for a specific image)

Set up the container `importer-container` mapping the input and output dirs with `-v` parameters:

```shell
docker run -d --name="importer-container" \
  --restart=always \
  --net=cbio-net \
   -v "$PWD"/study-dir:/study:ro \
   -v "$HOME"/Desktop:/outdir \
  cbioportal-image
```
###### Step 2

Open bash on container and execute the import command.

```shell
docker exec -it importer-container bash
```
The import command:
```shell
 metaImport.py -u http://cbioportal-container:8080/cbioportal -s /study --html=/outdir/report.html
```

### Running cBioPortal code from a local folder ###

If you have checked out (or modified) a git branch locally in `~/cbioportal`
and you want to run or debug it, you can use the following command. Note that
the path given to the `-v` option must be an absolute path. The mapping for
port 8000 and the references to JPDA open a port for remote debugging software
to attach. The image is used as a runtime environment and as a cache for
dependencies when compiling, while the `portal.properties` file will be read
from the source folder.

```shell
docker run --rm \
    -p 8000:8000 \
    -p 8080:8080 \
    -v "$HOME"/cbioportal:/cbioportal \
    --net=cbio-net \
    --name=cbioportal-dev \
    cbioportal-image \
    sh -c 'mvn -DskipTests clean install && rm -f "$CATALINA_HOME/webapps/cbioportal.war" && unzip portal/target/cbioportal*.war -d "$CATALINA_HOME/webapps/cbioportal/" && JPDA_ADDRESS=0.0.0.0:8000 exec catalina.sh jpda run'
```

### Testing cBioPortal code from a GitHub branch ###

If you want to run and test code from a branch you have not checked out
locally, say from someone else’s pull request, you can use a command like the
following. This example checks out the `rc` branch of the GitHub repository for
`thehyve`.

```shell
docker run --rm \
    -p 8081:8080 \
    --net=cbio-net \
    --name=cbioportal-test \
    cbioportal-image \
    sh -c 'git fetch https://github.com/thehyve/cbioportal.git rc && git checkout FETCH_HEAD && mvn -DskipTests clean install && rm -f "$CATALINA_HOME/webapps/cbioportal.war" && unzip portal/target/cbioportal*.war -d "$CATALINA_HOME/webapps/cbioportal/" && exec catalina.sh run'
```

### Inspecting or adjusting the database ###

If you have mapped a port on the host to port 3306 of the container
running the MySQL database, using an option such as `-p 8306:3306`,
you can connect to this port (localhost:8306) using [MySQL
Workbench](https://www.mysql.com/products/workbench/) or another
MySQL client.  Alternatively, you can connect a command-line client
to the container (named `cbioDB` in this example) via the `--net`
option with the following command:

```shell
docker run -it --rm \
    --net=cbio-net \
    -e MYSQL_HOST=cbioDB \
    -e MYSQL_USER=cbio \
    -e MYSQL_PASSWORD=P@ssword1 \
    -e MYSQL_DATABASE=cbioportal \
    mysql \
    sh -c 'mysql -h"$MYSQL_HOST" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE"'
```

### Updating the database schema ###

If the portal tells you that your database schema is outdated, you
can update it to match the cBioPortal version in the image by running
the following command. Note that this will most likely make your
database irreversibly incompatible with older versions of the portal
code.

```shell
docker run --rm -it --net cbio-net \
    cbioportal-image \
    migrate_db.py -p /cbioportal/src/main/resources/portal.properties -s /cbioportal/core/src/main/resources/db/migration.sql
```
