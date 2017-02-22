#!/bin/sh -e

# Maven プロジェクトで Javadoc を生成して GitHub Pages にデプロイする

# 1. デプロイ用の鍵ペアを用意する
# 2. 公開鍵を Github の Javadoc 用プロジェクト（デプロイ先）の Deploy Keys に登録する
# 3. 秘密鍵をデプロイ元プロジェクトディレクトリで travis encrypt-file して追加する
# 4. Travis CI のデプロイ元プロジェクトの環境変数に ENCRYPTION_LABEL を追加する

javadoc_repo=${JAVADOC_REPO:=https://github.com/realglobe-Inc/javadoc.git}
deploy_key=${DEPLOY_KEY:=javadoc-deploy-key.enc}


if ! [ -f ${deploy_key} ]; then
  echo "no ${deploy_key}" 1>&2
  exit 1
elif [ -z "${ENCRYPTION_LABEL}" ]; then
  echo 'no environment variable ENCRYPTION_LABEL' 1>&2
  exit 1
fi

group_id=$(xmllint --xpath '/*[local-name()="project"]/*[local-name()="groupId"]/text()' pom.xml)
artifact_id=$(xmllint --xpath '/*[local-name()="project"]/*[local-name()="artifactId"]/text()' pom.xml)
version=$(xmllint --xpath '/*[local-name()="project"]/*[local-name()="version"]/text()' pom.xml)


# デプロイ用の ssh 鍵を準備する
encrypted_key_var="encrypted_${ENCRYPTION_LABEL}_key"
encrypted_iv_var="encrypted_${ENCRYPTION_LABEL}_iv"
eval encrypted_key=\$${encrypted_key_var}
eval encrypted_iv=\$${encrypted_iv_var}
openssl aes-256-cbc -K ${encrypted_key} -iv ${encrypted_iv} -in ${deploy_key} -out deploy-key -d
chmod 600 deploy-key
eval "$(ssh-agent -s)"
ssh-add deploy-key


mvn javadoc:javadoc

git clone ${javadoc_repo} javadoc

group_dir=$(echo ${group_id} | sed 's/\./\//g')
mkdir -p javadoc/${group_dir}/${artifact_id}
rm -rf javadoc/${group_dir}/${artifact_id}/${version}
cp -r target/site/apidocs javadoc/${group_dir}/${artifact_id}/${version}

(
  cd javadoc

  # ディレクトリ列挙用 HTML をつくる
  dir=${group_dir}/${artifact_id}
  while true; do
    echo ${dir}
    (
      cd ${dir}
      echo '<html><body><ul>' > index.html
      for i in $(find . -mindepth 1 -maxdepth 1 -name ".*" -prune -o -type d -printf '%f\n' | sort -V); do
        echo '<li><a href="'${i}'">'${i}'</a></li>' >> index.html
      done
      echo '</html></body></ul>' >> index.html
    )

    if [ ${dir} = . ]; then
      break
    fi

    dir=$(dirname ${dir})
  done

  git config user.name rg-ci
  git config user.email ci@realglobe.jp
  git add -A
  if ! git commit -m "Add javadoc (${group_id}:${artifact_id}:${version})"; then
    echo 'no changes'
    exit
  fi

  ssh_repo=$(echo ${javadoc_repo} | sed 's/https:\/\/github.com\//git@github.com:/')
  git push ${ssh_repo} master
)
