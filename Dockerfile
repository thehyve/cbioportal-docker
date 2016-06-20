FROM tomcat:8-jre8
MAINTAINER Fedde Schaeffer <fedde@thehyve.nl>

# install build and runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
		git \
		libmysql-java \
		maven \
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

# fetch the cBioPortal sources and version control metadata
ENV PORTAL_HOME=/cbioportal
RUN git clone --single-branch -b v1.2.4 'https://github.com/cBioPortal/cbioportal.git' $PORTAL_HOME
WORKDIR $PORTAL_HOME

# include the entrypoint script to build based on runtime context
COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]
