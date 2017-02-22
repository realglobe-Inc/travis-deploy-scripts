#!/bin/sh -e

# Maven プロジェクトのパッケージが既にデプロイされているか調べる。
# パッケージが既に存在する場合は 0 で終了。まだ存在しない場合、確認できなかった場合は 0 以外で終了。

# pom.xml のあるディレクトリで実行する。

repo_prefix=${REPO_PREFIX:=https://dl.bintray.com/realglobe/maven}

if ! [ -f pom.xml ]; then
  echo 'no pom.xml' 1>&2
  exit 1
fi

group_id=$(xmllint --xpath '/*[local-name()="project"]/*[local-name()="groupId"]/text()' pom.xml)
artifact_id=$(xmllint --xpath '/*[local-name()="project"]/*[local-name()="artifactId"]/text()' pom.xml)
version=$(xmllint --xpath '/*[local-name()="project"]/*[local-name()="version"]/text()' pom.xml)

# 末尾の / が無いとパッケージが存在しても 301 Moved Permanently
repo_url=${repo_prefix}/$(echo ${group_id} | sed 's/\./\//g')/${artifact_id}/${version}/

status_code=$(curl --head -s -w '%{http_code}' -o /dev/null ${repo_url})

[ "${status_code}" = 200 ]
