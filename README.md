# Welcome to Alfresco Docker Base Tomcat

[![Build Status](https://travis-ci.com/Alfresco/alfresco-docker-base-tomcat.svg?branch=master)](https://travis-ci.com/Alfresco/alfresco-docker-base-tomcat)

## Introduction

This repository contains the Dockerfile used to create the parent Tomcat image that
will be used by Alfresco engineering teams, other internal groups in the
organisation, customers and partners to create images as part of the Alfresco
Digital Business Platform.

## Versioning

Currently any pull request to this project should ensure that `DOCKER_IMAGE_TAG`,
`DOCKER_IMAGE_TAG_SHORT_NAME` are set with the relevant values in `build.properties`.

Build-pinning is available on quay to ensure an exact build artifact is used.

## How to Build

This image depends on the [alfresco-docker-base-java](https://github.com/Alfresco/alfresco-docker-base-java) image,
which is available:

* (privately) on [Quay](https://quay.io/repository/alfresco/alfresco-base-java)
* (publicly) on [Docker Hub](https://hub.docker.com/r/alfresco/alfresco-base-java/).

To build this image, run the following script:

```bash
docker build -t alfresco/alfresco-base-tomcat .
```

## Pulling released images

Builds are available from [Docker Hub](https://hub.docker.com/r/alfresco/alfresco-base-tomcat)

```bash
docker pull alfresco/alfresco-base-tomcat:$TOMCAT_MAJOR_MINOR_VERSION 
docker pull alfresco/alfresco-base-tomcat:$TOMCAT_VERSION-java-$JAVA_MAJOR_VERSION-$JAVA_VENDOR-centos-$CENTOS_MAJOR_VERSION
docker pull alfresco/alfresco-base-tomcat:$TOMCAT_VERSION-java-$JAVA_MAJOR_VERSION-$JAVA_VENDOR-centos-$CENTOS_MAJOR_VERSION-$SHORT_SHA256
```

where:
* TOMCAT_MAJOR_MINOR_VERSION is 8.5
* TOMCAT_VERSION is 8.5.51
* JAVA_MAJOR_VERSION is 8 or 11
* JAVA_VENDOR is `oracle` for 8 and `openjdk` for 11
* CENTOS_MAJOR_VERSION is 7 or 8
* SHORT_SHA256 is the 12 digit SHA256 of the image as available from the registry

*NOTE* The default image with $TOMCAT_MAJOR_MINOR_VERSION as tag uses CentOS 8 and Java 11.

The builds are identical to those stored in the private repo on Quay, which also supports build-pinning versions.

```bash
docker pull quay.io/alfresco/alfresco-base-tomcat:$TOMCAT_MAJOR_MINOR_VERSION
docker pull quay.io/alfresco/alfresco-base-tomcat:$TOMCAT_VERSION-java-$JAVA_MAJOR_VERSION-$JAVA_VENDOR-centos-$CENTOS_MAJOR_VERSION
docker pull quay.io/alfresco/alfresco-base-tomcat:$TOMCAT_VERSION-java-$JAVA_MAJOR_VERSION-$JAVA_VENDOR-centos-$CENTOS_MAJOR_VERSION-$SHORT_SHA256
```

## Usage

### Standalone

The image can be used via `docker run` to run java applications
with `--read-only` set, without any loss of functionality providing the various
directories tomcat writes to are volumes.

With the supplied tomcat configuration, the following should all be mounted on volumes:

* `/usr/local/tomcat/logs`
* `/usr/local/tomcat/work`
* `/usr/local/tomcat/conf/Catalina`
* `/usr/local/tomcat/temp`

### Parent Image

Web Applications, Tomcat configuration, etc. can all be supplied by various  methods.
We recommend using this as a [parent image](https://docs.docker.com/glossary/?term=parent%20image),
and then following the  recommended practices for passing configuration and secrets for your orchestrator and use case.

For reference, see the documentation on
[layers](https://docs.docker.com/storage/storagedriver/#container-and-layers),
the
[VOLUME](https://docs.docker.com/engine/reference/builder/#volume)
instruction,
[best practices with VOLUMEs](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#volume),
[best practices with persistence](https://docs.docker.com/develop/dev-best-practices/#where-and-how-to-persist-application-data),
and
[tmpfs](https://docs.docker.com/storage/tmpfs/) mounts.

### Examples of usage as a parent image

Example from a Dockerfile using a public, parent image in Docker Hub.

```bash
FROM alfresco/alfresco-base-tomcat:9.0
```

Example from a Dockerfile using a private, parent image in Quay:

```bash
FROM quay.io/alfresco/alfresco-base-tomcat:9.0.41-java-11-oracle-centos-7-f7b1278cc0eb
```

### Minimum volume configuration

Used as parent image and with the default configuration, ensure the following
volumes are all specified.

<!-- markdownlint-disable MD013 -->

```bash
VOLUME [ "/usr/local/tomcat/logs", "/usr/local/tomcat/work", "/usr/local/tomcat/conf/Catalina", "/usr/local/tomcat/temp" ]
```
### Notes

The Tomcat in this image is running with Security Manager switched on. This may impact performance. The Security Manager can be disabled by overriding the startup command to:
```bash
CMD ["catalina.sh", "run"]
```

<!-- markdownlint-enable MD013 -->

## CI/CD

Running on Travis, requires the following environment variable to be set:

| Name | Description |
|------|-------------|
| DOCKER_USERNAME | Docker Hub username |
| DOCKER_PASSWORD | Docker Hub password/token |
| QUAY_USERNAME | Quay username |
| QUAY_PASSWORD | Quay password/token |
