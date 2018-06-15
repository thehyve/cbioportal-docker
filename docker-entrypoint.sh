#!/bin/sh -e

patch "$CATALINA_HOME/conf/server.xml" </cbioportal/catalina_server.xml.patch
patch "$CATALINA_HOME/conf/context.xml" </cbioportal/catalina_context.xml.patch

if [ -e /cbioportal/portal.properties ]
then
	cp /cbioportal/portal.properties /cbioportal/src/main/resources/portal.properties
fi

cp \
	/cbioportal/src/main/resources/portal.properties \
	"$CATALINA_HOME/webapps/cbioportal/src/main/webapps/cbioportal/src/main/resources"
cp \
	/cbioportal/src/main/resources/log4j.properties \
	"$CATALINA_HOME/webapps/cbioportal/src/main/webapps/cbioportal/src/main/resources"

exec "$@"
