# hadolint global ignore=DL3033,DL3008
# Alfresco Base Tomcat Image
# see also https://github.com/docker-library/tomcat
ARG JAVA_MAJOR
ARG DISTRIB_NAME=rockylinux
ARG DISTRIB_MAJOR
ARG IMAGE_JAVA_REPO=quay.io/alfresco
ARG IMAGE_JAVA_NAME=alfresco-base-java
ARG IMAGE_JAVA_TAG=jre${JAVA_MAJOR}-${DISTRIB_NAME}${DISTRIB_MAJOR}

# Tomcat is downloaded and configured on debian as its a binary dist anyway
FROM debian:12-slim AS tomcat_dist

ARG TOMCAT_MAJOR
ARG TOMCAT_VERSION
ARG TOMCAT_SHA512
ARG TCNATIVE_VERSION
ARG TCNATIVE_SHA512
ARG APR_VERSION
ARG APR_SHA256

ENV APACHE_MIRRORS="https://archive.apache.org/dist https://dlcdn.apache.org https://downloads.apache.org" \
    DEBIAN_FRONTEND=noninteractive

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

RUN apt-get -y update && apt-get -y install xmlstarlet curl gpg; \
  mkdir -p /build/{apr,tcnative,tomcat}; \
  \
  active_mirror=; \
  for mirror in $APACHE_MIRRORS; do \
    if curl -fsSL ${mirror}/tomcat/tomcat-${TOMCAT_MAJOR}/KEYS | gpg --import; then \
      curl -fsSL ${mirror}/apr/KEYS | gpg --import; \
      active_mirror=$mirror; \
      break; \
    fi; \
  done; \
  [ -n active_mirror ]; \
  \
  echo "Using mirror ${active_mirror}"; \
  for filetype in '.tar.gz' '.tar.gz.asc'; do \
    curl -fsSLo tomcat${filetype} ${active_mirror}/tomcat/tomcat-${TOMCAT_MAJOR}/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}${filetype}; \
    curl -fsSLo tcnative${filetype}  ${active_mirror}/tomcat/tomcat-connectors/native/${TCNATIVE_VERSION}/source/tomcat-native-${TCNATIVE_VERSION}-src${filetype}; \
    curl -fsSLo apr${filetype}  ${active_mirror}/apr/apr-${APR_VERSION}${filetype}; \
  done; \
  \
  echo "$TOMCAT_SHA512 *tomcat.tar.gz" | sha512sum -c - || (echo "Checksum did't match: $(sha512sum *tomcat.tar.gz)" && exit 1); \
  echo "$TCNATIVE_SHA512 *tcnative.tar.gz" | sha512sum -c - || (echo "Checksum did't match: $(sha512sum *tcnative.tar.gz)" && exit 1); \
  echo "$APR_SHA256 *apr.tar.gz" | sha256sum -c - || (echo "Checksum did't match: $(sha256sum *apr.tar.gz)" && exit 1); \
  \
  gpg --batch --verify tcnative.tar.gz.asc tcnative.tar.gz && \
  gpg --batch --verify tomcat.tar.gz.asc tomcat.tar.gz && \
  gpg --batch --verify apr.tar.gz.asc apr.tar.gz && \
  tar -zxf tomcat.tar.gz -C /build/tomcat --strip-components=1 && \
  tar -zxf tcnative.tar.gz -C /build/tcnative --strip-components=1 && \
  tar -zxf apr.tar.gz -C /build/apr --strip-components=1

WORKDIR /build/tomcat
# sh removes env vars it doesn't support (ones with periods)
# https://github.com/docker-library/tomcat/issues/77
RUN find ./bin/ -name '*.sh' -exec sed -ri 's|^#!/bin/sh$|#!/usr/bin/env bash|' '{}' +; \
  mkdir -p lib/org/apache/catalina/util

WORKDIR /build/tomcat/lib/org/apache/catalina/util
RUN printf "server.info=Alfresco servlet container/$TOMCAT_MAJOR\nserver.number=$TOMCAT_MAJOR" > ServerInfo.properties

WORKDIR /build/tomcat
RUN xmlstarlet ed -L \
  # Remove comments
  -d '//comment()' \
  # Disable shutdown port
  -d '/Server/@shutdown' -u '/Server/@port' -v -1 \
  # Remove server banner
  -u '/Server/Service[@name="Catalina"]/Connector[@port=8080]/@Server' -v "" \
  # Disable auto deployment of webapps
  -a '/Server/Service[@name="Catalina"]/Engine[@name="Catalina"]/Host[@name="localhost"]' -t attr -n deployXML -v false \
  -u '/Server/Service[@name="Catalina"]/Engine[@name="Catalina"]/Host[@name="localhost"]/@autoDeploy' -v false \
  -u '/Server/Service[@name="Catalina"]/Engine[@name="Catalina"]/Host[@name="localhost"]/@unpackWARs' -v false \
  # Enable RemoteIP valve for better handling when behind reverse proxy
  -s '/Server/Service[@name="Catalina"]/Engine[@name="Catalina"]/Host[@name="localhost"]' -t elem -n 'Valve' \
  -a '/Server/Service[@name="Catalina"]/Engine[@name="Catalina"]/Host[@name="localhost"]/Valve[last()]' -t attr -n className -v org.apache.catalina.valves.RemoteIpValve \
  -a '/Server/Service[@name="Catalina"]/Engine[@name="Catalina"]/Host[@name="localhost"]/Valve[last()]' -t attr -n portHeader -v X-Forwarded-Port \
  # Do not leak server info within error pages
  -s '/Server/Service[@name="Catalina"]/Engine[@name="Catalina"]/Host[@name="localhost"]' -t elem -n 'Valve' \
  -a '/Server/Service[@name="Catalina"]/Engine[@name="Catalina"]/Host[@name="localhost"]/Valve[last()]' -t attr -n className -v org.apache.catalina.valves.ErrorReportValve \
  -a '/Server/Service[@name="Catalina"]/Engine[@name="Catalina"]/Host[@name="localhost"]/Valve[last()]' -t attr -n showServerInfo -v false \
  -a '/Server/Service[@name="Catalina"]/Engine[@name="Catalina"]/Host[@name="localhost"]/Valve[last()]' -t attr -n showReport -v false \
  # Do not leak runtime arguments and variables in logs
  -a '/Server/Listener[@className="org.apache.catalina.startup.VersionLoggerListener"]' -t attr -n logArgs -v false \
  -a '/Server/Listener[@className="org.apache.catalina.startup.VersionLoggerListener"]' -t attr -n logEnv -v false \
  -a '/Server/Listener[@className="org.apache.catalina.startup.VersionLoggerListener"]' -t attr -n logProps -v false \
  conf/server.xml
# Remove unwanted files from distribution
RUN rm -fr webapps/* *.txt *.md RELEASE-NOTES logs/ temp/ work/ bin/*.bat

# hadolint ignore=DL3041
FROM ${IMAGE_JAVA_REPO}/${IMAGE_JAVA_NAME}:${IMAGE_JAVA_TAG} AS tcnative_build-rockylinux

ARG DISTRIB_MAJOR
ARG JAVA_MAJOR
ARG BUILD_DIR=/build
ARG INSTALL_DIR=/usr/local

ENV JAVA_HOME=/usr/lib/jvm/java-openjdk

COPY --from=tomcat_dist /build/tcnative $BUILD_DIR/tcnative
COPY --from=tomcat_dist /build/apr $BUILD_DIR/apr

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

RUN <<EOT
  yum install -y gcc make expat-devel java-${JAVA_MAJOR}-openjdk-devel redhat-rpm-config
  yum clean all
EOT

WORKDIR ${BUILD_DIR}/apr
RUN <<EOT
  ./configure --prefix=${INSTALL_DIR}/apr
  make -j "$(nproc)"
  make install
EOT

WORKDIR ${BUILD_DIR}/tcnative/native
RUN <<EOT
  if [ $DISTRIB_MAJOR -eq 8 ]; then
    dnf install -y dnf-plugins-core
    dnf config-manager -y --set-enabled powertools
    dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
    dnf install -y openssl3-devel
    ln -s /usr/include/openssl3/openssl /usr/include/openssl
    export LIBS="-L/usr/lib64/openssl3 -Wl,-rpath,/usr/lib64/openssl3 -lssl -lcrypto"
    export CFLAGS="-I/usr/include/openssl3"
  else dnf install -y openssl-devel
  fi
  dnf clean all
  ./configure \
    --libdir=${INSTALL_DIR}/tcnative \
    --with-apr=${INSTALL_DIR}/apr/bin/apr-1-config \
    --with-java-home="$JAVA_HOME" \
    --disable-openssl-version-check
  make -j "$(nproc)"
  make install
EOT

# hadolint ignore=DL3006
FROM tcnative_build-${DISTRIB_NAME} AS tcnative_build

# hadolint ignore=DL3006
FROM ${IMAGE_JAVA_REPO}/${IMAGE_JAVA_NAME}:${IMAGE_JAVA_TAG}

ARG DISTRIB_MAJOR
ARG CREATED
ARG REVISION
ARG LABEL_NAME="Alfresco Base Tomcat Image"
ARG LABEL_DESC="Apache Tomcat Image tailored for Alfresco products"
ARG LABEL_VENDOR="Hyland"
ARG LABEL_SOURCE="https://github.com/Alfresco/alfresco-docker-base-tomcat"

LABEL org.label-schema.schema-version="1.0" \
  org.label-schema.name="$LABEL_NAME" \
  org.label-schema.description="$LABEL_DESC" \
  org.label-schema.vendor="$LABEL_VENDOR" \
  org.label-schema.build-date="$CREATED" \
  org.label-schema.url="$LABEL_SOURCE" \
  org.label-schema.vcs-url="$LABEL_SOURCE" \
  org.label-schema.vcs-ref="$LABEL_SOURCE" \
  org.opencontainers.image.title="$LABEL_NAME" \
  org.opencontainers.image.description="$LABEL_DESC" \
  org.opencontainers.image.vendor="$LABEL_VENDOR" \
  org.opencontainers.image.authors="Alfresco OPS-Readiness" \
  org.opencontainers.image.revision="$REVISION" \
  org.opencontainers.image.url="$LABEL_SOURCE" \
  org.opencontainers.image.source="$LABEL_SOURCE" \
  org.opencontainers.image.created="$CREATED"

ENV CATALINA_HOME=/usr/local/tomcat
# let "Tomcat Native" live somewhere isolated
ENV TOMCAT_NATIVE_LIBDIR=$CATALINA_HOME/native-jni-lib \
    APR_LIBDIR=$CATALINA_HOME/apr
ENV LD_LIBRARY_PATH=$TOMCAT_NATIVE_LIBDIR:$APR_LIBDIR \
    PATH=$CATALINA_HOME/bin:$PATH

WORKDIR $CATALINA_HOME
# fix permissions (especially for running as non-root)
# https://github.com/docker-library/tomcat/issues/35
RUN groupadd --system tomcat && \
  useradd -M -s /bin/false --home $CATALINA_HOME --system --gid tomcat tomcat

COPY --chown=:tomcat --chmod=640 --from=tomcat_dist /build/tomcat $CATALINA_HOME
COPY --chown=:tomcat --chmod=640 --from=tcnative_build /usr/local/tcnative $TOMCAT_NATIVE_LIBDIR
COPY --chown=:tomcat --chmod=640 --from=tcnative_build /usr/local/apr/lib/libapr-1.so* $APR_LIBDIR/

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

RUN <<EOT
  if [ $DISTRIB_MAJOR -eq 8 ]; then
    dnf install -y dnf-plugins-core
    dnf config-manager -y --set-enabled powertools
    dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
    dnf install -y openssl3-libs
    dnf clean all
  fi
  mkdir -m 770 logs temp work && chgrp tomcat . logs temp work
  chmod ug+x bin/*.sh
  find . -type d -exec chmod 770 {} +
  # verify Tomcat Native is working properly
  nativeLines="$(catalina.sh configtest 2>&1 | grep -c 'Loaded Apache Tomcat Native library')"
  test $nativeLines -ge 1 || { echo "Tomcat Native library not found or not working properly"; exit 1; }
EOT

USER tomcat
EXPOSE 8080

# Starting tomcat with Security Manager
CMD ["catalina.sh", "run", "-security"]
