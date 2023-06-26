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
esac

CHECKSUM=$(curl -sf "${SHA_URL}" | cut -d ' ' -f 1)
if [ ${#CHECKSUM} -eq 128 ]; then
    echo "$CHECKSUM"
else
    echo -n 'ERROR Looks like checksum cannot be retrieved correctly. Actual contents: ' >&2
    echo "$CHECKSUM" >&2
    exit 1
fi
