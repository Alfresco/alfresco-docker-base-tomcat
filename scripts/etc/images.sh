#!/bin/bash

########################################################################
# Docker Image
########################################################################

# shellcheck disable=SC2034,SC2148

export docker_image_tag_suffix='centos-7'
export docker_image_repository='alfresco-base-tomcat'

# Actual version of tomcat we're going to build
export tomcat_version=8.5.34
# Short tag we'll apply to
export short_name=8.5

# The image built will be ${docker_image_repository}:${tomcat_version}-java-${java_major_version}-${java_vendor}-${docker_image_tag_suffix}

# For general builds:
export base_image='alfresco/alfresco-base-java'
# If basing off unreleased quay builds:
# export base_image='quay.io/alfresco/alfresco-base-java'

# short_tag is 'true' if you get to be alfresco-base-tomcat:${DOCKER_IMAGE_TAG_SHORT_NAME}

export -A java_8=(
  [base_tag]=8u181-oracle-centos-7-33e0cd92ffd0
  [short_tag]='true'
)

export -A java_11=(
  [base_tag]=11-openjdk-centos-7-95536c8b599f
  [short_tag]='true'
)

