#!/bin/sh -e

# Gradle プロジェクトで Maven 用スクリプトが動くようにファイルを準備する。

# パッケージファイルをローカルインストールしておくこと。


module_dir=${MODULE_DIR?}


# pom.xml
cp ${module_dir}/build/poms/pom-default.xml pom.xml

group_id=$(xmllint --xpath '/*[local-name()="project"]/*[local-name()="groupId"]/text()' pom.xml)
artifact_id=$(xmllint --xpath '/*[local-name()="project"]/*[local-name()="artifactId"]/text()' pom.xml)
version=$(xmllint --xpath '/*[local-name()="project"]/*[local-name()="version"]/text()' pom.xml)


# javadoc
mkdir -p target/site
cp -r ${module_dir}/build/docs/javadoc target/site/apidocs


# jar
group_dir=$(echo ${group_id} | sed 's/\./\//g')
for ext in jar aar; do
  cp ~/.m2/repository/${group_dir}/${artifact_id}/${version}/*.${ext} target/
done
