name: "Bump tomcat version"

scms:
  tomcatGitHub:
    kind: "git"
    spec:
        url: "https://github.com/apache/tomcat.git"
        branch: "main"

sources:
  github:
    name: Get Tomcat version
    kind: gittag
    scmid: tomcatGitHub
    spec:
      versionfilter:
        kind: semver
        pattern: "~{{ requiredEnv "TOMCAT_VERSION" }}"

targets:
  json:
    name: Update version in json target
    kind: json
    sourceid: github
    spec:
      file: tomcat{{ requiredEnv "TOMCAT_MAJOR" }}.json
      key: tomcat_version
