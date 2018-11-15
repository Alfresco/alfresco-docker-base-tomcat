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
    # shellcheck disable=SC2086
    IFS=, read -ra versions_a <<< $java_versions

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

        local private_repo_tag
        private_repo_tag="${registry}/${namespace}/${docker_image_repository}:${docker_image_tag}"
    
        export private_repo_tag
        
        # Get the short tag (java major version)
        # shellcheck disable=SC2091
        if $(tomcat::docker::is_short "${java}"); then
            # This variable is used by release-docker-tags.sh
            local DOCKER_IMAGE_TAG_SHORT_NAME
            DOCKER_IMAGE_TAG_SHORT_NAME="${short_name}"

            export DOCKER_IMAGE_TAG_SHORT_NAME
        fi    

        ./docker-tools/bin/release-docker-tags.sh

        unset docker_build_extra_args \
            docker_image_tag \
            DOCKER_IMAGE_TAG_SHORT_NAME

    done
}

# environment
declare registry
declare namespace
declare java_versions

# From other file
declare base_image
declare docker_image_repository
declare short_name
declare docker_image_tag_suffix

export suffix
export docker_build='true'


# Call main() if we're not sourced
[[ "${BASH_SOURCE[0]}" == "${0}" ]] && main "$@"

