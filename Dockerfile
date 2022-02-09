#
# Alfresco Base Tomcat Image
# see also https://github.com/docker-library/tomcat
ARG JDIST
ARG JAVA_MAJOR
ARG DISTRIB_NAME
ARG DISTRIB_MAJOR
ARG TOMCAT_MAJOR

FROM quay.io/alfresco/alfresco-base-java:${JDIST}${JAVA_MAJOR}-${DISTRIB_NAME}${DISTRIB_MAJOR} AS debian11
ARG JAVA_MAJOR
ENV DEBIAN_FRONTEND=noninteractive
ENV BUILD_DEP="gcc make libssl-dev libexpat1-dev curl gpg"
RUN apt-get -y update; apt-get -qqy install $BUILD_DEP openjdk-${JAVA_MAJOR}-jdk

FROM quay.io/alfresco/alfresco-base-java:$JDIST${JAVA_MAJOR}-$DISTRIB_NAME${DISTRIB_MAJOR} AS ubuntu20.04
ARG JAVA_MAJOR
ENV DEBIAN_FRONTEND=noninteractive
ENV BUILD_DEP="gcc make libssl-dev libexpat1-dev curl gpg"
RUN apt-get -y update; apt-get -qqy install $BUILD_DEP openjdk-${JAVA_MAJOR}-jdk

FROM quay.io/alfresco/alfresco-base-java:$JDIST${JAVA_MAJOR}-$DISTRIB_NAME${DISTRIB_MAJOR} AS centos7
ARG JAVA_MAJOR
ENV BUILD_DEP="gcc make openssl-devel expat-devel"
RUN JRE_PKG_VERSION=$(rpm -qa java-${JAVA_MAJOR}-openjdk-headless --queryformat "%{RPMTAG_VERSION}"); \
    yum install -y $BUILD_DEP java-${JAVA_MAJOR}-openjdk-devel-${JRE_PKG_VERSION}

FROM quay.io/alfresco/alfresco-base-java:$JDIST${JAVA_MAJOR}-$DISTRIB_NAME${DISTRIB_MAJOR} AS ubi8
ARG JAVA_MAJOR
ENV BUILD_DEP="gzip gcc make openssl-devel expat-devel"
USER root
RUN microdnf --setopt=install_weak_deps=0 --setopt=tsflags=nodocs install -y $BUILD_DEP java-${JAVA_MAJOR}-openjdk-devel

FROM $DISTRIB_NAME${DISTRIB_MAJOR} AS tomcat8
ENV TOMCAT_MAJOR 8
ENV TOMCAT_VERSION 8.5.72
ENV TOMCAT_SHA512 41d7eb83120f210d238d8653d729bfb2be32f3666e6c04e73607c05f066c4136b0719f8107cf66673333548c82dc5b9c0357e91fc0ac845e64f055b598f27049

FROM $DISTRIB_NAME${DISTRIB_MAJOR} AS tomcat9
ENV TOMCAT_MAJOR 9
ENV TOMCAT_VERSION 9.0.54
ENV TOMCAT_SHA512 83430f24d42186ce2ff51eeef2f7a5517048f37d9050c45cac1e3dba8926d61a1f7f5aba122a34a11ac1dbdd3c1f6d98671841047df139394d43751263de57c3

FROM $DISTRIB_NAME${DISTRIB_MAJOR} AS tomcat10
ENV TOMCAT_MAJOR 10
ENV TOMCAT_VERSION 10.0.12
ENV TOMCAT_SHA512 e084fc0cc243c0a9ac7de85ffd4b96d00b40b5493ed7ef276d91373fe8036bc953406cd3c48db6b5ae116f2af162fd1bfb13ecdddf5d64523fdd69a9463de8a3

FROM $DISTRIB_NAME${DISTRIB_MAJOR} AS TCNATIVE_BUILD
ARG TCNATIVE_VERSION=1.2.31
ARG TCNATIVE_SHA512=2aaa93f0acf3eb780d39faeda3ece3cf053d3b6e2918462f7183070e8ab32232e035e9062f7c07ceb621006d727d3596d9b4b948f4432b4f625327b72fdb0e49
ARG APR_VERSION=1.7.0
ARG APR_SHA256=48e9dbf45ae3fdc7b491259ffb6ccf7d63049ffacbc1c0977cced095e4c2d5a2
ARG APR_UTIL_VERSION=1.6.1
ARG APR_UTIL_SHA256=b65e40713da57d004123b6319828be7f1273fbc6490e145874ee1177e112c459
ENV BUILD_DIR=/build
ENV INSTALL_DIR=/usr/local
ENV APACHE_MIRRORS \
        https://www.apache.org/dyn/closer.cgi?action=download&filename= \
        https://archive.apache.org/dist \
        https://www-us.apache.org/dist \
        https://www.apache.org/dist
SHELL ["/bin/bash","-c"]
RUN mkdir -p {${INSTALL_DIR},${BUILD_DIR}}/{tcnative,libapr,apr-util}
WORKDIR $BUILD_DIR
RUN set -eux; \
        for mirror in $APACHE_MIRRORS; do \
	        if curl -fsSL ${mirror}/tomcat/tomcat-connectors/KEYS | gpg --import; then \
			curl -fsSL ${mirror}/apr/KEYS | gpg --import; \
			active_mirror=$mirror; \
			break; \
		fi; \
	done; \
	[ -n "active_mirror" ]; \
	\
	for filetype in '.tar.gz' '.tar.gz.asc'; do \
		curl -fsSLo tcnative-${TCNATIVE_VERSION}-src${filetype} "${active_mirror}/tomcat/tomcat-connectors/native/${TCNATIVE_VERSION}/source/tomcat-native-${TCNATIVE_VERSION}-src${filetype}"; \
		curl -fsSLo apr-${APR_VERSION}${filetype} "${active_mirror}/apr/apr-${APR_VERSION}${filetype}"; \
		curl -fsSLo apr-util-${APR_VERSION}${filetype} "${active_mirror}/apr/apr-util-${APR_UTIL_VERSION}${filetype}"; \
	done; \
	\
	echo "$TCNATIVE_SHA512 *tcnative-${TCNATIVE_VERSION}-src.tar.gz" | sha512sum -c -; \
	echo "$APR_SHA256 *apr-${APR_VERSION}.tar.gz" | sha256sum -c -; \
	echo "$APR_UTIL_SHA256 *apr-util-${APR_VERSION}.tar.gz" | sha256sum -c -; \
	\
	gpg --verify tcnative-${TCNATIVE_VERSION}-src.tar.gz.asc && \
        tar -zxf tcnative-${TCNATIVE_VERSION}-src.tar.gz --strip-components=1 -C ${BUILD_DIR}/tcnative; \
	if gpg --verify apr-${APR_VERSION}.tar.gz.asc; then \
		echo signature checked; \
	else \
		keyID=$(gpg --verify apr-${APR_VERSION}.tar.gz.asc 2>&1 | awk '/RSA\ /{print $NF}'); \
		gpg --keyserver pgp.mit.edu --recv-keys "0x$keyID"; \
		gpg --verify apr-${APR_VERSION}.tar.gz.asc; \
	fi && \
        tar -zxf apr-${APR_VERSION}.tar.gz --strip-components=1 -C ${BUILD_DIR}/libapr; \
	if gpg --verify apr-util-${APR_VERSION}.tar.gz.asc; then \
		echo signature checked; \
	else \
		keyID=$(gpg --batch --verify apr-util-${APR_VERSION}.tar.gz.asc 2>&1 | awk '/RSA\ /{print $NF}'); \
		gpg --keyserver pgp.mit.edu --recv-keys "0x$keyID"; \
		gpg --verify apr-util-${APR_VERSION}.tar.gz.asc; \
	fi && \
        tar -zxf apr-util-${APR_VERSION}.tar.gz --strip-components=1 -C ${BUILD_DIR}/apr-util
WORKDIR ${BUILD_DIR}/libapr
RUN ./configure --prefix=${INSTALL_DIR}/apr  && make && make install
WORKDIR ${BUILD_DIR}/apr-util
RUN ./configure  --prefix=${INSTALL_DIR}/apr --with-apr=${INSTALL_DIR}/apr && make && make install
WORKDIR ${BUILD_DIR}/tcnative/native
RUN ./configure \
        --with-java-home="$JAVA_HOME" \
        --libdir="${INSTALL_DIR}/tcnative" \
	--with-apr="${INSTALL_DIR}/apr" \
        --with-ssl=yes; \
    make -j "$(nproc)"; \
    make install

FROM tomcat${TOMCAT_MAJOR} AS TOMCAT_BUILD
RUN mkdir -p /build
# let "Tomcat Native" live somewhere isolated
ENV LD_LIBRARY_PATH ${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}$TOMCAT_NATIVE_LIBDIR
ENV TOMCAT_TGZ_URLS \
# https://issues.apache.org/jira/browse/INFRA-8753?focusedCommentId=14735394#comment-14735394
	https://www.apache.org/dyn/closer.cgi?action=download&filename=tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz \
# if the version is outdated, we might have to pull from the dist/archive
	https://www-us.apache.org/dist/tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz \
	https://www.apache.org/dist/tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz \
	https://archive.apache.org/dist/tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz
ENV TOMCAT_ASC_URLS \
	https://www.apache.org/dyn/closer.cgi?action=download&filename=tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz.asc \
# not all the mirrors actually carry the .asc files :'(
	https://www-us.apache.org/dist/tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz.asc \
	https://www.apache.org/dist/tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz.asc \
	https://archive.apache.org/dist/tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz.asc
RUN set -eux; \
	curl -fsSL https://www.apache.org/dist/tomcat/tomcat-${TOMCAT_MAJOR}/KEYS | gpg --import; \
	# Official tomcat Dockerfile section: Download, build and remove source of Tomcat Native Library \
	success=; \
	for url in $TOMCAT_TGZ_URLS; do \
		if curl -fsSLo tomcat.tar.gz "$url"; then \
			success=1; \
			break; \
		fi; \
	done; \
	[ -n "$success" ]; \
	\
	echo "$TOMCAT_SHA512 *tomcat.tar.gz" | sha512sum -c -; \
	\
	success=; \
	for url in $TOMCAT_ASC_URLS; do \
		if curl -fsSLo tomcat.tar.gz.asc "$url"; then \
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

FROM quay.io/alfresco/alfresco-base-java:$JDIST${JAVA_MAJOR}-$DISTRIB_NAME${DISTRIB_MAJOR} AS TOMCAT_BASE_IMAGE
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
