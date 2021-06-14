# Alfresco Base Tomcat Image
# see also https://github.com/docker-library/tomcat
ARG JAVA_MAJOR
ARG CENTOS_MAJOR
ARG TOMCAT_MAJOR

FROM java-$JAVA_MAJOR-centos-$CENTOS_MAJOR AS tomcat-8
ENV TOMCAT_MAJOR 8
ENV TOMCAT_VERSION 8.5.65
ENV TOMCAT_SHA512 eb5a77d75a46496f7de39c1cba5f4fc4991ec7da7717e7b37ad48b4ca2ea334aeabfd094f64977477b4b2352637b56e30e5d9acfcdf7ccd5f4269a824829dd39

FROM java-$JAVA_MAJOR-centos-$CENTOS_MAJOR AS tomcat-9
ENV TOMCAT_MAJOR 9
ENV TOMCAT_VERSION 9.0.45
ENV TOMCAT_SHA512 81bfbd1f13dabc178635a2841c1566d080e209dff36170f6f4f354e3b2b3878f603fc8978c0c132655fca3653166e68094d61c3dcfc5edf07bc7e5419d20c0d1

FROM tomcat-$TOMCAT_MAJOR
ARG JAVA_MAJOR
ARG CENTOS_MAJOR
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
	[ ${CENTOS_MAJOR} = 7 ] && deps=" \
		apr-1.4.8-7.el7 \
	"; \
	[ ${CENTOS_MAJOR} = 8 ] && yum update -y; \
	[ ${CENTOS_MAJOR} = 8 ] && deps=" \
		apr-1.6.3-11.el8 \
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
	tar -xvf bin/tomcat-native.tar.gz -C "$nativeBuildDir" --strip-components=1; \
	[ ${CENTOS_MAJOR} = 7 ] && nativeBuildDeps=" \
		apr-devel-1.4.8-7.el7 \
		gcc-4.8.5-44.el7 \
		make-3.82-24.el7 \
		openssl-devel-1.0.2k-21.el7_9 \
	"; \
	[ ${CENTOS_MAJOR} = 8 ] && nativeBuildDeps=" \
		apr-devel-1.6.3-11.el8 \
		gcc-8.4.1-1.el8 \
		make-4.2.1-10.el8 \
		openssl-devel-1.1.1g-15.el8_3 \
		redhat-rpm-config-125-1.el8 \
		glibc-all-langpacks-2.28-151.el8 \
	"; \
	yum install -y $nativeBuildDeps; \
	( \
		export CATALINA_HOME="$PWD"; \
		cd "$nativeBuildDir/native"; \
		./configure \
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
	# Remove server banner
	sed -i "s/\    <Connector\ port=\"8080\"\ protocol=\"HTTP\/1.1\"/\    <Connector\ port=\"8080\"\ protocol=\"HTTP\/1.1\"\n\               Server=\" \"/g" /usr/local/tomcat/conf/server.xml ; \
	# Removal of default/unwanted Applications
	rm -f -r -d /usr/local/tomcat/webapps/* ; \
	# Change SHUTDOWN port and command.
	#     sed -i "s/<Server\ port=\"8005\"\ shutdown=\"SHUTDOWN\">/<Server\ port=\"ShutDownPort\"\ shutdown=\"ShutDownCommand\">/g" /usr/local/tomcat/conf/server.xml ; \
	# Replace default 404,403,500 page
	sed -i "$ d" /usr/local/tomcat/conf/web.xml ; \
	sed -i -e "\$a\    <error-page\>\n\        <error-code\>404<\/error-code\>\n\        <location\>\/error.jsp<\/location\>\n\    <\/error-page\>\n\    <error-page\>\n\        <error-code\>403<\/error-code\>\n\        <location\>\/error.jsp<\/location\>\n\    <\/error-page\>\n\    <error-page\>\n\        <error-code\>500<\/error-code\>\n\        <location\>\/error.jsp<\/location\>\n\    <\/error-page\>\n\n\<\/web-app\>" /usr/local/tomcat/conf/web.xml ; \
	#Turn off loggin by the VersionLoggerListener
	sed -i "s/\  <Listener\ className=\"org.apache.catalina.startup.VersionLoggerListener\"/\  <Listener\ className=\"org.apache.catalina.startup.VersionLoggerListener\"\ logArgs=\"false\"/g" /usr/local/tomcat/conf/server.xml ; \
	yum clean all

# verify Tomcat Native is working properly
RUN set -e \
	&& nativeLines="$(catalina.sh configtest 2>&1)" \
	&& nativeLines="$(echo "$nativeLines" | grep 'Apache Tomcat Native')" \
	&& nativeLines="$(echo "$nativeLines" | sort -u)" \
	&& if ! echo "$nativeLines" | grep 'Apache Tomcat Native library' >&2; then \
		echo >&2 "$nativeLines"; \
		exit 1; \
	fi

EXPOSE 8080
# Starting tomcat with Security Manager
CMD ["catalina.sh", "run", "-security"]
