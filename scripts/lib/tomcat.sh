#!/bin/bash

tomcat::docker::base () {
    local java_as_str
    java_as_str=$(declare -p "$1")
    # shellcheck disable=SC2086
    eval "declare -A java="${java_as_str#*=}

    # shellcheck disable=SC2154
    echo "${java[base_tag]}"
}

# Am i the short tag?
tomcat::docker::is_short () {
    local java_as_str
    java_as_str=$(declare -p "$1")
    # shellcheck disable=SC2086
    eval "declare -A java="${java_as_str#*=}

    # shellcheck disable=SC2154
    [ -z "${java[short_tag]}" ] && return 1
    return 0
}