# Adjusting cBioPortal

## Customize cBioPortal configuration
When building a Docker image, the Dockerfile adjusts configuration by copying cBioPortal configuration files `portal.properties` and `log4j.properties` to the image. To build an image that uses different settings (see the documentation on the [main properties](https://github.com/cBioPortal/cbioportal/blob/master/docs/portal.properties-Reference.md) and the [skin properties](https://github.com/cBioPortal/cbioportal/blob/master/docs/Customizing-your-instance-of-cBioPortal.md)), you can follow the steps listed below. The `log4j.properties` file can modified to change the log level.

To modify the configuration for your own cBioPortal instance, please add modifications to `portal.properties` and `log4j.properties`. This file already contains several modifications for this Docker setup. The original configuration of the dockerized version of cBioPortal can be found in `portal.properties.EXAMPLE` and `log4j.properties.EXAMPLE`. To view differences between the original file and modified file, use `diff`:
```
diff portal.properties portal.properties.EXAMPLE
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
