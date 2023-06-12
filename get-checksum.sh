#!/bin/bash -e
TOMCAT_VERSION=$(jq -r '.tomcat_version' "tomcat${TOMCAT_MAJOR}.json")
CHECKSUM=$(curl -sf "https://dlcdn.apache.org/tomcat/tomcat-${TOMCAT_MAJOR}/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz.sha512" | cut -d ' ' -f 1)
if [ ${#CHECKSUM} -eq 128 ]; then
    echo "$CHECKSUM"
else
    echo 'ERROR Looks like checksum cannot be retrived correctly. Actual contents:' >&2
    echo "$CHECKSUM" >&2
    exit 1
fi
