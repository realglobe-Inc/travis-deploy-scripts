#!/bin/sh -e

# Maven プロジェクト生成した Javadoc を GitHub Pages にデプロイする。

# pom.xml のあるディレクトリで実行する。事前に以下の準備が必要。
# 1. デプロイ用の鍵ペアを用意する。
# 2. 公開鍵を Github の Javadoc 用プロジェクト（デプロイ先）の Deploy Keys に登録する。
# 3. 秘密鍵をデプロイ元プロジェクトディレクトリで travis encrypt-file して追加する。
# 4. Travis CI のデプロイ元プロジェクトの環境変数に ENCRYPTION_LABEL を追加する。

# 既に同一バージョンの Javadoc がデプロイされている場合はデプロイしない。
# ただし、環境変数 FORCE_DEPLOY が空でない場合は上書きデプロイする。

# target/site/apidocs に Javadoc を生成しておくこと。


javadoc_repo=${JAVADOC_REPO:=https://github.com/realglobe-Inc/javadoc.git}
deploy_key=${DEPLOY_KEY:=javadoc-deploy-key.enc}
work_dir=${WORK_DIR:=.deploy-workspace}
deployer_name=${DEPLOYER_NAME:=rg-ci}
deployer_email=${DEPLOYER_EMAIL:=ci@realglobe.jp}


if ! [ -f pom.xml ]; then
  echo 'no pom.xml' 1>&2
  exit 1
elif ! [ -d target/site/apidocs ]; then
  echo "no javadoc direcotry (target/site/apidocs)" 1>&2
  exit 1
elif ! [ -f ${deploy_key} ]; then
  echo "no ${deploy_key}" 1>&2
  exit 1
elif [ -z "${ENCRYPTION_LABEL}" ]; then
  echo 'no environment variable ENCRYPTION_LABEL' 1>&2
  exit 1
fi

group_id=$(xmllint --xpath '/*[local-name()="project"]/*[local-name()="groupId"]/text()' pom.xml)
artifact_id=$(xmllint --xpath '/*[local-name()="project"]/*[local-name()="artifactId"]/text()' pom.xml)
version=$(xmllint --xpath '/*[local-name()="project"]/*[local-name()="version"]/text()' pom.xml)

mkdir -p ${work_dir}

# デプロイ用の ssh 鍵を準備する
encrypted_key_var="encrypted_${ENCRYPTION_LABEL}_key"
encrypted_iv_var="encrypted_${ENCRYPTION_LABEL}_iv"
eval encrypted_key=\$${encrypted_key_var}
eval encrypted_iv=\$${encrypted_iv_var}
openssl aes-256-cbc -K ${encrypted_key} -iv ${encrypted_iv} -in ${deploy_key} -out ${work_dir}/deploy-key -d
chmod 600 ${work_dir}/deploy-key
eval "$(ssh-agent -s)"
ssh-add ${work_dir}/deploy-key


javadoc_root_dir=${work_dir}/javadoc

git clone ${javadoc_repo} ${javadoc_root_dir}

group_dir=$(echo ${group_id} | sed 's/\./\//g')
javadoc_dir=${javadoc_root_dir}/${group_dir}/${artifact_id}/${version}

if [ -e ${javadoc_dir} ]; then
  if [ -n "${FORCE_DEPLOY}" ]; then
    rm -rf ${javadoc_dir}
  else
    echo "already exists"
    exit
  fi
fi


mkdir -p $(dirname ${javadoc_dir})
cp -r target/site/apidocs ${javadoc_dir}

(
  cd ${javadoc_root_dir}

  # ディレクトリ列挙用 HTML をつくる
  dir=${group_dir}/${artifact_id}
  while true; do
    (
      cd ${dir}
      echo '<html><body><ul>' > index.html
      if [ ${dir} != . ]; then
        echo '<li><a href="..">..</a></li>' >> index.html
      fi
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

  git config user.name ${deployer_name}
  git config user.email ${deployer_email}
  git add -A
  if ! git commit -m "Add javadoc (${group_id}:${artifact_id}:${version})"; then
    echo 'no changes'
    exit
  fi

  ssh_repo=$(echo ${javadoc_repo} | sed 's/https:\/\/github.com\//git@github.com:/')
  git push ${ssh_repo} master
)
