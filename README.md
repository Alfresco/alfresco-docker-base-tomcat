# Welcome to Alfresco Docker Base Tomcat

This repository contains the Dockerfile to create the base image that will be used by Alfresco engineering teams, other internal groups in the organisation, customers and partners to create images as part of the Alfresco Digital Business Platform.

#How to Build

This image depends on the [alfresco-docker-base-java](https://github.com/Alfresco/alfresco-docker-base-java) image. The base Java image is not currently publicly available but the Dockerfile to build it is. To build the base tomcat image you will first need to build a local base java image and adjust the FROM directive in the base tomcat Dockerfile to use your local build of the base java image.

To build this image run the following script
```bash
docker build -t alfresco/alfresco-docker-base-tomcat .
```