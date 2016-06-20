docker run -d --name "cbioDB" \
    --net=cbio-net \
    -e MYSQL_ROOT_PASSWORD=P@ssword1 \
    -e MYSQL_USER=cbio \
    -e MYSQL_PASSWORD=P@ssword1 \
    -e MYSQL_DATABASE=cbioportal \
    -v "$HOME"/data/cbioportal-seed.sql:/docker-entrypoint-initdb.d/cbioportal-seed.sql:ro \
    mysql

docker run -dp 8081:8080 --net=cbio-net --name=cbioportal <image>

docker run --rm -it --net cbio-net \
    <image> \
    migrate_db.py -p /cbioportal/src/main/resources/portal.properties -s /cbioportal/core/src/main/resources/db/migration.sql

docker run --rm --net cbio-net \
    -v "$PWD"/study_es_0:/study:ro
    -v "$HOME"/Desktop:/outdir \
    <image> \
    metaImport.py -u http://cbioportal:8080/cbioportal -s /study --html=/outdir/report.html

docker run -it --rm \
    --net=cbio-net \
    -e MYSQL_HOST=cbioDB \
    -e MYSQL_USER=cbio \
    -e MYSQL_PASSWORD=P@ssword1 \
    -e MYSQL_DATABASE=cbioportal \
    mysql \
    sh -c 'mysql -h"$MYSQL_HOST" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE"'

docker run --rm \
    -p 8000:8000 \
    -p 8080:8080 \
    -e JPDA_ADDRESS=0.0.0.0:8000 \
    -v "$HOME"/cbioportal:/cbioportal \
    --net=cbio-net \
    --name=cbioportal-dev \
    <image> \
    catalina.sh jpda run

docker run --rm \
    -p 8081:8080 \
    -e CBIO_GIT_BRANCH=rc \
    --net=cbio-net \
    --name=cbioportal-test \
    <image>

# testing:
docker run -p 8083:8080 --net='cbio-net' --name='cbio_testentrypoint' \
    -v "$PWD"/docker-entrypoint.sh:/usr/local/bin/docker-entrypoint.sh:ro \
    -v "$PWD"/portal.properties.patch:/portal_config/portal.properties.patch:ro \
    fschaeffer/cbioportal-configured \
    sh -c 'rm src/main/resources/portal.properties && docker-entrypoint.sh catalina.sh run'
