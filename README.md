# travis-deploy-scripts

Travis CI からデプロイするときに役立つスクリプト集。

例えば、以下のように .travis.yml から使う。

```yaml
deploy:
  provider: script
  script:
    - curl -s https://raw.githubusercontent.com/realglobe-Inc/travis-deploy-scripts/master/SCRIPT | sh
```
