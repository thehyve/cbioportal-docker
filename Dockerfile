#
# Copyright (c) 2016 The Hyve B.V.
# This code is licensed under the GNU Affero General Public License (AGPL),
# version 3, or (at your option) any later version.
#

FROM tomcat:8-jre8
MAINTAINER Fedde Schaeffer <fedde@thehyve.nl>

# install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
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
		openjdk-8-jdk \
	&& rm -rf /var/lib/apt/lists/* \
	# set up Tomcat to use the MySQL Connector/J Java connector
	&& ln -s /usr/share/java/mysql-connector-java.jar "$CATALINA_HOME"/lib/ \
	# remove webapps that come with Tomcat for security reasons
	&& rm -rf $CATALINA_HOME/webapps/*m* 
	

# fetch the cBioPortal sources, without keeping git and its deps in the image
ENV PORTAL_HOME=/cbioportal
RUN apt-get update && apt-get install -y --no-install-recommends git \
	&& rm -rf /var/lib/apt/lists/* \
	&& git clone --depth=1 -b v1.4.2 'https://github.com/cBioPortal/cbioportal.git' $PORTAL_HOME \
	#&& cd $PORTAL_HOME \
	#&& git fetch https://github.com/thehyve/cbioportal.git my_development_branch \
	#&& git checkout commit_hash_in_branch \
	&& apt-get purge -y git && apt-get autoremove -y --purge
WORKDIR $PORTAL_HOME

# add buildtime configuration
COPY ./portal.properties.patch /root/

# install default config files, build and install
RUN apt-get update && apt-get install -y --no-install-recommends maven \
	&& rm -rf /var/lib/apt/lists/* \
	&& cp src/main/resources/portal.properties.EXAMPLE src/main/resources/portal.properties \
	&& patch src/main/resources/portal.properties </root/portal.properties.patch \
	&& cp src/main/resources/log4j.properties.EXAMPLE src/main/resources/log4j.properties \
	&& mvn -DskipTests clean install \
	# deploy the war to the Tomcat web container
	&& unzip portal/target/cbioportal-*.war -d $CATALINA_HOME/webapps/cbioportal/ \
	# save the scripts jar needed for importing, so Maven does not clean it up
	&& mv scripts/target/scripts-*.jar /root/ \
	&& mvn clean \
	&& mkdir scripts/target/ \
	&& mv /root/scripts-*.jar scripts/target/ \
	&& apt-get purge -y maven && apt-get autoremove -y --purge

# add runtime configuration
COPY ./catalina_server.xml.patch /root/
RUN patch $CATALINA_HOME/conf/server.xml </root/catalina_server.xml.patch
COPY ./catalina_context.xml.patch /root/
RUN patch $CATALINA_HOME/conf/context.xml </root/catalina_context.xml.patch

# add importer scripts to PATH for easy running in containers
RUN find $PWD/core/src/main/scripts/ -type f -executable \! -name '*.pl'  -print0 | xargs -0 -- ln -st /usr/local/bin
# TODO: fix the workdir-dependent references to '../scripts/env.pl' and do this:
# RUN find $PWD/core/src/main/scripts/ -type f -executable \! \( -name env.pl -o -name envSimple.pl \)  -print0 | xargs -0 -- ln -st /usr/local/bin
