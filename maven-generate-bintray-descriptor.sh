#!/bin/sh -e

# Maven プロジェクトで Bintray にデプロイするために必要な情報ファイルを生成する。

# pom.xml のあるディレクトリで実行する。

desc_file=${DESC_FILE:=bintray.json}


if ! [ -f pom.xml ]; then
  echo 'no pom.xml' 1>&2
  exit 1
fi

group_id=$(xmllint --xpath '/*[local-name()="project"]/*[local-name()="groupId"]/text()' pom.xml)
artifact_id=$(xmllint --xpath '/*[local-name()="project"]/*[local-name()="artifactId"]/text()' pom.xml)
version=$(xmllint --xpath '/*[local-name()="project"]/*[local-name()="version"]/text()' pom.xml)
date=$(date -I)

group_dir=$(echo ${group_id} | sed 's/\./\//g')

force_deploy_option=
if [ -n "${FORCE_DEPLOY}" ]; then
  force_deploy_option=',"matrixParams":{"override":1}'
fi

cat <<EOF > ${desc_file}
{
  "package": {
    "name": "${artifact_id}",
    "repo": "maven",
    "subject": "realglobe"
  },
  "version": {
    "name": "${version}",
    "desc": "${version}",
    "released": "${date}"
  },
  "files": [{
    "includePattern": "target/(.*\\\\.jar)",
    "uploadPattern": "/${group_dir}/${artifact_id}/${version}/\$1"${force_deploy_option}
  }, {
    "includePattern": "pom.xml",
    "uploadPattern": "/${group_dir}/${artifact_id}/${version}/${artifact_id}-${version}.pom"${force_deploy_option}
  }],
  "publish": true
}
EOF
