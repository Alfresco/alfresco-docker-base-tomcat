name: "Bump tomcat checksum"

sources:
  checksum:
    name: Retrieve the package checksum
    kind: shell
    spec:
      command: ./get-checksum.sh
      environments:
        - name: TOMCAT_MAJOR

targets:
  json:
    name: Update version in json target
    kind: json
    sourceid: checksum
    spec:
      file: tomcat{{ requiredEnv "TOMCAT_MAJOR" }}.json
      key: tomcat_sha512
