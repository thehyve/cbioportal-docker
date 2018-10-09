# Adjusting cBioPortal

## Customize server configuration
To build an image that uses a different log level than the default,
modify `log4j.properties`.

## Use a different cBioPortal branch
The default configuration to run containers creates an image based on
the latest version of cBioPortal known to work with the Docker setup.
The branch used to build the image is specified in the Dockerfile.
Download or check out the folder containing the Dockerfile.

To use a different branch, you must know the branch name and
the latest commit of this branch that you want to apply to your image,
and specify them in the `Dockerfile`.
For instance, if you want to build a cBioPortal image based on
commit `6b9356aecdce4068543156e6b1b4509ce89cae66` of `rc`,
you should find this part of the Dockerfile:
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
Once you have made your changes, you can build the image by
going to your cBioPortal Docker directory and typing:
```
docker build -t cbioportal-image .
```

You could include a version to the image name by using a `:`. For example:
```
docker build -t cbioportal-image:1.11.2 .
```