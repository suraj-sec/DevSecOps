### install inspec

```
wget https://packages.chef.io/files/stable/inspec/5.22.29/ubuntu/18.04/inspec_5.22.29-1_amd64.deb
dpkg -i inspec_5.22.29-1_amd64.deb
```
or

```
curl https://omnitruck.chef.io/install.sh | sudo bash -s -- -v 5.22.29 -P inspec
```

### running inspec



```
echo "StrictHostKeyChecking accept-new" >> ~/.ssh/config #prevents the ssh agent from prompting YES or NO question
inspec exec https://github.com/dev-sec/linux-baseline.git -t ssh://root@prod-lq84iw0v -i ~/.ssh/id_rsa --chef-license accept
```

The first parameter tells the Inspec profile that we need to run against the server
-t tells the target machine
-i flag used to specify the ssh-key since we are using login in via ssh
--chef-license accept tells that we are accepting license this commands prevent the inspec from prompting YES or NO question

### pipeline

using binary

```
image: docker:20.10

services:
  - docker:dind

stages:
  - build
  - test
  - release
  - preprod
  - integration
  - prod

inspec:
  stage: prod
  image: ubuntu:latest
  before_script:
    - apt-get update && apt-get upgrade -y && apt-get install -y openssh-client wget git
    - mkdir -p ~/.ssh
    - echo "$DEPLOYMENT_SERVER_SSH_PRIVKEY" | tr -d '\r' > ~/.ssh/id_rsa
    - chmod 600 ~/.ssh/id_rsa
    - eval "$(ssh-agent -s)"
    - ssh-add ~/.ssh/id_rsa
    - ssh-keyscan -t rsa $DEPLOYMENT_SERVER >> ~/.ssh/known_hosts
  script:
    - wget https://packages.chef.io/files/stable/inspec/5.22.29/ubuntu/18.04/inspec_5.22.29-1_amd64.deb
    - dpkg -i inspec_5.22.29-1_amd64.deb
    - echo "StrictHostKeyChecking accept-new" >> ~/.ssh/config
    - inspec exec https://github.com/dev-sec/linux-baseline.git -t ssh://root@$DEPLOYMENT_SERVER -i ~/.ssh/id_rsa --chef-license accept --reporter json:inspec-output.json
  artifacts:
    paths: [inspec-output.json]
    when: always
  allow_failure: true
```

### using docker
```

inspec:
  stage: prod
  only:
    - main
  before_script:
    - mkdir -p ~/.ssh
    - echo "$DEPLOYMENT_SERVER_SSH_PRIVKEY" | tr -d '\r' > ~/.ssh/id_rsa
    - chmod 600 ~/.ssh/id_rsa
    - eval "$(ssh-agent -s)"
    - ssh-add ~/.ssh/id_rsa
    - ssh-keyscan -t rsa $DEPLOYMENT_SERVER >> ~/.ssh/known_hosts
  script:
    - docker run --rm -v ~/.ssh:/root/.ssh -v $(pwd):/share hysnsec/inspec exec https://github.com/dev-sec/linux-baseline.git -t ssh://root@$DEPLOYMENT_SERVER -i ~/.ssh/id_rsa --chef-license accept --reporter json:inspec-output.json
  artifacts:
    paths: [inspec-output.json]
    when: always
  allow_failure: true
```
