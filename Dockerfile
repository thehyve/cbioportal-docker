#
# Copyright (c) 2016 The Hyve B.V.
# This code is licensed under the GNU Affero General Public License (AGPL),
# version 3, or (at your option) any later version.
#

FROM tomcat:8-jre8
MAINTAINER Fedde Schaeffer <fedde@thehyve.nl>

# install build and runtime dependencies and configure Tomcat for production
RUN apt-get update && apt-get install -y --no-install-recommends \
		git \
		libmysql-java \
		maven \
		openjdk-8-jdk \
		patch \
		python \
		python-jinja2 \
		python-mysqldb \
		python-requests \
	&& rm -rf /var/lib/apt/lists/* \
	&& ln -s /usr/share/java/mysql-connector-java.jar "$CATALINA_HOME"/lib/ \
	&& rm -rf $CATALINA_HOME/webapps/*m* 
	

# fetch the cBioPortal sources and version control metadata
ENV PORTAL_HOME=/cbioportal
RUN git clone --depth 1 -b v1.13.2 'https://github.com/cBioPortal/cbioportal.git' $PORTAL_HOME
WORKDIR $PORTAL_HOME

# add default configuration baked in at build-time
COPY portal.properties $PORTAL_HOME
COPY log4j.properties src/main/resources/log4j.properties

# install default config files, build and install, placing the scripts jar back
# in the target folder where import scripts expect it after cleanup
RUN cp portal.properties src/main/resources/portal.properties \
	&& mvn -DskipTests clean package \
	&& unzip portal/target/cbioportal-*.war -d $CATALINA_HOME/webapps/cbioportal \
	&& mv scripts/target/scripts-*.jar /root/ \
	&& mvn clean \
	&& mkdir scripts/target/ \
	&& mv /root/scripts-*.jar scripts/target/

# add importer scripts to PATH for easy running in containers
RUN find $PWD/core/src/main/scripts/ -type f -executable \! -name '*.pl'  -print0 | xargs -0 -- ln -st /usr/local/bin
# TODO: fix the workdir-dependent references to '../scripts/env.pl' and do this:
# RUN find $PWD/core/src/main/scripts/ -type f -executable \! \( -name env.pl -o -name envSimple.pl \)  -print0 | xargs -0 -- ln -st /usr/local/bin

# add default configuration applied by the entrypoint script
COPY ./catalina_context.xml.patch /cbioportal/
COPY ./catalina_server.xml.patch /cbioportal/

COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["catalina.sh", "run"]
