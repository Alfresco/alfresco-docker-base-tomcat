name: "Bump tomcat versions"

scms:
  tcnativeGitHub:
    kind: git
    spec:
      url: https://github.com/apache/tomcat-native.git
      branch: main
  aprGitHub:
    kind: git
    spec:
      url: https://github.com/apache/apr.git
      branch: trunk

sources:
  tomcatVersion:
    name: Retrieve the tomcat latest version
    kind: shell
    spec:
      command: ./get-tomcat-version.sh tomcat
      environments:
        - name: PATH
        - name: TOMCAT_MAJOR
  tcnativeTag:
    name: Get Tomcat Native libs version
    kind: gittag
    scmid: tcnativeGitHub
    spec:
      versionfilter:
        kind: semver
        pattern: "~{{ requiredEnv "TCNATIVE_SOURCE_PATTERN" }}"
  aprTag:
    name: Get Apache APR library version
    kind: gittag
    scmid: aprGitHub
    spec:
      versionfilter:
        kind: semver
        pattern: "~{{ requiredEnv "APR_SOURCE_PATTERN" }}"

conditions:
  isTCNativeFullyReleased:
    name: Check if tcnative is fully released
    kind: http
    sourceid: tcnativeTag
    spec:
      url: https://archive.apache.org/dist/tomcat/tomcat-connectors/native/{{ source `tcnativeTag` }}/source/tomcat-native-{{ source `tcnativeTag` }}-src.tar.gz
      request:
        verb: HEAD

targets:
  tomcatJson:
    name: Update Tomcat version in json target
    kind: json
    sourceid: tomcatVersion
    spec:
      engine: dasel/v2
      file: tomcat{{ requiredEnv "TOMCAT_MAJOR" }}.json
      key: tomcat_version
  tcnativeJson:
    name: Update TCnative version in json target
    kind: json
    sourceid: tcnativeTag
    spec:
      engine: dasel/v2
      file: tomcat{{ requiredEnv "TOMCAT_MAJOR" }}.json
      key: tcnative_version
  aprJson:
    name: Update APR version in json target
    kind: json
    sourceid: aprTag
    spec:
      engine: dasel/v2
      file: tomcat{{ requiredEnv "TOMCAT_MAJOR" }}.json
      key: apr_version
