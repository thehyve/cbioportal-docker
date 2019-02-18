# Maintaining this repository

Some notes on maintenance of this external Docker setup.

## Ugrading cBioPortal

Find or load a database folder based on any previously Dockerised release,
with at least one loaded study (e.g. Datahub `gbm_tcga_pan_can_atlas_2018`).
Make a copy if you want to keep it around:
```
rsync -aP cbioDB-vOLD.VERSION/ cbioDB-vNEW_VERSION
```

Edit the Dockerfile to clone the new release tag.
Never use a mutable ref such as a branch name,
as that will cause headaches reproducing what you did on another machine,
and caching build steps on the same machine.

Fetch the latest base image with `docker pull tomcat:8-jre8`
and build an image.

Save the differences between the upstream and customised config files:
```sh
diff -u portal.properties.EXAMPLE portal.properties >portal.properties.patch
```

Run a no-op container based on the image:
```sh
docker run --name=copycat <image_name> sh -c ''
```

Copy the current upstream example file out of the container:
```sh
docker cp copycat:/cbioportal/src/main/resources/portal.properties.EXAMPLE .
```

Apply the customisations to the new file:
```sh
cp portal.properties.EXAMPLE portal.properties
patch portal.properties <portal.properties.patch
```

Clean up the copycat container and the patch file.

Fetch the latest compatible MySQL image:
```sh
docker pull mysql:5.7
```

Then use the commands in `README.md`
to run a database based on the old folder (not the seed files) and migrate it.
Address any errors or warnings during this step.

Use the next command in `README.md` to start the webserver.
Visit the home page, study view, an Oncoprint queried from there
and a patient view opened from an Oncoprint mouseover,
and address anything that doesn't behave as you expect during these steps.

Load a study from Datahub and using the commands in `example_commands.md`,
restart the webserver and visit the views again,
and address anything that doesn't behave as you expect during these steps.

If you had to make any other changes to the Dockerfile to make it run,
see if they also apply to `Dockerfile.local`. You can try patching it:
```sh
git diff Dockerfile | patch Dockerfile.local
```

But since many lines work slightly differently between the two files
it will likely tell you to do it manually.
