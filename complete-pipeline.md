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

build:
  stage: build
  image: python:3.6
  before_script:
   - pip3 install --upgrade virtualenv
  script:
   - virtualenv env
   - source env/bin/activate
   - pip install -r requirements.txt
   - python manage.py check

test:
  stage: test
  image: python:3.6
  before_script:
   - pip3 install --upgrade virtualenv
  script:
   - virtualenv env
   - source env/bin/activate
   - pip install -r requirements.txt
   - python manage.py test taskManager

# Software Component Analysis
sca-frontend:
  stage: build
  image: node:alpine3.10
  script:
    - npm install
    - npm install -g retire # Install retirejs npm package.
    - retire --outputformat json --outputpath retirejs-report.json --severity high
  artifacts:
    paths: [retirejs-report.json]
    when: always # What is this for?
    expire_in: one week
  allow_failure: true #<--- allow the build to fail but don't mark it as such

sca-backend:
  stage: build
  script:
    - docker pull hysnsec/safety
    - docker run --rm -v $(pwd):/src hysnsec/safety check -r requirements.txt --json > oast-results.json
  artifacts:
    paths: [oast-results.json]
    when: always # What does this do?
  allow_failure: true #<--- allow the build to fail but don't mark it as such

# Git Secrets Scanning
secrets-scanning:
  stage: build
  script:
    - docker run -v $(pwd):/src --rm hysnsec/trufflehog filesystem /src --json | tee trufflehog-output.json
  artifacts:
    paths: [trufflehog-output.json]
    when: always  # What is this for?
    expire_in: one week
  allow_failure: true

# Static Application Security Testing
sast:
  stage: build
  script:
    - docker pull hysnsec/bandit  # Download bandit docker container
    # Run docker container, please refer docker security course, if this doesn't make sense to you.
    - docker run --user $(id -u):$(id -g) -v $(pwd):/src --rm hysnsec/bandit -r /src -f json -o /src/bandit-output.json
  artifacts:
    paths: [bandit-output.json]
    when: always
  allow_failure: true   #<--- allow the build to fail but don't mark it as such

# Dynamic Application Security Testing
nikto:
  stage: integration
  script:
    - docker pull hysnsec/nikto
    - docker run --rm -v $(pwd):/tmp hysnsec/nikto -h prod-lq84iw0v -o /tmp/nikto-output.xml
  artifacts:
    paths: [nikto-output.xml]
    when: always

sslscan:
  stage: integration
  script:
    - docker pull hysnsec/sslyze
    - docker run --rm -v $(pwd):/tmp hysnsec/sslyze prod-lq84iw0v.lab.practical-devsecops.training:443 --json_out /tmp/sslyze-output.json
  artifacts:
    paths: [sslyze-output.json]
    when: always

nmap:
  stage: integration
  script:
    - docker pull hysnsec/nmap
    - docker run --rm -v $(pwd):/tmp hysnsec/nmap prod-lq84iw0v -oX /tmp/nmap-output.xml
  artifacts:
    paths: [nmap-output.xml]
    when: always

zap-baseline:
  stage: integration
  script:
    - docker pull softwaresecurityproject/zap-stable:2.13.0
    - docker run --user $(id -u):$(id -g) --rm -v $(pwd):/zap/wrk:rw softwaresecurityproject/zap-stable:2.13.0 zap-baseline.py -t https://prod-lq84iw0v.lab.practical-devsecops.training -J zap-output.json
  after_script:
    - docker rmi softwaresecurityproject/zap-stable:2.13.0  # clean up the image to save the disk space
  artifacts:
    paths: [zap-output.json]
    when: always # What does this do?
  allow_failure: true
```

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

# Infrastructure as Code
ansible-hardening:
  stage: prod
  image: willhallonline/ansible:2.9-ubuntu-18.04
  before_script:
    - mkdir -p ~/.ssh
    - echo "$DEPLOYMENT_SERVER_SSH_PRIVKEY" | tr -d '\r' > ~/.ssh/id_rsa
    - chmod 600 ~/.ssh/id_rsa
    - eval "$(ssh-agent -s)"
    - ssh-add ~/.ssh/id_rsa
    - ssh-keyscan -t rsa $DEPLOYMENT_SERVER >> ~/.ssh/known_hosts
  script:
    - echo -e "[prod]\n$DEPLOYMENT_SERVER" >> inventory.ini
    - ansible-galaxy install dev-sec.os-hardening
    - ansible-playbook -i inventory.ini ansible-hardening.yml

# Compliance as Code
inspec:
  stage: prod
  only:
    - "main"
  environment: production
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
```
```
