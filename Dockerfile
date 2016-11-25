#
# Copyright (c) 2016 The Hyve B.V.
# This code is licensed under the GNU Affero General Public License (AGPL),
# version 3, or (at your option) any later version.
#

FROM tomcat:8-jre8
MAINTAINER Fedde Schaeffer <fedde@thehyve.nl>

# install build and runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
		git \
		libmysql-java \
		patch \
		python \
		python-jinja2 \
		python-mysqldb \
		python-requests \
	# install new versions of these packages backported to Debian stable;
	# Debian does not add new features or break backwards compatibility within
	# a stable release, but for these dependencies we need versions that do.
	&& apt-get install -y --no-install-recommends -t jessie-backports \
		maven \
		openjdk-8-jdk \
	&& rm -rf /var/lib/apt/lists/* \
	# set up Tomcat to use the MySQL Connector/J Java connector
	&& ln -s /usr/share/java/mysql-connector-java.jar "$CATALINA_HOME"/lib/ \
	# remove webapps that come with Tomcat for security reasons
	&& rm -rf $CATALINA_HOME/webapps/*m* 
	

# fetch the cBioPortal sources and version control metadata
ENV PORTAL_HOME=/cbioportal
RUN git clone --single-branch -b v1.3.1 'https://github.com/cBioPortal/cbioportal.git' $PORTAL_HOME
WORKDIR $PORTAL_HOME

#RUN git fetch https://github.com/thehyve/cbioportal.git uniprot_accession_in_maf_rebased \
#       && git checkout FETCH_HEAD

# add buildtime configuration
COPY ./portal.properties.patch /root/

# install default config files, build and install
RUN cp src/main/resources/portal.properties.EXAMPLE src/main/resources/portal.properties \
	&& patch src/main/resources/portal.properties </root/portal.properties.patch \
	&& cp src/main/resources/log4j.properties.EXAMPLE src/main/resources/log4j.properties \
	&& mvn -DskipTests clean install \
	&& mv portal/target/cbioportal-*.war $CATALINA_HOME/webapps/cbioportal.war

# add runtime configuration
COPY ./catalina_server.xml.patch /root/
RUN patch $CATALINA_HOME/conf/server.xml </root/catalina_server.xml.patch
COPY ./catalina_context.xml.patch /root/
RUN patch $CATALINA_HOME/conf/context.xml </root/catalina_context.xml.patch

# add importer scripts to PATH for easy running in containers
RUN find $PWD/core/src/main/scripts/ -type f -executable \! -name '*.pl'  -print0 | xargs -0 -- ln -st /usr/local/bin
# TODO: fix the workdir-dependent references to '../scripts/env.pl' and do this:
# RUN find $PWD/core/src/main/scripts/ -type f -executable \! \( -name env.pl -o -name envSimple.pl \)  -print0 | xargs -0 -- ln -st /usr/local/bin
