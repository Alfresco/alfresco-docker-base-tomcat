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

targets:
  tomcatJson:
    name: Update Tomcat version in json target
    kind: json
    sourceid: tomcatVersion
    spec:
      file: tomcat{{ requiredEnv "TOMCAT_MAJOR" }}.json
      key: tomcat_version
  tcnativeJson:
    name: Update TCnative version in json target
    kind: json
    sourceid: tcnativeTag
    spec:
      file: tomcat{{ requiredEnv "TOMCAT_MAJOR" }}.json
      key: tcnative_version
  aprJson:
    name: Update APR version in json target
    kind: json
    sourceid: aprTag
    spec:
      file: tomcat{{ requiredEnv "TOMCAT_MAJOR" }}.json
      key: apr_version
