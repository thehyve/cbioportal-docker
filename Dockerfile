#
# Copyright (c) 2016 The Hyve B.V.
# This code is licensed under the GNU Affero General Public License (AGPL),
# version 3, or (at your option) any later version.
#

FROM tomcat:8-jre8
MAINTAINER Fedde Schaeffer <fedde@thehyve.nl>

# install build and runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
		libmysql-java \
		openjdk-8-jdk="$JAVA_DEBIAN_VERSION" \
		patch \
		python \
		python-jinja2 \
		python-mysqldb \
		python-requests \
	&& rm -rf /var/lib/apt/lists/* \
	# set up Tomcat to use the MySQL Connector/J Java connector
	&& ln -s /usr/share/java/mysql-connector-java.jar "$CATALINA_HOME"/lib/ \
	# remove the example apps that come with Tomcat for security reasons
	&& rm -rf $CATALINA_HOME/webapps/examples/

# fetch the cBioPortal sources, without keeping git and its deps in the image
ENV PORTAL_SRC=/cbioportal
RUN apt-get update && apt-get install -y --no-install-recommends git \
	&& rm -rf /var/lib/apt/lists/* \
	&& git clone --depth 1 -b v1.3.1 'https://github.com/cBioPortal/cbioportal.git' $PORTAL_SRC \
	&& apt-get purge -y git && apt-get autoremove -y --purge
WORKDIR $PORTAL_SRC

# add buildtime configuration
COPY ./portal.properties.patch /root/

# install default config files, build and install
RUN apt-get update && apt-get install -y --no-install-recommends maven \
	&& rm -rf /var/lib/apt/lists/* \
	&& cp src/main/resources/portal.properties.EXAMPLE src/main/resources/portal.properties \
	&& patch src/main/resources/portal.properties </root/portal.properties.patch \
	&& cp src/main/resources/log4j.properties.EXAMPLE src/main/resources/log4j.properties \
	&& mvn -DskipTests clean install \
	&& mv portal/target/cbioportal-*.war $CATALINA_HOME/webapps/cbioportal.war \
	&& mvn clean \
	&& apt-get purge -y maven && apt-get autoremove -y --purge
ENV PORTAL_HOME=$CATALINA_HOME/webapps/cbioportal

# add runtime configuration
COPY ./catalina_server.xml.patch /root/
RUN patch $CATALINA_HOME/conf/server.xml </root/catalina_server.xml.patch
COPY ./catalina_context.xml.patch /root/
RUN patch $CATALINA_HOME/conf/context.xml </root/catalina_context.xml.patch

# add importer scripts to PATH for easy running in containers
RUN find $PWD/core/src/main/scripts/ -type f -executable \! -name '*.pl'  -print0 | xargs -0 -- ln -st /usr/local/bin
# TODO: fix the workdir-dependent references to '../scripts/env.pl' and do this:
# RUN find $PWD/core/src/main/scripts/ -type f -executable \! \( -name env.pl -o -name envSimple.pl \)  -print0 | xargs -0 -- ln -st /usr/local/bin
