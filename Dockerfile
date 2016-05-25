FROM tomcat:8-jre8
MAINTAINER Fedde Schaeffer <fedde@thehyve.nl>

# install build and runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
		git \
		libmysql-java \
		maven \
		openjdk-8-jdk="$JAVA_DEBIAN_VERSION" \
		python \
		python-jinja2 \
		python-mysqldb \
		python-requests \
	&& rm -rf /var/lib/apt/lists/*
# set up Tomcat to use the MySQL Connector/J Java connector
RUN ln -s /usr/share/java/mysql-connector-java.jar "$CATALINA_HOME"/lib/

# fetch the cBioPortal sources and version control metadata
ENV PORTAL_HOME=/cbioportal
RUN git clone -b v1.1.1 'https://github.com/cBioPortal/cbioportal.git' $PORTAL_HOME
WORKDIR $PORTAL_HOME

# install default config files, build and install
RUN mv src/main/resources/portal.properties.EXAMPLE src/main/resources/portal.properties \
	&& mv src/main/resources/log4j.properties.EXAMPLE src/main/resources/log4j.properties \
	&& mvn -DskipTests clean install \
	&& mv portal/target/cbioportal.war $CATALINA_HOME/webapps/

# add importer scripts to PATH for easy running in containers
# TODO: fix the references to '../scripts/env.pl' and do this:
# RUN find $PWD/core/src/main/scripts/ -type f -executable \! \( -name env.pl -o -name envSimple.pl \)  -print0 | xargs -0 -- ln -st /usr/local/bin
ENV PATH=$PORTAL_HOME/core/src/main/scripts/importer:$PATH
