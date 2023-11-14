#!/bin/bash -e
set -o pipefail

if ! command -v htmlq &> /dev/null; then
    echo "htmlq is required."
    exit 1
fi

if [ -z "$TOMCAT_MAJOR" ]; then
    echo "TOMCAT_MAJOR must be set."
    exit 1
fi

if [ "$TOMCAT_MAJOR" -ge 10 ]; then
    VERSION=$TOMCAT_MAJOR
else
    VERSION="${TOMCAT_MAJOR}0"
fi

curl -sf "https://tomcat.apache.org/download-${VERSION}.cgi" | htmlq --text --attribute href a | grep '^#' | cut -d'#' -f 2
