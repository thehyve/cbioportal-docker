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

Similar to the method above, but here you open a bash shell in an otherwise idle container and run the commands there.

###### Step 1 (one time only for a specific image)

Set up the container `importer-container` mapping the input and
output dirs with `-v` parameters, and keep it running idle in the
background:

```shell
docker run -d --name="importer-container" \
  --restart=always \
  --net=cbio-net \
   -v "$PWD"/study-dir:/study:ro \
   -v "$HOME"/Desktop:/outdir \
  cbioportal-image tail -f /dev/null
```

###### Step 2

Run bash in the container and execute the import command.

```shell
docker exec -it importer-container bash
```
The import command:
```shell
 metaImport.py -u http://cbioportal-container:8080/cbioportal -s /study --html=/outdir/report.html
```

### Running cBioPortal code from a local folder ###

TODO: document building images based on a different online git
branch or a local folder, and using volumes to overwrite frontend
resources on the fly

### Testing cBioPortal code from a GitHub branch ###

### Inspecting or adjusting the database ###

When creating the database container, you can map a port on the
local host to port 3306 of the container running the MySQL database,
by adding an option such as `-p 127.0.0.1:8306:3306` to the `docker
run` command before the name of the image (`mysql`).  You can then
connect to this port (port 8306 in this example) using [MySQL
Workbench](https://www.mysql.com/products/workbench/) or another
MySQL client.

If you have not opened a port, the following command can still
connect a command-line client to the container (`cbioDB` here)
using the `--net` option:

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
