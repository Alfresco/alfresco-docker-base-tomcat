# Welcome to Alfresco Docker Base Tomcat

[![Build Status](https://travis-ci.com/Alfresco/alfresco-docker-base-tomcat.svg?branch=master)](https://travis-ci.com/Alfresco/alfresco-docker-base-tomcat)

## Introduction

This repository contains the [Dockerfile](Dockerfile) used to create the parent Tomcat image that will be used by Alfresco engineering teams,
other internal groups in the organisation, customers and partners to create Tomcat bases application images from.

## Versioning

Images are available for latest Tomcat 8.5.65, 9.0.45 and 10.0.8 (last two are Java 11 only).

## How to Build

This image depends on the [alfresco-docker-base-java](https://github.com/Alfresco/alfresco-docker-base-java) image,
which is available:

* (privately) on [Quay](https://quay.io/repository/alfresco/alfresco-base-java)
* (publicly) on [Docker Hub](https://hub.docker.com/r/alfresco/alfresco-base-java)

To build this image, run the following script:

```bash
IMAGE_REPOSITORY=alfresco/alfresco-base-tomcat
(cd java-$JAVA_MAJOR/$DISTRIB_NAME-$DISTRIB_MAJOR && docker build -t java-$JAVA_MAJOR-$DISTRIB_NAME-$DISTRIB_MAJOR .)
docker build -t $IMAGE_REPOSITORY . \
  --build-arg DISTRIB_NAME=$DISTRIB_NAME \
  --build-arg DISTRIB_MAJOR=$DISTRIB_MAJOR \
  --build-arg JAVA_MAJOR=$JAVA_MAJOR \
  --build-arg TOMCAT_MAJOR=$TOMCAT_MAJOR \
  --no-cache
```
where:
* DISTRIB_NAME is centos
* DISTRIB_MAJOR is 7
* JAVA_MAJOR is 8 or 11
* TOMCAT_MAJOR is 8, 9 or 10

## Release

Just push a commit on the default branch including `[release]` in the message to trigger a release on Travis CI.

## Pulling released images

Builds are available from [Docker Hub](https://hub.docker.com/r/alfresco/alfresco-base-tomcat)

```bash
docker pull alfresco/alfresco-base-tomcat:$TOMCAT_MAJOR_MINOR_VERSION 
docker pull alfresco/alfresco-base-tomcat:$TOMCAT_VERSION-java-$JAVA_MAJOR-$DISTRIB_NAME-$DISTRIB_MAJOR
docker pull alfresco/alfresco-base-tomcat:$TOMCAT_VERSION-java-$JAVA_MAJOR-$DISTRIB_NAME-$DISTRIB_MAJOR-$SHORT_SHA256
```

where:
* DISTRIB_NAME is centos
* DISTRIB_MAJOR is 7
* JAVA_MAJOR is 8 or 11
* TOMCAT_MAJOR_MINOR_VERSION is 8.5 or 9.0
* TOMCAT_VERSION is 8.5.65, 9.0.45 or 10.0.8
* SHORT_SHA256 is the 12 digit SHA256 of the image as available from the registry

*NOTE*
The default image with $TOMCAT_MAJOR_MINOR_VERSION as tag uses CentOS 7 and Java 11.
Tomcat 9 images are available with CentOS 8 and Java 11 only.

The builds are identical to those stored in the private repo on Quay, which also supports build-pinning versions.

```bash
docker pull quay.io/alfresco/alfresco-base-tomcat:$TOMCAT_MAJOR_MINOR_VERSION
docker pull quay.io/alfresco/alfresco-base-tomcat:$TOMCAT_VERSION-java-$JAVA_MAJOR-$DISTRIB_NAME-$DISTRIB_MAJOR
docker pull quay.io/alfresco/alfresco-base-tomcat:$TOMCAT_VERSION-java-$JAVA_MAJOR-$DISTRIB_NAME-$DISTRIB_MAJOR-$SHORT_SHA256
```

## Usage

### Standalone

The image can be used via `docker run` to run java applications with `--read-only` set,
without any loss of functionality providing the various directories tomcat writes to are volumes.

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

Example from a Dockerfile using a public parent image in Docker Hub.

```bash
FROM alfresco/alfresco-base-tomcat:10.0
```

Example from a Dockerfile using a private parent image in Quay:

```bash
FROM quay.io/alfresco/alfresco-base-tomcat:10.0.8-java-11-centos-7-94fdb78396b6
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

## CI/CD

Running on Travis, requires the following environment variable to be set:

| Name | Description |
|------|-------------|
| DOCKER_USERNAME | Docker Hub username |
| DOCKER_PASSWORD | Docker Hub password/token |
| QUAY_USERNAME | Quay username |
| QUAY_PASSWORD | Quay password/token |
