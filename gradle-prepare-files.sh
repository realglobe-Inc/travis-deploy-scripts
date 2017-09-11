#!/bin/sh -e

# Copyright 2017 realglobe Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# Gradle プロジェクトで Maven 用スクリプトが動くようにファイルを準備する。

# パッケージファイルをローカルインストールしておくこと。


module_dir=${MODULE_DIR?}

if ! which xmllint > /dev/null; then
  sudo apt-get install -y libxml2-utils
fi

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
