# Build an image based on a different branch
The default configuration to run containers creates an image based on the current version of cBioPortal. The branch used to build the image is specified in the Dockerfile. The default branch can be easily changed by following two steps.

## Step 1: modify the `Dockerfile` in the cBioPortal Docker directory
Briefly, you must know the branch name and the latest commit of this branch that you want to apply to your image, and specify them in the `Dockerfile`. For instance, if you want to build a cBioPortal image based on commit `6b9356aecdce4068543156e6b1b4509ce89cae66` of `rc`, you should find this part in Dockerfile:

```
#RUN git fetch https://github.com/thehyve/cbioportal.git my_development_branch \
#       && git checkout commit_hash_in_branch
```

and replace it with:

```
RUN git fetch https://github.com/cbioportal/cbioportal.git rc \
       && git checkout 6b9356aecdce4068543156e6b1b4509ce89cae66
```

## Step 2: build the new Docker image
Once you have done your changes, you can build the image by going to your cBioPortal Docker directory and typing:

```
docker build -t cbioportal-image .
```

