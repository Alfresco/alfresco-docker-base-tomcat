# Alfresco Docker Base Tomcat [![Build Status](https://img.shields.io/github/workflow/status/Alfresco/alfresco-docker-base-tomcat/Alfresco%20tomcat%20base%20Docker%20image)](https://github.com/Alfresco/alfresco-docker-base-tomcat/actions/workflows/main.yml)

This repository contains the [Dockerfile](Dockerfile) used to create the parent
Tomcat image that will be used by Alfresco engineering teams, other internal
groups in the organization, customers and partners to create Tomcat bases
application images from.

Images are available for latest Tomcat 8.5.x, 9.0.x (Java 11 only).

This image depends on the [alfresco-docker-base-java](https://github.com/Alfresco/alfresco-docker-base-java).

## Quickstart

Choose between one of the available flavours built from this repository:

Tomcat version | Java version | Java flavour | OS       | Image tag             | Size
---------------|--------------|--------------|----------|-----------------------|---------------------------------
9              | 11           | jre          | Centos 7 | tomcat9-jre11-centos7 | ![tomcat9-jre11-centos7 size][1]
9              | 11           | jdk          | Centos 7 | tomcat9-jdk11-centos7 | ![tomcat9-jdk11-centos7 size][2]
8              | 11           | jre          | Centos 7 | tomcat8-jre11-centos7 | ![tomcat8-jre11-centos7 size][3]
8              | 11           | jdk          | Centos 7 | tomcat8-jdk11-centos7 | ![tomcat8-jdk11-centos7 size][4]
9              | 11           | jre          | Ubi 8    | tomcat9-jre11-ubi8    | ![tomcat9-jre11-ubi8 size][5]
8              | 11           | jre          | Ubi 8    | tomcat8-jre11-ubi8    | ![tomcat8-jre11-ubi8 size][6]

[1]: https://img.shields.io/docker/image-size/alfresco/alfresco-base-tomcat/tomcat9-jre11-centos7
[2]: https://img.shields.io/docker/image-size/alfresco/alfresco-base-tomcat/tomcat9-jdk11-centos7
[3]: https://img.shields.io/docker/image-size/alfresco/alfresco-base-tomcat/tomcat8-jre11-centos7
[4]: https://img.shields.io/docker/image-size/alfresco/alfresco-base-tomcat/tomcat8-jdk11-centos7
[5]: https://img.shields.io/docker/image-size/alfresco/alfresco-base-tomcat/tomcat9-jre11-ubi8
[6]: https://img.shields.io/docker/image-size/alfresco/alfresco-base-tomcat/tomcat8-jre11-ubi8

* [Docker Hub](https://hub.docker.com/r/alfresco/alfresco-base-tomcat) image name: `alfresco/alfresco-base-tomcat`
* [Quay](https://quay.io/repository/alfresco/alfresco-base-tomcat) image name: `quay.io/alfresco/alfresco-base-tomcat`

Example final image: `alfresco/alfresco-base-tomcat:tomcat9-jre11-centos7`

> If you are using this base image in a public repository, please stick to the DockerHub published image.

### Image pinning

The [pinning suggestions provided in alfresco-base-java](https://github.com/Alfresco/alfresco-docker-base-java/blob/master/README.md#image-pinning) are valid for this image too.

### Minimum volume configuration

Used as parent image and with the default configuration, ensure the following
volumes are all specified.

```bash
VOLUME [ "/usr/local/tomcat/logs", "/usr/local/tomcat/work", "/usr/local/tomcat/conf/Catalina", "/usr/local/tomcat/temp" ]
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

### Disabling Security Manager

The Tomcat in this image is running with Security Manager switched on. This may impact performance. The Security Manager can be disabled by overriding the startup command to:

```bash
CMD ["catalina.sh", "run"]
```

## Development

### Naming specs

The images built from this repository are named as follow:

`tomcat<TOMCAT_VERSION>-<JAVA_DISTRIBUTION_TYPE><JAVA_MAJOR_VERSION>-<OS_DISTRIBUTION_NAME><OS_DISTRIBUTION_VERSION>`

### How to build an image locally

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

### Release

Just push a commit on the default branch including `[release]` in the message to trigger a release on Travis CI.
