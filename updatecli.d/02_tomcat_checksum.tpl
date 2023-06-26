name: "Bump tomcat checksum"

sources:
  tomcatChecksum:
    name: Retrieve the tomcat binaries archive checksum
    kind: shell
    spec:
      command: ./get-checksum.sh tomcat
      environments:
        - name: TOMCAT_MAJOR
  tcnativeChecksum:
    name: Retrieve the tomcat native libs  checksum
    kind: shell
    spec:
      command: ./get-checksum.sh tcnative
      environments:
        - name: TOMCAT_MAJOR

targets:
  tomcatJson:
    name: Update version in json target
    kind: json
    sourceid: tomcatChecksum
    spec:
      file: tomcat{{ requiredEnv "TOMCAT_MAJOR" }}.json
      key: tomcat_sha512
  tcnativeJson:
    name: Update version in json target
    kind: json
    sourceid: tcnativeChecksum
    spec:
      file: tomcat{{ requiredEnv "TOMCAT_MAJOR" }}.json
      key: tcnative_sha512
