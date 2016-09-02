# cbioportal-docker
Files to create cBioPortal docker images.

#### Step 1 - build image
Start by building the image. Checkout this repository, enter the directory and run:

`docker build -t cbioportal .`

Alternatively, if you do not wish to change anything in the Docker file or the properties, you can run: 

`docker build -t cbioportal https://github.com/thehyve/cbioportal-docker.git`

#### Step 2 - run container

In https://github.com/thehyve/cbioportal-docker/blob/master/docker_commands.sh you can find a number of commands to start a container based on the image built in step 1 and the extra mysql container for the cBioPortal DB.
