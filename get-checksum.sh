#!/bin/bash -e

case "$1" in
    tomcat)
        VERSION=$(jq -r '.tomcat_version' "tomcat${TOMCAT_MAJOR}.json")
        SHA_URL="https://dlcdn.apache.org/tomcat/tomcat-${TOMCAT_MAJOR}/v${VERSION}/bin/apache-tomcat-${VERSION}.tar.gz.sha512"
    ;;
    tcnative)
        VERSION=$(jq -r '.tcnative_version' "tomcat${TOMCAT_MAJOR}.json")
        SHA_URL="https://dlcdn.apache.org/tomcat/tomcat-connectors/native/${VERSION}/source/tomcat-native-${VERSION}-src.tar.gz.sha512"
    ;;
    apr)
        VERSION=$(jq -r '.apr_version' "tomcat${TOMCAT_MAJOR}.json")
        SHA_URL="https://dlcdn.apache.org/apr/apr-${VERSION}.tar.gz.sha256"
    ;;
esac

SHA_LEN=$((${SHA_URL##*.sha} / 4))

CHECKSUM=$(curl -sLf "${SHA_URL}" | cut -d ' ' -f 1)
if [ ${#CHECKSUM} -eq $SHA_LEN ]; then
    echo "$CHECKSUM"
else
    echo -n "ERROR Looks like checksum cannot be retrieved correctly from ${SHA_URL} - Actual contents: " >&2
    echo "$CHECKSUM" >&2
    exit 1
fi
