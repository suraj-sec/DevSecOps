# safety

## github

Let’s create PAT by visiting https://github.com/settings/tokens, clicking Generate new token (classic) button then selecting repo and workflow in the scopes.
Provide your token a name e.g. django and save it in Machine to login. 
```
git config --global user.email "your_email@gmail.com"
git config --global user.name "your_username"
git clone https://gitlab.practical-devsecops.training/pdso/django.nv.git
cd django.nv
git remote rename origin old-origin
git remote add origin https://github.com/username/django.nv.git
git status
git push -u origin --all
mkdir -p .github/workflows # add following file and commit changes
git add .github/workflows/main.yaml
git commit -m "Add github workflows"
git push origin main
```

```
cat >.github/workflows/main.yaml<<EOF
name: Django                                  # workflow name

on:
  push:                                       
    branches:                                 # similar to "only" in GitLab
      - main

jobs:
  build:
    runs-on: ubuntu-20.04                    # similar to "image" in GitLab
    steps:
      - uses: actions/checkout@v2

      - name: Setup python
        uses: actions/setup-python@v2
        with:
          python-version: '3.6'

      - run: |
          pip3 install --upgrade virtualenv
          virtualenv env
          source env/bin/activate
          pip install -r requirements.txt
          python manage.py check

  test:
    runs-on: ubuntu-20.04
    needs: build
    steps:
      - uses: actions/checkout@v2

      - name: Setup python
        uses: actions/setup-python@v2
        with:
          python-version: '3.6'

      - run: |
          pip3 install --upgrade virtualenv
          virtualenv env
          source env/bin/activate
          pip install -r requirements.txt
          python manage.py test taskManager

  integration:
    runs-on: ubuntu-20.04
    needs: test
    steps:
      - run: echo "This is an integration step"
      - run: exit 1
        continue-on-error: true

  prod:
    runs-on: ubuntu-20.04
    needs: integration
    steps:
      - run: echo "This is a deploy step."
EOF
```

# retire.js - https://github.com/retirejs/retire.js

# dependency-check

create a new file called run-depcheck.sh with the following contents in repo.


# snyk
Add another job name oast-snyk under the build stage with the Snyk tool
Sign up for the Snyk’s Free service and generate/copy the token
Store Snyk token in Variables via Project –> Settings –> CI/CD –> Variables https://gitlab-ce-lq84iw0v.lab.practical-devsecops.training/root/django-nv/-/settings/ci_cd
Create a new variable SNYK_TOKEN and put the token you got from the service, and ensure the protected flag is turned on
Use Snyk’s Linux binary to scan the dependencies in the project

# composer

```
composer-job:       
  stage: build
  image: php:7.4
  script:
    - apt update && apt install -y git
    - php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    - php composer-setup.php
    - mv composer.phar /usr/local/bin/composer
    - composer install
    - composer audit --format json | tee composer-audit.json
  artifacts:
    paths: [composer-audit.json]
    when: always
  allow_failure: true
```


# dependabot

Provide the token name as renovatebot, select the following checkboxes:
api
read_api
read_repository
write_repository

We need to add the GitLab Personal Access Token variable (Go to Project (django.nv) → Settings → CI/CD → Variables → Expand).
Click on the Add Variable button and you’ll be directed to the variable input box.
Then populate the SETTINGS__GITLAB_ACCESS_TOKEN field with the previously generated Personal Access Token value.
Ensure the Protect Variable box is unchecked for a more adaptable pipeline, then click add variable.

```
mkdir /django-nv/.gitlab

cat > /django-nv/.gitlab/dependabot.yml <<EOF
version: 2
updates:
  - package-ecosystem: npm
    directory: /
EOF

git add .gitlab/

git commit -m "add dependabot configuration file"

git push origin main

```

# trivy

```
trivy:
  stage: build
  image: ubuntu:latest
  before_script:
    - apt-get update && apt-get upgrade
    - apt-get install wget apt-transport-https gnupg lsb-release -y
    - wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | apt-key add -
    - echo deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main | tee -a /etc/apt/sources.list.d/trivy.list
    - apt-get update
    - apt-get install trivy
  script:
    -  trivy fs . --scanners vuln -f json | tee trivy-output.json
  artifacts:
    paths: [trivy-output.json]
    when: always
  allow_failure: true
```

# extra

```
image: docker:20.10

services:
  - docker:dind

stages:
  - build

.npm:
  stage: build
  image:
    name: docker.io/andrcuns/dependabot-gitlab:0.11.0
    entrypoint: [""]
  variables:
    GIT_STRATEGY: none
    PACKAGE_MANAGER: npm
    RAILS_ENV: production
    SETTINGS__GITLAB_URL: $CI_SERVER_URL
    SETTINGS__STANDALONE: "true"
  before_script:
    - cd /home/dependabot/app
  script:
    - bundle exec rake "dependabot:update[$CI_PROJECT_NAMESPACE/$CI_PROJECT_NAME,$PACKAGE_MANAGER,/]"

dependabot:
  extends: .npm
  when: manual

osv_scanner_js:
  stage: build
  script:
    - docker run -v ${PWD}:/src node:22-alpine3.19 npm --prefix /src install /src
    - docker run -v ${PWD}:/src ghcr.io/google/osv-scanner --format json /src > scan-results.json
  artifacts:
    paths: [scan-results.json]
    when: always
  allow_failure: true
```
