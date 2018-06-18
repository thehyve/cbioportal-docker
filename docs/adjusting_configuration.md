# Adjusting cBioPortal

## Customize cBioPortal configuration

The cBioPortal server software can be configured in various ways
to suit the needs of your particular installation
by overriding the file `portal.properties`.
For details, see the documentation on the
[main properties](https://github.com/cBioPortal/cbioportal/blob/master/docs/portal.properties-Reference.md)
and the
[skin properties](https://github.com/cBioPortal/cbioportal/blob/master/docs/Customizing-your-instance-of-cBioPortal.md).

To override any propertiese,
mount a customised file into the `/cbioportal` folder
by including a `-v` option in all `docker_run` commands
_before_ the name of the cbioportal image:
```
docker run -d --restart=always \
    --name=cbioportal-container \
    --net=cbio-net \
    -e CATALINA_OPTS='-Xms2g -Xmx4g' \
    -p 8081:8080 \
    -v "$PWD/portal.properties:/cbioportal/:ro" \
    cbioportal-image
```

Note that the database credentials used by the web server must also
be specified in the Tomcat configuration below.

The properties files included in this repository contain several tweaks likely
to be relevant to the documented Docker setup.
The original configuration can be found in `portal.properties.EXAMPLE`.
To view differences between the original file and modified file, use `diff`:

```
diff portal.properties portal.properties.EXAMPLE
```


## Customize web server configuration

To override any Tomcat server configuration,
including the database credentials used by the cBioPortal web server,
tweak `catalina_context.xml` and/or `catalina_server.xml`
and mount them in the `/cbioportal/` as demonstrated below
when running the web server:

```
    -v "$PWD/catalina_context.xml:/cbioportal/:ro" \
    -v "$PWD/catalina_server.xml:/cbioportal/:ro" \
```

The `log4j.properties` file configures the log level.
Override it by mounting the file into
`/usr/local/tomcat/webapps/cbioportal/WEB-INF/classes`
when running the web server:

```
    -v "$PWD/log4j.properties:/user/local/tomcat/webapps/cbioportal/WEB-INF/classes/:ro" \
```


## Use a different cBioPortal branch

The default configuration to run containers creates an image based on
the latest version of cBioPortal known to work out of the box.
The release used to build the image is specified in the Dockerfile.

To use a different snapshot, you should find the tag/branch name and the commit
that you want to base your image on, and specify them in the `Dockerfile`.
Use `git` to check out the repository, and edit the Dockerfile:

```
git clone https://github.com/thehyve/cbioportal-docker.git
cd cbioportal-docker
nano Dockerfile
```
For instance, if you want to build a cBioPortal image based on commit
`6b9356aecdce4068543156e6b1b4509ce89cae66` of the `rc` branch,
you should find the line in the Dockerfile that looks like this:

```
RUN git clone --depth 1 -b v1.xx.x 'https://github.com/cBioPortal/cbioportal.git' $PORTAL_HOME
```
and replace it with:
```
RUN git clone --single-branch -b rc 'https://github.com/cBioPortal/cbioportal.git' $PORTAL_HOME \
    && git checkout 6b9356aecdce4068543156e6b1b4509ce89cae66
```

## Build the new Docker image
Once you have done your changes, you can build the image by going to your cBioPortal Docker directory and typing:
```
docker build -t cbioportal-image .
```

You could include a version to the image name by using a `:`. For example:
```
docker build -t cbioportal-image:my-rc-snapshot.
```
