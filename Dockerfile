# Alfresco Base Tomcat Image
# see also https://github.com/docker-library/tomcat
ARG JAVA_MAJOR
ARG DISTRIB_NAME
ARG DISTRIB_MAJOR
ARG TOMCAT_MAJOR

FROM java-$JAVA_MAJOR-$DISTRIB_NAME-$DISTRIB_MAJOR AS tomcat-8
ENV TOMCAT_MAJOR 8
ENV TOMCAT_VERSION 8.5.70
ENV TOMCAT_SHA512 10d306a2ea27e10b914556678763e2b1295ffdaa3da042db586d39b9ab95640bd3e1b81627f96c61f400f2db98a7d4b4bbdf21dc3238c8d0025bf95b08f2f61c

FROM java-$JAVA_MAJOR-$DISTRIB_NAME-$DISTRIB_MAJOR AS tomcat-9
ENV TOMCAT_MAJOR 9
ENV TOMCAT_VERSION 9.0.52
ENV TOMCAT_SHA512 35e007e8e30e12889da27f9c71a6f4997b9cb5023b703d99add5de9271828e7d8d4956bf34dd2f48c7c71b4f8480f318c9067a4cd2a6d76eaae466286db4897b

FROM java-$JAVA_MAJOR-$DISTRIB_NAME-$DISTRIB_MAJOR AS tomcat-10
ENV TOMCAT_MAJOR 10
ENV TOMCAT_VERSION 10.0.10
ENV TOMCAT_SHA512 3f6d5d292ab67348b3134c1013044c948caf5a4bf142b4e856b5ee63693a6e80994b0b4dbb3404d0fd3542fd6f7f52b4cbe404fc5a0f716ac98d68db879b7112

FROM tomcat-$TOMCAT_MAJOR
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
ENV PATH $CATALINA_HOME/bin:$PATH
RUN mkdir -p "$CATALINA_HOME"
WORKDIR $CATALINA_HOME

# let "Tomcat Native" live somewhere isolated
ENV TOMCAT_NATIVE_LIBDIR $CATALINA_HOME/native-jni-lib
ENV LD_LIBRARY_PATH ${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}$TOMCAT_NATIVE_LIBDIR

ENV TOMCAT_TGZ_URLS \
# https://issues.apache.org/jira/browse/INFRA-8753?focusedCommentId=14735394#comment-14735394
	https://www.apache.org/dyn/closer.cgi?action=download&filename=tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz \
# if the version is outdated, we might have to pull from the dist/archive :/
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
	# CentOS specific addition: Install RPMs needed to build Tomcat Native Library \
	# We're version-pinning to improve the chances of repeatable builds. [DEPLOY-433] \
	# openssl's version is always the same as the openssl-libs RPM already installed \
	[[ ${DISTRIB_MAJOR} = 7 && ${JAVA_MAJOR} = 8 ]] && deps="\
		apr-1.4.8-7.el7 \
	"; \
	[[ ${DISTRIB_MAJOR} = 7 && ${JAVA_MAJOR} = 11 ]] && deps="\
		apr-1.4.8-7.el7 \
	"; \
	yum install -y $deps; \
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
	gpg --batch --verify tomcat.tar.gz.asc tomcat.tar.gz; \
	tar -xvf tomcat.tar.gz --strip-components=1; \
	rm bin/*.bat; \
	rm tomcat.tar.gz*; \
	\
	nativeBuildDir="$(mktemp -d)"; \
	[ ${JAVA_MAJOR} == 8 ] && JAVA_MAJOR_PKG=1.8.0; \
	JRE_PKG_VERSION=$(rpm -qa java-${JAVA_MAJOR_PKG:-$JAVA_MAJOR}-openjdk-headless --queryformat "%{RPMTAG_VERSION}"); \
	tar -xvf bin/tomcat-native.tar.gz -C "$nativeBuildDir" --strip-components=1; \
	[ ${DISTRIB_MAJOR} = 7 ] && nativeBuildDeps=" \
		apr-devel-1.4.8-7.el7 \
		gcc-4.8.5-44.el7 \
		make-3.82-24.el7 \
		openssl-devel-1.0.2k-21.el7_9 \
	"; \
	yum install -y "java-${JAVA_MAJOR_PKG:-$JAVA_MAJOR}-openjdk-devel-${JRE_PKG_VERSION}"; \
	yum install -y $nativeBuildDeps; \
	( \
		export CATALINA_HOME="$PWD"; \
		cd "$nativeBuildDir/native"; \
		./configure \
			--with-java-home="$JDK_HOME" \
			--libdir="$TOMCAT_NATIVE_LIBDIR" \
			--prefix="$CATALINA_HOME" \
			--with-apr="$(which apr-1-config)" \
			--with-ssl=yes; \
		make -j "$(nproc)"; \
		make install; \
	); \
	yum history -y rollback last-1; \
	find /etc -mindepth 2 -name *.rpmsave -exec rm -v '{}' +; \
	rm -rf "$nativeBuildDir"; \
	rm bin/tomcat-native.tar.gz; \
	\
# sh removes env vars it doesn't support (ones with periods)
# https://github.com/docker-library/tomcat/issues/77
	find ./bin/ -name '*.sh' -exec sed -ri 's|^#!/bin/sh$|#!/usr/bin/env bash|' '{}' +; \
	\
# fix permissions (especially for running as non-root)
# https://github.com/docker-library/tomcat/issues/35
	chmod -R +rX .; \
	chmod 777 logs work ; \
	\
	# Security improvements:
	# Remove server banner, Turn off loggin by the VersionLoggerListener, enable remoteIP valve so we know who we're talking to
	sed -i \
          -e "s/\  <Listener\ className=\"org.apache.catalina.startup.VersionLoggerListener\"/\  <Listener\ className=\"org.apache.catalina.startup.VersionLoggerListener\"\ logArgs=\"false\"/g" \
          -e "s%\(^\s*</Host>\)%\t<Valve className=\"org.apache.catalina.valves.RemoteIpValve\" />\n\n\1%" \
          -e "s/\    <Connector\ port=\"8080\"\ protocol=\"HTTP\/1.1\"/\    <Connector\ port=\"8080\"\ protocol=\"HTTP\/1.1\"\n\               Server=\" \"/g" /usr/local/tomcat/conf/server.xml; \
	# Removal of default/unwanted Applications
	rm -f -r -d /usr/local/tomcat/webapps/* ; \
	# Change SHUTDOWN port and command.
	#     sed -i "s/<Server\ port=\"8005\"\ shutdown=\"SHUTDOWN\">/<Server\ port=\"ShutDownPort\"\ shutdown=\"ShutDownCommand\">/g" /usr/local/tomcat/conf/server.xml ; \
	# Replace default 404,403,500 page
	sed -i "$ d" /usr/local/tomcat/conf/web.xml ; \
	sed -i -e "\$a\    <error-page\>\n\        <error-code\>404<\/error-code\>\n\        <location\>\/error.jsp<\/location\>\n\    <\/error-page\>\n\    <error-page\>\n\        <error-code\>403<\/error-code\>\n\        <location\>\/error.jsp<\/location\>\n\    <\/error-page\>\n\    <error-page\>\n\        <error-code\>500<\/error-code\>\n\        <location\>\/error.jsp<\/location\>\n\    <\/error-page\>\n\n\<\/web-app\>" /usr/local/tomcat/conf/web.xml ; \
	yum clean all

# verify Tomcat Native is working properly
RUN set -e \
	&& nativeLines="$(catalina.sh configtest 2>&1 | grep -c 'Loaded Apache Tomcat Native library')" \
	&& test $nativeLines -ge 1 || exit 1

EXPOSE 8080
# Starting tomcat with Security Manager
CMD ["catalina.sh", "run", "-security"]
