name: "Bump tomcat versions"

scms:
  tomcatGitHub:
    kind: "git"
    spec:
      url: "https://github.com/apache/tomcat.git"
      branch: "main"
  tcnativeGitHub:
    kind: git
    spec:
      url: https://github.com/apache/tomcat-native.git
      branch: main

sources:
  tomcatTag:
    name: Get Tomcat version
    kind: gittag
    scmid: tomcatGitHub
    spec:
      versionfilter:
        kind: semver
        pattern: "~{{ requiredEnv "TOMCAT_VERSION" }}"
  tcnativeTag:
    name: Get Tomcat Native libs version
    kind: gittag
    scmid: tcnativeGitHub
    spec:
      versionfilter:
        kind: semver
        pattern: "~{{ requiredEnv "TCNATIVE_VERSION" }}"

targets:
  tomcatJson:
    name: Update version in json target
    kind: json
    sourceid: tomcatTag
    spec:
      file: tomcat{{ requiredEnv "TOMCAT_MAJOR" }}.json
      key: tomcat_version
  tcnativeJson:
    name: Update version in json target
    kind: json
    sourceid: tcnativeTag
    spec:
      file: tomcat{{ requiredEnv "TOMCAT_MAJOR" }}.json
      key: tomcat_version
