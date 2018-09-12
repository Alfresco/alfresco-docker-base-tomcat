# Alfresco Base Tomcat Image
# see also https://github.com/docker-library/tomcat/blob/master/8.5/jre8/Dockerfile
FROM quay.io/alfresco/alfresco-base-java:8u181-oracle-centos-7-fbda83b9c4da	

LABEL name="Alfresco Base Tomcat" \
    vendor="Alfresco" \
    license="Various" \
    build-date="unset"

ENV CATALINA_HOME /usr/local/tomcat
ENV PATH $CATALINA_HOME/bin:$PATH
RUN mkdir -p "$CATALINA_HOME"
WORKDIR $CATALINA_HOME

# let "Tomcat Native" live somewhere isolated
ENV TOMCAT_NATIVE_LIBDIR $CATALINA_HOME/native-jni-lib
ENV LD_LIBRARY_PATH ${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}$TOMCAT_NATIVE_LIBDIR

# see https://www.apache.org/dist/tomcat/tomcat-$TOMCAT_MAJOR/KEYS
# see also "update.sh" (https://github.com/docker-library/tomcat/blob/master/update.sh)
# During DEPLOY-580: Work around keyservers randomly not responding
ENV GPG_KEYS 05AB33110949707C93A279E3D3EFE6B686867BA6 07E48665A34DCAFAE522E5E6266191C37C037D42 47309207D818FFD8DCD3F83F1931D684307A10A5 541FBE7D8F78B25E055DDEE13C370389288584E7 61B832AC2F1C5A90F0F9B00A1C506407564C17A3 713DA88BE50911535FE716F5208B0AB1D63011C7 79F7026C690BAA50B92CD8B66A3AD3F4F22C4FED 9BA44C2621385CB966EBA586F72C284D731FABEE A27677289986DB50844682F8ACB77FC2E86E29AC A9C5DF4D22E99998D9875A5110C01C5A2F6059E7 DCFD35E0BF8CA7344752DE8B6FB21E8933C60243 F3A04C595DB5B6A5F1ECA43E3B7BBB100D811BBE F7DA48BB64BCB84ECBA7EE6935CD23C10D498E23
RUN set -ex; \
	for key in $GPG_KEYS; do \
		for i in $(seq 1 4); do \
			[ $i -lt 4 ] && set +e ; \
			gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
			retval=$? ; \
			set -e ; \
			[ $retval = 0 ] && break ; \
		done \
	done

ENV TOMCAT_MAJOR
ENV TOMCAT_VERSION 8.5.33
ENV TOMCAT_SHA512 bb6b3c27284697a835d1625bf63921b6147f98f3e1167b896d28b05bbcf7d6c71baa0aef35d8405ad41f897985dacf288f3a403b7d65bd726808637d97bfad11


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
  yum install -y \
		apr-1.4.8-3.el7_4.1 \
		apr-devel \
		apr-util-1.5.2-6.el7 \
		apr-util-devel \
		openssl \
		openssl-devel \
		wget-1.14-15.el7_4.1 \
		gcc-4.8.5-28.el7_5.1 \
		automake-1.13.4-3.el7 \
		autoconf-2.69-11.el7 ; \
  # Official tomcat Dockerfile section: Download, build and remove source of Tomcat Native Library \
	success=; \
	for url in $TOMCAT_TGZ_URLS; do \
		if wget -O tomcat.tar.gz "$url"; then \
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
		if wget -O tomcat.tar.gz.asc "$url"; then \
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
	( \
		export CATALINA_HOME="$PWD"; \
		cd "$nativeBuildDir/native"; \
    gnuArch="$(arch)"; \
		./configure \
			--build="$gnuArch" \
			--libdir="$TOMCAT_NATIVE_LIBDIR" \
			--prefix="$CATALINA_HOME" \
			--with-apr="$(which apr-1-config)" \
			--with-ssl=yes; \
		make -j "$(nproc)"; \
		make install; \
	); \
	rm -rf "$nativeBuildDir"; \
	rm bin/tomcat-native.tar.gz; \
	\
# sh removes env vars it doesn't support (ones with periods)
# https://github.com/docker-library/tomcat/issues/77
	find ./bin/ -name '*.sh' -exec sed -ri 's|^#!/bin/sh$|#!/usr/bin/env bash|' '{}' + ; \
	# CentOS specific addition: Delete RPMs installed by above yum command (only) \
	\
	rpm -e mpfr libmpc libmnl libnfnetlink libnetfilter_conntrack iptables iproute \
      apr-util apr-devel cpp libdb-devel m4 groff-base perl-parent perl-HTTP-Tiny perl-podlators \
      perl-Pod-Perldoc perl-Text-ParseWords perl-Pod-Escapes perl-Encode perl-Pod-Usage perl-macros \
      perl-libs perl-Socket perl-Time-HiRes perl-Exporter perl-constant perl-Filter perl-Carp \
      perl-Storable perl-PathTools perl-Scalar-List-Utils perl-Time-Local perl-File-Temp perl-File-Path \
      perl-threads-shared perl-threads perl-Pod-Simple perl-Getopt-Long perl perl-Test-Harness \
      perl-Thread-Queue perl-Data-Dumper autoconf libkadm5 libgomp sysvinit-tools initscripts cyrus-sasl \
      cyrus-sasl-devel openldap-devel make kernel-headers glibc-headers glibc-devel libsepol-devel \
      pcre-devel libselinux-devel libcom_err-devel libverto-devel expat-devel keyutils-libs-devel \
      krb5-devel zlib-devel openssl-devel apr-util-devel gcc openssl automake wget ; \
    # Security improvements:
    # Remove server banner
    sed -i "s/\    <Connector\ port=\"8080\"\ protocol=\"HTTP\/1.1\"/\    <Connector\ port=\"8080\"\ protocol=\"HTTP\/1.1\"\n\               Server=\" \"/g" /usr/local/tomcat/conf/server.xml ; \
    # Add httpOnly flag to Cookies
    sed -i "s/\    <\/session-config>/\        <cookie-config>\n\            <http-only>true<\/http-only> \n\            <secure>true<\/secure>\n\        <\/cookie-config>\n\    <\/session-config>/g" /usr/local/tomcat/conf/web.xml ; \
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
	&& nativeLines="$(catalina.sh configtest 2>&1)" \
	&& nativeLines="$(echo "$nativeLines" | grep 'Apache Tomcat Native')" \
	&& nativeLines="$(echo "$nativeLines" | sort -u)" \
	&& if ! echo "$nativeLines" | grep 'INFO: Loaded APR based Apache Tomcat Native library' >&2; then \
		echo >&2 "$nativeLines"; \
		exit 1; \
	fi

EXPOSE 8080
# Starting tomcat with Security Manager
CMD ["catalina.sh", "run", "-security"]