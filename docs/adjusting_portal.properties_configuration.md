# Build image with changes in portal.properties

When building an image on which to run containers, the Dockerfile adjusts configuration by copying main cBioPortal configuration file `portal.properties` to the image. To build an image that uses different settings (see the documentation on the [main properties](https://github.com/cBioPortal/cbioportal/blob/master/docs/portal.properties-Reference.md) and the [skin properties](https://github.com/cBioPortal/cbioportal/blob/master/docs/Customizing-your-instance-of-cBioPortal.md)), you can follow the steps listed below.

### Step 1: modify `portal.properties` in the cBioPortal Docker directory
To modify the configuration for your own cBioPortal instance, please add modifications to `portal.properties`. This file already contains several modifications for this Docker setup.

The original configuration file of the current version of cBioPortal, `portal.properties.EXAMPLE`, has been added to this folder. To view differences between the original file and modified file, use `diff`:

```
diff portal.properties portal.properties.EXAMPLE
```

### Step 2: build the new Docker image

Once you have done your changes, you can build the image by going to your cBioPortal Docker directory and typing:

```
docker build -t cbioportal-image .
```

You could include a version to the image name by using a `:`. For example:

```
docker build -t cbioportal:1.10.1 .
```