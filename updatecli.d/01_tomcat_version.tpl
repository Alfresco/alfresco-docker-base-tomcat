name: "Bump tomcat versions"

scms:
  tcnativeGitHub:
    kind: git
    spec:
      url: https://github.com/apache/tomcat-native.git
      branch: main

sources:
  tomcatVersion:
    name: Retrieve the tomcat latest version
    kind: shell
    spec:
      command: ./get-tomcat-version.sh tomcat
      environments:
        - name: TOMCAT_MAJOR
  tcnativeTag:
    name: Get Tomcat Native libs version
    kind: gittag
    scmid: tcnativeGitHub
    spec:
      versionfilter:
        kind: semver
        pattern: "~{{ requiredEnv "TCNATIVE_SOURCE_PATTERN" }}"

targets:
  tomcatJson:
    name: Update version in json target
    kind: json
    sourceid: tomcatVersion
    spec:
      file: tomcat{{ requiredEnv "TOMCAT_MAJOR" }}.json
      key: tomcat_version
  tcnativeJson:
    name: Update version in json target
    kind: json
    sourceid: tcnativeTag
    spec:
      file: tomcat{{ requiredEnv "TOMCAT_MAJOR" }}.json
      key: tcnative_version
