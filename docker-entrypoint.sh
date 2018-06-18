#!/bin/sh -e

patch "$CATALINA_HOME/conf/server.xml" <"$PORTAL_HOME/catalina_server.xml.patch"
patch "$CATALINA_HOME/conf/context.xml" <"$PORTAL_HOME/catalina_context.xml.patch"

exec "$@"
