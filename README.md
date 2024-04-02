# Alfresco Docker Base Tomcat [![Build Status](https://img.shields.io/github/actions/workflow/status/Alfresco/alfresco-docker-base-tomcat/main.yml?branch=master)](https://github.com/Alfresco/alfresco-docker-base-tomcat/actions/workflows/main.yml) ![Docker Hub Pulls](https://img.shields.io/docker/pulls/alfresco/alfresco-base-tomcat)

This repository provides the base Docker images for Tomcat 10.1.x and 9.0.x that
are meant to be used within the Alfresco engineering to build Docker images for
Java/Tomcat applications.

This image relies on the [alfresco-docker-base-java](https://github.com/Alfresco/alfresco-docker-base-java) image.

## Flavours

Choose between one of the available flavours built from this repository:

Tomcat version | Java version | OS            | Image ref                                                  | Size
---------------|--------------|---------------|------------------------------------------------------------|--------------------------------------
9              | 11           | Rocky Linux 8 | `alfresco/alfresco-base-tomcat:tomcat9-jre11-rockylinux8`  | ![tomcat9-jre11-rockylinux8 size][1]
9              | 17           | Rocky Linux 8 | `alfresco/alfresco-base-tomcat:tomcat9-jre17-rockylinux8`  | ![tomcat9-jre17-rockylinux8 size][2]
10             | 11           | Rocky Linux 8 | `alfresco/alfresco-base-tomcat:tomcat9-jre11-rockylinux8`  | ![tomcat10-jre11-rockylinux8 size][3]
10             | 17           | Rocky Linux 8 | `alfresco/alfresco-base-tomcat:tomcat10-jre17-rockylinux8` | ![tomcat10-jre17-rockylinux8 size][4]
10             | 17           | Rocky Linux 9 | `alfresco/alfresco-base-tomcat:tomcat10-jre17-rockylinux9` | ![tomcat10-jre17-rockylinux9 size][5]

[1]: https://img.shields.io/docker/image-size/alfresco/alfresco-base-tomcat/tomcat9-jre11-rockylinux8
[2]: https://img.shields.io/docker/image-size/alfresco/alfresco-base-tomcat/tomcat9-jre17-rockylinux8
[3]: https://img.shields.io/docker/image-size/alfresco/alfresco-base-tomcat/tomcat10-jre11-rockylinux8
[4]: https://img.shields.io/docker/image-size/alfresco/alfresco-base-tomcat/tomcat10-jre17-rockylinux8
[5]: https://img.shields.io/docker/image-size/alfresco/alfresco-base-tomcat/tomcat10-jre17-rockylinux9

The images are available on:

* [Docker Hub](https://hub.docker.com/r/alfresco/alfresco-base-tomcat), image name: `alfresco/alfresco-base-tomcat`
* [Quay](https://quay.io/repository/alfresco/alfresco-base-tomcat) (enterprise credentials required), image name: `quay.io/alfresco/alfresco-base-tomcat`

### Image pinning

The pinning approach provided in
[alfresco-base-java](https://github.com/Alfresco/alfresco-docker-base-java/blob/master/README.md#image-pinning)
is highly suggested for this image too.

## Development

### Naming specs

The images built from this repository are named as follow:

`tomcat<TOMCAT_VERSION>-<JAVA_DISTRIBUTION_TYPE><JAVA_MAJOR_VERSION>-<OS_DISTRIBUTION_NAME><OS_DISTRIBUTION_VERSION>`

### How to build an image locally

To build this image, run the following script:

```bash
IMAGE_REPOSITORY=alfresco/alfresco-base-tomcat
docker buildx build -t $IMAGE_REPOSITORY . \
  --build-arg DISTRIB_NAME=$DISTRIB_NAME \
  --build-arg DISTRIB_MAJOR=$DISTRIB_MAJOR \
  --build-arg JAVA_MAJOR=$JAVA_MAJOR \
  --build-arg TOMCAT_MAJOR=$TOMCAT_MAJOR \
  --no-cache
```

where:

* DISTRIB_NAME is rockylinux
* DISTRIB_MAJOR is 8 or 9 for rockylinux
* JAVA_MAJOR is 11 or 17 for rockylinux only
* TOMCAT_MAJOR is 8 or 9

### Release

New images are built automatically on each new commit on master and on a weekly schedule.

## Downstream projects

* [alfresco-community-repo](https://github.com/Alfresco/alfresco-community-repo/blob/master/packaging/docker-alfresco/Dockerfile)
* [alfresco-community-share](https://github.com/Alfresco/alfresco-community-share/blob/master/packaging/docker/Dockerfile)
