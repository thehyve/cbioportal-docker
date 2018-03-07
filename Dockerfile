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

ARG BRANCH=master
ARG COMMIT=
ARG REPOSITORY=https://github.com/cBioPortal/cbioportal.git

LABEL thehyve.cbioportal.commit="${COMMIT}" thehyve.cbioportal.branch="${BRANCH}" thehyve.cbioportal.repository="${REPOSITORY}"
LABEL thehyve.dockerfile.repository="https://github.com/thehyve/cbioportal-docker.git"

ENV PORTAL_HOME=/cbioportal

# fetch the cBioPortal sources and version control metadata
RUN echo "git clone --single-branch --depth 1 -b ${BRANCH} ${REPOSITORY} ${PORTAL_HOME}" ; git clone --single-branch --depth 1 -b ${BRANCH} ${REPOSITORY} ${PORTAL_HOME} 2> /dev/null

WORKDIR ${PORTAL_HOME}

RUN if [ "${COMMIT}" != "" ] ; then git fetch --unshallow ${REPOSITORY} ; git checkout ${COMMIT} 2> /dev/null ; fi

# add buildtime configuration
COPY ./portal.properties src/main/resources/portal.properties
COPY ./log4j.properties src/main/resources/log4j.properties

# install default config files, build and install, placing the scripts jar back
# in the target folder where import scripts expect it after cleanup
RUN mvn -DskipTests clean package \
	&& mv portal/target/cbioportal-*.war $CATALINA_HOME/webapps/cbioportal.war \
	&& mv scripts/target/scripts-*.jar /root/ \
	&& mvn clean \
	&& mkdir scripts/target/ \
	&& mv /root/scripts-*.jar scripts/target/

# add runtime configuration
COPY ./catalina_server.xml.patch /root/
RUN patch $CATALINA_HOME/conf/server.xml </root/catalina_server.xml.patch
COPY ./catalina_context.xml.patch /root/
RUN patch $CATALINA_HOME/conf/context.xml </root/catalina_context.xml.patch

# add importer scripts to PATH for easy running in containers
RUN find $PWD/core/src/main/scripts/ -type f -executable \! -name '*.pl'  -print0 | xargs -0 -- ln -st /usr/local/bin
# TODO: fix the workdir-dependent references to '../scripts/env.pl' and do this:
# RUN find $PWD/core/src/main/scripts/ -type f -executable \! \( -name env.pl -o -name envSimple.pl \)  -print0 | xargs -0 -- ln -st /usr/local/bin
