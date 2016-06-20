#!/bin/sh

#
# Copy custom configuration into the image and build cBioPortal.
#
# The configuration options recognised are described below.
#
# Volumes:
#
#  - /portal_config/portal.properties.patch: patch to apply to
#    portal.properties.EXAMPLE
#  - /portal_config/catalina_context.xml.patch: patch to apply to
#    catalina's context.xml
#  - /portal_resources/*: files (and subdirectories) to be copied into the
#    portal/ directory for use by the web application
#
# Environment variables:
#
#  - CBIO_GIT_BRANCH: the branch or refspec to check out, if any.
#  - CBIO_GIT_REPO: the URL or path of the git repository to switch  to,
#    if CBIO_GIT_BRANCH is set. Default: the official GitHub repository.
#
# TODO: implement the CBIO_DB_* variables
#  The following variables will override any values given in
#  portal.properties.patch, but will only affect Catalina's context.xml if
#  no patch is supplied:
#
#  - CBIO_DB_USER: mysql database username for cBioPortal
#  - CBIO_DB_PASS: mysql database password for cBioPortal
#  - CBIO_DB_HOST: mysql database host for cBioPortal
#  - CBIO_DB_NAME: mysql database url for cBioPortal
#
# TODO: implement configuration of the db host used for testing
#

# stop if any command fails
set -e

# if a git branch is given and not yet on a branch, check it out first
if [ "$CBIO_GIT_BRANCH" ] && ! (git symbolic-ref -q HEAD >/dev/null); then
	# assume default repository if not set
	if [ -z "$CBIO_GIT_REPO" ]; then
		CBIO_GIT_REPO='https://github.com/cBioPortal/cbioportal.git'
	fi
	# switch to the git branch
	echo "Checking out branch '$CBIO_GIT_BRANCH' of repo '$CBIO_GIT_REPO'"
	git fetch "$CBIO_GIT_REPO" "$CBIO_GIT_BRANCH"
	git checkout FETCH_HEAD
fi

# install default build-time config files and patch if applicable
if [ ! -e src/main/resources/log4j.properties ]; then
	cp src/main/resources/log4j.properties.EXAMPLE src/main/resources/log4j.properties
fi
if [ ! -e src/main/resources/portal.properties ]; then
	cp src/main/resources/portal.properties.EXAMPLE src/main/resources/portal.properties
	if [ -f '/portal_config/portal.properties.patch' ]; then
		patch src/main/resources/portal.properties </root/portal.properties.patch
	fi
fi

# build
mvn -DskipTests clean install

# TODO copy any custom webapp resources into the built directory without touching src dir
if ls /portal_resources/* >/dev/null 2>&1; then
	cp -r /portal_resources/* portal/target/portal/
fi

# install
if [ -d $CATALINA_HOME/webapps/cbioportal ]; then
	rm -r $CATALINA_HOME/webapps
fi
mv portal/target/portal $CATALINA_HOME/webapps/cbioportal

# apply any runtime configuration from the volume and environment
if [ -f '/portal_config/catalina_context.xml.patch' ]; then
	patch $CATALINA_HOME/conf/context.xml </portal_config/catalina_context.xml.patch
fi

# (re-)install importer scripts to PATH for easy running
find /usr/local/bin -type l -lname "$PWD/core/src/main/scripts/*" -delete
find $PWD/core/src/main/scripts/ -type f -executable \! -name '*.pl' -print0 | xargs -0 -- ln -st /usr/local/bin
# TODO: fix the workdir-dependent references to '../scripts/env.pl' and do this:
# RUN find $PWD/core/src/main/scripts/ -type f -executable \! \( -name env.pl -o -name envSimple.pl \) -print0 | xargs -0 -- ln -st /usr/local/bin

exec "$@"
