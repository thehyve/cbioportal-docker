# Adjusting cBioPortal

## Customize cBioPortal configuration
When building a Docker image, the Dockerfile adjusts configuration by copying cBioPortal configuration files `portal.properties` and `log4j.properties` to the image. To build an image that uses different settings (see the documentation on the [main properties](https://github.com/cBioPortal/cbioportal/blob/master/docs/portal.properties-Reference.md) and the [skin properties](https://github.com/cBioPortal/cbioportal/blob/master/docs/Customizing-your-instance-of-cBioPortal.md)), you can follow the steps listed below. The `log4j.properties` file can modified to change the log level.

To modify the configuration for your own cBioPortal instance, please add modifications to `portal.properties` and `log4j.properties`. This file already contains several modifications for this Docker setup. The original configuration of the dockerized version of cBioPortal can be found in `portal.properties.EXAMPLE` and `log4j.properties.EXAMPLE`. To view differences between the original file and modified file, use `diff`:
```
diff portal.properties portal.properties.EXAMPLE
```

## Use a different cBioPortal branch
The default configuration to run containers creates an image based on the current version of cBioPortal. The branch used to build the image is specified in the Dockerfile. 

To use a different branch, you must know the branch name and the latest commit of this branch that you want to apply to your image, and specify them in the `Dockerfile`. For instance, if you want to build a cBioPortal image based on commit `6b9356aecdce4068543156e6b1b4509ce89cae66` of `rc`, you should find this part in Dockerfile:
```
#RUN git fetch https://github.com/thehyve/cbioportal.git my_development_branch \
#       && git checkout commit_hash_in_branch
```
and replace it with:
```
RUN git fetch https://github.com/cbioportal/cbioportal.git rc \
       && git checkout 6b9356aecdce4068543156e6b1b4509ce89cae66
```

## Build the new Docker image
Once you have done your changes, you can build the image by going to your cBioPortal Docker directory and typing:
```
docker build -t cbioportal-image .
```

You could include a version to the image name by using a `:`. For example:
```
docker build -t cbioportal-image:1.11.2 .
```