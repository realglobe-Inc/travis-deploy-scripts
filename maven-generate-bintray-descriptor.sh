#!/bin/sh -e

# Maven プロジェクトで Bintray にデプロイするために必要な情報ファイルを生成する。

# pom.xml のあるディレクトリで実行する。

desc_file=${DESC_FILE:=bintray.json}
package_repo=${PACKAGE_REPO:=maven}
package_subject=${PACKAGE_SUBJECT:=realglobe}


if ! [ -f pom.xml ]; then
  echo 'no pom.xml' 1>&2
  exit 1
fi

group_id=$(xmllint --xpath '/*[local-name()="project"]/*[local-name()="groupId"]/text()' pom.xml)
artifact_id=$(xmllint --xpath '/*[local-name()="project"]/*[local-name()="artifactId"]/text()' pom.xml)
version=$(xmllint --xpath '/*[local-name()="project"]/*[local-name()="version"]/text()' pom.xml)

package_desc=$(xmllint --xpath '/*[local-name()="project"]/*[local-name()="description"]/text()' pom.xml)
package_website=$(xmllint --xpath '/*[local-name()="project"]/*[local-name()="url"]/text()' pom.xml)
package_vcs=$(xmllint --xpath '/*[local-name()="project"]/*[local-name()="scm"]/*[local-name()="url"]/text()' pom.xml)
version_released=$(date -I)

package_licenses=""
for i in $(seq $(xmllint --xpath 'count(/*[local-name()="project"]/*[local-name()="licenses"]/*[local-name()="license"])' pom.xml)); do
  if [ -n "${package_licenses}" ]; then
    package_licenses="${package_licenses},"
  fi
  license="$(xmllint --xpath '/*[local-name()="project"]/*[local-name()="licenses"]/*[local-name()="license"]['$i']/*[local-name()="name"]/text()' pom.xml)"
  case "${license}" in
    Apache*2.0*)
      license='Apache-2.0'
      ;;
    MIT*)
      license='MIT'
      ;;
    *)
      echo "Unsupported license ${license}" 1>&2
      continue
      ;;
  esac
  package_licenses="${package_licenses}\"${license}\""
done

group_dir=$(echo ${group_id} | sed 's/\./\//g')

force_deploy_option=
if [ -n "${FORCE_DEPLOY}" ]; then
  force_deploy_option=',"matrixParams":{"override":1}'
fi

cat <<EOF > ${desc_file}
{
  "package": {
    "name": "${artifact_id}",
    "repo": "${package_repo}",
    "subject": "${package_subject}",
    "desc": "${package_desc}",
    "website_url": "${package_website}",
    "vcs_url": "${package_vcs}",
    "licenses": [
      ${package_licenses}
    ]
  },
  "version": {
    "name": "${version}",
    "desc": "Version ${version}",
    "released": "${version_released}"
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
