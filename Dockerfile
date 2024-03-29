# Alfresco Base Tomcat Image
# see also https://github.com/docker-library/tomcat
ARG JAVA_MAJOR
ARG DISTRIB_NAME
ARG DISTRIB_MAJOR
ARG TOMCAT_MAJOR

FROM quay.io/alfresco/alfresco-base-java:jre${JAVA_MAJOR}-${DISTRIB_NAME}${DISTRIB_MAJOR} AS base
ENV APACHE_MIRRORS \
  https://archive.apache.org/dist \
  https://dlcdn.apache.org \
  https://downloads.apache.org

ARG TOMCAT_MAJOR
ARG TOMCAT_VERSION
ARG TOMCAT_SHA512
ARG TCNATIVE_VERSION
ARG TCNATIVE_SHA512

FROM base AS tomcat
ARG APACHE_MIRRORS
RUN \
  set -eu; \
  mkdir -p /build/{tcnative,tomcat}; \
  active_mirror=; \
  for mirror in $APACHE_MIRRORS; do \
    if curl -fsSL ${mirror}/tomcat/tomcat-${TOMCAT_MAJOR}/KEYS | gpg --import; then \
      active_mirror=$mirror; \
      break; \
    fi; \
  done; \
  [ -n "active_mirror" ]; \
  \
  echo "Using mirror ${active_mirror}"; \
  for filetype in '.tar.gz' '.tar.gz.asc'; do \
    curl -fsSLo tomcat${filetype} ${active_mirror}/tomcat/tomcat-${TOMCAT_MAJOR}/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}${filetype}; \
    curl -fsSLo tcnative${filetype}  ${active_mirror}/tomcat/tomcat-connectors/native/${TCNATIVE_VERSION}/source/tomcat-native-${TCNATIVE_VERSION}-src${filetype}; \
  done; \
  \
  echo "$TOMCAT_SHA512 *tomcat.tar.gz" | sha512sum -c - || (echo "Checksum did't match: $(sha512sum *tomcat.tar.gz)" && exit 1); \
  echo "$TCNATIVE_SHA512 *tcnative.tar.gz" | sha512sum -c - || (echo "Checksum did't match: $(sha512sum *tcnative.tar.gz)" && exit 1); \
  \
  gpg --batch --verify tcnative.tar.gz.asc tcnative.tar.gz && \
  gpg --batch --verify tomcat.tar.gz.asc tomcat.tar.gz && \
  tar -zxf tomcat.tar.gz -C /build/tomcat --strip-components=1 && \
  tar -zxf tcnative.tar.gz -C /build/tcnative --strip-components=1

FROM tomcat AS TCNATIVE_BUILD
ARG JAVA_MAJOR
ENV JAVA_HOME /usr/lib/jvm/java-openjdk
ARG BUILD_DIR=/build
ARG INSTALL_DIR=/usr/local
RUN set -eu; \
  cd $BUILD_DIR; \
  yum install -y gcc make openssl-devel expat-devel java-${JAVA_MAJOR}-openjdk-devel apr-devel redhat-rpm-config; \
  cd tcnative/native; \
  ./configure \
    --libdir=${INSTALL_DIR}/tcnative \
    --with-apr=/usr/bin/apr-1-config \
    --with-java-home="$JAVA_HOME"; \
  make -j "$(nproc)"; \
  make install

FROM tomcat AS TOMCAT_BUILD
WORKDIR /build/tomcat
RUN \
# sh removes env vars it doesn't support (ones with periods)
# https://github.com/docker-library/tomcat/issues/77
  find ./bin/ -name '*.sh' -exec sed -ri 's|^#!/bin/sh$|#!/usr/bin/env bash|' '{}' +; \
  \
# fix permissions (especially for running as non-root)
# https://github.com/docker-library/tomcat/issues/35
  chmod -R +rX .; \
  chmod 770 logs work ; \
  \
  # Security improvements:
  # Remove server banner, Turn off loggin by the VersionLoggerListener, enable remoteIP valve so we know who we're talking to
  sed -i \
    -e "s/\  <Listener\ className=\"org.apache.catalina.startup.VersionLoggerListener\"/\  <Listener\ className=\"org.apache.catalina.startup.VersionLoggerListener\"\ logArgs=\"false\"/g" \
    -e "s%\(^\s*</Host>\)%\t<Valve className=\"org.apache.catalina.valves.RemoteIpValve\" />\n\n\1%" \
    -e "s/\    <Connector\ port=\"8080\"\ protocol=\"HTTP\/1.1\"/\    <Connector\ port=\"8080\"\ protocol=\"HTTP\/1.1\"\n\               Server=\" \"/g" conf/server.xml; \
  # Removal of default/unwanted Applications
  rm -f -r -d webapps/* ; \
  # Change SHUTDOWN port and command.
  #     sed -i "s/<Server\ port=\"8005\"\ shutdown=\"SHUTDOWN\">/<Server\ port=\"ShutDownPort\"\ shutdown=\"ShutDownCommand\">/g" /usr/local/tomcat/conf/server.xml ; \
  # Replace default 404,403,500 page
  sed -i "$ d" conf/web.xml ; \
  sed -i -e "\$a\    <error-page\>\n\        <error-code\>404<\/error-code\>\n\        <location\>\/error.jsp<\/location\>\n\    <\/error-page\>\n\    <error-page\>\n\        <error-code\>403<\/error-code\>\n\        <location\>\/error.jsp<\/location\>\n\    <\/error-page\>\n\    <error-page\>\n\        <error-code\>500<\/error-code\>\n\        <location\>\/error.jsp<\/location\>\n\    <\/error-page\>\n\n\<\/web-app\>" conf/web.xml

FROM quay.io/alfresco/alfresco-base-java:jre${JAVA_MAJOR}-${DISTRIB_NAME}${DISTRIB_MAJOR} AS TOMCAT_BASE_IMAGE
ARG JAVA_MAJOR
ARG DISTRIB_MAJOR
ARG CREATED
ARG REVISION
LABEL org.label-schema.schema-version="1.0" \
  org.label-schema.name="Alfresco Base Tomcat Image" \
  org.label-schema.vendor="Alfresco" \
  org.label-schema.build-date="$CREATED" \
  org.opencontainers.image.title="Alfresco Base Tomcat Image" \
  org.opencontainers.image.vendor="Alfresco" \
  org.opencontainers.image.revision="$REVISION" \
  org.opencontainers.image.source="https://github.com/Alfresco/alfresco-docker-base-tomcat" \
  org.opencontainers.image.created="$CREATED"
# let "Tomcat Native" live somewhere isolated
ENV CATALINA_HOME /usr/local/tomcat
ENV TOMCAT_NATIVE_LIBDIR $CATALINA_HOME/native-jni-lib
ENV LD_LIBRARY_PATH ${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}$TOMCAT_NATIVE_LIBDIR
ENV PATH $CATALINA_HOME/bin:$PATH
WORKDIR $CATALINA_HOME
COPY --from=TOMCAT_BUILD /build/tomcat $CATALINA_HOME
COPY --from=TCNATIVE_BUILD /usr/local/tcnative $TOMCAT_NATIVE_LIBDIR
RUN \
  set -eu; \
  yum install -y apr; \
  # verify Tomcat Native is working properly
  nativeLines="$(catalina.sh configtest 2>&1 | grep -c 'Loaded Apache Tomcat Native library')" && \
  test $nativeLines -ge 1 || exit 1
EXPOSE 8080
# Starting tomcat with Security Manager
CMD ["catalina.sh", "run", "-security"]
