# Alfresco Base Tomcat Image
# see also https://github.com/docker-library/tomcat
ARG JDIST
ARG JAVA_MAJOR
ARG DISTRIB_NAME
ARG DISTRIB_MAJOR
ARG TOMCAT_MAJOR

FROM quay.io/alfresco/alfresco-base-java:${JDIST}${JAVA_MAJOR}-${DISTRIB_NAME}${DISTRIB_MAJOR} AS tomcat8
ENV TOMCAT_MAJOR 8
ENV TOMCAT_VERSION 8.5.76
ENV TOMCAT_SHA512 7b84a311b2ba3b6c92eea5739275b45686ed893bc000c16ead0a3cfe7c166b12d42485e9eb9c40fe279d207a293c4de65db3107602794f2b8e6071bc4d2b53ed

FROM quay.io/alfresco/alfresco-base-java:${JDIST}${JAVA_MAJOR}-${DISTRIB_NAME}${DISTRIB_MAJOR} AS tomcat9
ENV TOMCAT_MAJOR 9
ENV TOMCAT_VERSION 9.0.59
ENV TOMCAT_SHA512 74902b522abda04afb2be24d7410d4d93966d20fd07dde8f03bb281cdc714866f648babe1ff1ae85d663774779235f1cb9d701d5ce8884052f1f5efca7b62c68

FROM ${DISTRIB_NAME}:${DISTRIB_MAJOR} AS TCNATIVE_BUILD
ARG JAVA_MAJOR
ARG TCNATIVE_VERSION=1.2.33
ARG TCNATIVE_SHA512=b9ffe0ecfd14482ed8c752caf2c28d880ab5fca1f5ea1d5b2a8330d26a14266406bdecda714644603ba2d4ca78c22ec5fc2341afd09172d073f21cf5a1099a0f
ARG APR_VERSION=1.7.0
ARG APR_SHA256=48e9dbf45ae3fdc7b491259ffb6ccf7d63049ffacbc1c0977cced095e4c2d5a2
ARG APR_UTIL_VERSION=1.6.1
ARG APR_UTIL_SHA256=b65e40713da57d004123b6319828be7f1273fbc6490e145874ee1177e112c459
ENV JAVA_HOME /etc/alternatives/jre
ENV BUILD_DIR=/build
ENV INSTALL_DIR=/usr/local
ENV APACHE_MIRRORS \
  https://dlcdn.apache.org \
  https://archive.apache.org/dist \
  https://downloads.apache.org
SHELL ["/bin/bash","-c"]
RUN mkdir -p {${INSTALL_DIR},${BUILD_DIR}}/{tcnative,libapr,apr-util}
WORKDIR $BUILD_DIR
RUN set -eux; \
  BUILD_DEP="gcc make openssl-devel expat-devel java-${JAVA_MAJOR}-openjdk-devel"; \
  yum install -y $BUILD_DEP; \
  for mirror in $APACHE_MIRRORS; do \
    if curl -fsSL ${mirror}/tomcat/tomcat-connectors/KEYS | gpg --import; then \
      curl -fsSL ${mirror}/apr/KEYS | gpg --import; \
      active_mirror=$mirror; \
      break; \
    fi; \
  done; \
  [ -n "active_mirror" ]; \
  \
  echo "Using mirror ${active_mirror}"; \
  for filetype in '.tar.gz' '.tar.gz.asc'; do \
    curl -fsSLo tcnative-${TCNATIVE_VERSION}-src${filetype} "${active_mirror}/tomcat/tomcat-connectors/native/${TCNATIVE_VERSION}/source/tomcat-native-${TCNATIVE_VERSION}-src${filetype}" ; \
    curl -fsSLo apr-${APR_VERSION}${filetype} "${active_mirror}/apr/apr-${APR_VERSION}${filetype}"; \
    curl -fsSLo apr-util-${APR_VERSION}${filetype} "${active_mirror}/apr/apr-util-${APR_UTIL_VERSION}${filetype}"; \
  done; \
  \
  echo "$TCNATIVE_SHA512 *tcnative-${TCNATIVE_VERSION}-src.tar.gz" | sha512sum -c -; \
  echo "$APR_SHA256 *apr-${APR_VERSION}.tar.gz" | sha256sum -c -; \
  echo "$APR_UTIL_SHA256 apr-util-${APR_VERSION}.tar.gz" | sha256sum -c -; \
  \
  gpg --verify tcnative-${TCNATIVE_VERSION}-src.tar.gz.asc && \
    tar -zxf tcnative-${TCNATIVE_VERSION}-src.tar.gz --strip-components=1 -C ${BUILD_DIR}/tcnative; \
# NOTE: disabling signature check as it's broken
#  if gpg --verify apr-${APR_VERSION}.tar.gz.asc; then \
#    echo signature checked; \
#  else \
#    keyID=$(gpg --verify apr-${APR_VERSION}.tar.gz.asc 2>&1 | awk '/RSA\ /{print $NF}'); \
#    gpg --keyserver pgp.mit.edu --recv-keys "0x$keyID"; \
#    gpg --verify apr-${APR_VERSION}.tar.gz.asc; \
#  fi && \
    tar -zxf apr-${APR_VERSION}.tar.gz --strip-components=1 -C ${BUILD_DIR}/libapr; \
# NOTE: disabling signature check as it's broken
#  if gpg --verify apr-util-${APR_VERSION}.tar.gz.asc; then \
#    echo signature checked; \
#  else \
#    keyID=$(gpg --batch --verify apr-util-${APR_VERSION}.tar.gz.asc 2>&1 | awk '/RSA\ /{print $NF}'); \
#    gpg --keyserver pgp.mit.edu --recv-keys "0x$keyID"; \
#    gpg --verify apr-util-${APR_VERSION}.tar.gz.asc; \
#  fi && \
    tar -zxf apr-util-${APR_VERSION}.tar.gz --strip-components=1 -C ${BUILD_DIR}/apr-util
WORKDIR ${BUILD_DIR}/libapr
RUN ./configure --prefix=${INSTALL_DIR}/apr  && make && make install
WORKDIR ${BUILD_DIR}/apr-util
RUN ./configure  --prefix=${INSTALL_DIR}/apr --with-apr=${INSTALL_DIR}/apr && make && make install
WORKDIR ${BUILD_DIR}/tcnative/native
RUN \
  ./configure \
    --with-java-home="$JAVA_HOME" \
    --libdir="${INSTALL_DIR}/tcnative" \
    --with-apr="${INSTALL_DIR}/apr" \
    --with-ssl=yes; \
  make -j "$(nproc)"; \
  make install

FROM tomcat${TOMCAT_MAJOR} AS TOMCAT_BUILD
RUN mkdir -p /build
# let "Tomcat Native" live somewhere isolated
ENV LD_LIBRARY_PATH ${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}${TOMCAT_NATIVE_LIBDIR}
ENV APACHE_MIRRORS \
  https://archive.apache.org/dist \
  https://dlcdn.apache.org \
  https://downloads.apache.org
ENV TOMCAT_TGZ_PATH tomcat/tomcat-${TOMCAT_MAJOR}/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz
ENV TOMCAT_ASC_PATH ${TOMCAT_TGZ_PATH}.asc
RUN set -eux; \
  # Official tomcat Dockerfile section: Download, build and remove source of Tomcat Native Library \
  success=; \
  for mirror in $APACHE_MIRRORS; do \
    if curl -fsSLo tomcat.tar.gz $mirror/$TOMCAT_TGZ_PATH; then \
      success=1; \
      curl -fsSL $mirror/tomcat/tomcat-${TOMCAT_MAJOR}/KEYS | gpg --import; \
      break; \
    fi; \
  done; \
  [ -n "$success" ]; \
  \
  echo "$TOMCAT_SHA512 *tomcat.tar.gz" | sha512sum -c -; \
  \
  success=; \
  for mirror in $APACHE_MIRRORS; do \
    if curl -fsSLo tomcat.tar.gz.asc $mirror/$TOMCAT_ASC_PATH; then \
      success=1; \
      break; \
    fi; \
  done; \
  [ -n "$success" ]; \
  \
  gpg --batch --verify tomcat.tar.gz.asc tomcat.tar.gz && \
  tar -zxf tomcat.tar.gz -C /build --strip-components=1

WORKDIR /build
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

FROM quay.io/alfresco/alfresco-base-java:${JDIST}${JAVA_MAJOR}-${DISTRIB_NAME}${DISTRIB_MAJOR} AS TOMCAT_BASE_IMAGE
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
ENV CATALINA_HOME /usr/local/tomcat
# let "Tomcat Native" live somewhere isolated
ENV TOMCAT_NATIVE_LIBDIR $CATALINA_HOME/native-jni-lib
ENV LD_LIBRARY_PATH ${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}$TOMCAT_NATIVE_LIBDIR
ENV PATH $CATALINA_HOME/bin:$PATH
WORKDIR $CATALINA_HOME
COPY --from=TOMCAT_BUILD /build $CATALINA_HOME
COPY --from=TCNATIVE_BUILD /usr/local/apr /usr/local/apr
COPY --from=TCNATIVE_BUILD /usr/local/tcnative $TOMCAT_NATIVE_LIBDIR
USER root
# verify Tomcat Native is working properly
RUN set -e \
  echo -e "/usr/local/apr/lib\n$TOMCAT_NATIVE_LIBDIR" >> /etc/ld.so.conf.d/tomcat.conf; \
  nativeLines="$(catalina.sh configtest 2>&1 | grep -c 'Loaded Apache Tomcat Native library')" && \
  test $nativeLines -ge 1 || exit 1
EXPOSE 8080
# Starting tomcat with Security Manager
CMD ["catalina.sh", "run", "-security"]
