#!/bin/bash

set -o errexit

# shellcheck disable=SC2155

declare -r here="$(dirname "${BASH_SOURCE[0]}")"
# shellcheck source=../etc/common.sh
source "${here}/../etc/common.sh"
# shellcheck source=../etc/images.sh
source "${here}/../etc/images.sh"
# shellcheck source=../lib/java.sh
source "${here}/../lib/java.sh"
# shellcheck source=../lib/tomcat.sh
source "${here}/../lib/tomcat.sh"

main () {
    local -a versions_a
    IFS=, read -ra versions_a <<< "$java_versions"

    local java
    for java in "${versions_a[@]}"; do
        local java_major_version="${java}"
        java="java_${java}"

        local alfresco_base_java
        alfresco_base_java="${base_image}":$(tomcat::docker::base "${java}")

        export docker_build_extra_args="--build-arg ALFRESCO_BASE_JAVA=${alfresco_base_java}"

        local java_vendor
        java_vendor="$(java::vendor "${java_major_version}")"

        local docker_image_tag
        docker_image_tag="${tomcat_version}-java-${java_major_version}-${java_vendor}-${docker_image_tag_suffix}"

        export repo_tag="${registry}/${namespace}/${docker_image_repository}:${docker_image_tag}"

        ./docker-tools/bin/primary-docker-tag.sh

        unset docker_build_extra_args \
            docker_image_tag \
            repo_tag
    done
}

# environment
declare registry
declare namespace
declare java_versions

# From other file
declare docker_image_repository
declare alfresco_base_java
declare tomcat_version
declare docker_image_tag_suffix

export suffix
export docker_build='true'


# Call main() if we're not sourced
[[ "${BASH_SOURCE[0]}" == "${0}" ]] && main "$@"

