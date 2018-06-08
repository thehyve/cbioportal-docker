# Build images from development code #

Using `Dockerfile.local`, you can build images based on a local checkout of a
development branch. The Dockerfile will cache the dependencies across rebuilds,
so that changing the code and rebuilding the cBioPortal stack doesn't waste
time fetching everything unless the dependencies or project structure change.

To use this functionality, copy the following files into your source folder and
build an image based on that folder and Dockerfile.local:

```shell
cp Dockerfile.local *.properties *.patch ~/git/cbioportal
cp dockerignore ~/git/cbioportal/.dockerignore
cd ~/git/cbioportal
docker build -f Dockerfile.local -t cbioportal:my-local-source-dir .
```

And then, whenever you've changed the source code (or configuration), you can
build a new image by re-running the build command. This will not automatically
remove the old image; use `docker image ls` and `docker image rm` if you no
longer need it.

## Override deployed files ##

Images built based on `Dockerfile.local` allow you to override deployed web app
files in place, by mounting volumes inside
`/usr/local/tomcat/webapps/cbioportal/`. For instance, run a container such as
the following to test a production build of the frontend project:

```shell
cd ~/git/cbioportal-frontend
npm install && npm run build
docker run --rm \
    --name=cbioportal-container \
    --net=cbio-net \
    -v "$PWD/dist/reactapp:/usr/local/tomcat/webapps/cbioportal/reactapp:ro" \
    -e CATALINA_OPT0S='-Xms2g -Xmx4g' \
    -p 8081:8080 \
    cbioportal:my-local-source-dir
```
