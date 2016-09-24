When building an image on which to run containers, the Dockerfile
adjusts configuration files by applying patches to them. The main
cBioPortal configuration file is
`/cbioportal/src/main/resources/portal.properties`, which is generated
by patching `/cbioportal/src/main/resources/portal.properties` with
`portal.properties.patch`. To build an image that uses different
settings (see the documentation on the [main
properties](https://github.com/cBioPortal/cbioportal/blob/master/docs/portal.properties-Reference.md)
and the [skin properties]()), start a container, and get copies of
`portal.properties` and `portal.properties.EXAMPLE` from the
container:

```bash
```

