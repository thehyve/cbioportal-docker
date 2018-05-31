### Importing data ###

Use this command to validate a dataset in the folder `./study-dir`, connecting
to the web API of the container `cbioportal-container`, and import it into the
database configured in the image, saving an html report of the validation to
`~/Desktop/report.html`.  Note that the paths given to the `-v` option must be
absolute paths.

```shell
docker run -it --rm --net cbio-net \
    -v "$PWD/study-dir:/study:ro" \
    -v "$HOME/Desktop:/outdir" \
    cbioportal-image \
    metaImport.py -u http://cbioportal-container:8080/cbioportal -s /study --html=/outdir/report.html
```
:warning: after importing a study, remember to restart `cbioportal-container` to see the study in the home page. Run `docker restart cbioportal-container`

#### Using cached portal side-data ####

In some setups the data validation step may not have direct access to the web API, for instance when the web API is only accessible to authenticated browser sessions. You can use this command to generate a cached folder of files that the validation script can use instead:

```shell
docker run --rm --net cbio-net \
    -v "$PWD/portalinfo:/portalinfo" \
    -w /cbioportal/core/src/main/scripts \
    cbioportal-image \
    ./dumpPortalInfo.pl /portalinfo
```

Then, grant the validation/loading command access to this folder and tell the script it to use it instead of the API:

```shell
docker run -it --rm --net cbio-net \
    -v "$PWD/study-dir:/study:ro" \
    -v "$HOME/Desktop:/outdir" \
    -v "$PWD/portalinfo:/portalinfo:ro" \
    cbioportal-image \
    metaImport.py -p /portalinfo -s /study --html=/outdir/report.html
```

#### Public data sets ####
A catalogue of compatible public study data can be found in
[this snapshot of the Datahub project](https://github.com/cBioPortal/datahub/tree/47c1c0a987ee2873b3f043252ea077df3146d86b/public).
Use one of the methods described in
[this Stack Overflow discussion](https://stackoverflow.com/questions/7106012/download-a-single-folder-or-directory-from-a-github-repo)
to download study folders you're interested in, or install `git` and `git-lfs`
and run commands such as the following:
```
git  clone --single-branch -b rc https://github.com/cBioPortal/datahub.git
cd datahub
git checkout 47c1c0a987ee2873b3f043252ea077df3146d86b
git lfs install --local --skip-smudge
cd public
git lfs pull -I brca_tcga
```
Substituting any data set you may want for the TCGA provisional breast cancer
study.

### Importing data (method 2) ###

Similar to the method above, but here you open a bash shell in an otherwise idle container and run the commands there.

#### Step 1 (one time only for a specific image) ####

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

#### Step 2 ####

Run bash in the container and execute the import command.

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

When creating the database container, you can map a port on the
local host to port 3306 of the container running the MySQL database,
by adding an option such as `-p 127.0.0.1:8306:3306` to the `docker
run` command before the name of the image (`mysql:5.7`).  You can then
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
    mysql:5.7 \
    sh -c 'mysql -h"$MYSQL_HOST" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE"'
```
