#!/bin/bash

# Given 8u181 or 11 or 11.0.1 return 8 or 11
java::version::major () {
    local java_version="$1"

    IFS='u' read -ra java_version <<< "${java_version}"
    IFS='.' read -ra java_version <<< "${java_version}"

    echo "${java_version}"
}

# Given 8u181 or 11 or 11.0.1 return if oracle or openjdk
# Hint: it's always OpenJDK unless we're on 8
java::vendor () {
    local java_version="$1"

    java_version=$(java::version::major "${java_version}")

    if [ "${java_version}" -lt 11 ]; then
        echo 'oracle'
    else
        echo 'openjdk'
    fi
}
