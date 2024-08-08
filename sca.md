# safety

```
image: docker:20.10  # To run all jobs in this pipeline, use the latest docker image

services:
  - docker:dind       # To run all jobs in this pipeline, use a docker image that contains a docker daemon running inside (dind - docker in docker). Reference: https://forum.gitlab.com/t/why-services-docker-dind-is-needed-while-already-having-image-docker/43534

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
   - virtualenv env                       # Create a virtual environment for the python application
   - source env/bin/activate              # Activate the virtual environment
   - pip install -r requirements.txt      # Install the required third party packages as defined in requirements.txt
   - python manage.py check               # Run checks to ensure the application is working fine

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

oast:
  stage: test
  script:
    # We are going to pull the hysnsec/safety image to run the safety scanner
    - docker pull hysnsec/safety
    # third party components are stored in requirements.txt for python, so we will scan this particular file with safety.
    - docker run --rm -v $(pwd):/src hysnsec/safety check -r requirements.txt --json > oast-results.json
  artifacts:
    paths: [oast-results.json]
    when: always # What does this do?
  allow_failure: true

integration:
  stage: integration
  script:
    - echo "This is an integration step"
    - exit 1
  allow_failure: true # Even if the job fails, continue to the next stages

prod:
  stage: prod
  script:
    - echo "This is a deploy step."
  when: manual # Continuous Delivery
```

## jenkins

```
pipeline {
    agent any

    options {
        gitLabConnection('gitlab')
    }

    stages {
        stage("build") {
            agent { 
                docker { 
                    image 'python:3.6'
                    args '-u root'
                }
            }
            steps {
                sh """
                pip3 install --user virtualenv
                python3 -m virtualenv env
                . env/bin/activate
                pip3 install -r requirements.txt
                python3 manage.py check
                """
            }
        }
        stage("test") {
            agent { 
                docker { 
                    image 'python:3.6'
                    args '-u root'
                }
            }
            steps {
                sh """
                pip3 install --user virtualenv
                python3 -m virtualenv env
                . env/bin/activate
                pip3 install -r requirements.txt
                python3 manage.py test taskManager
                """
            }
        }
        stage("oast") {
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') { 
                    sh "docker run -v \$(pwd):/src --rm hysnsec/safety check -r requirements.txt --json | tee oast-results.json"
                }
            }
        }
        stage("integration") {
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                    echo "This is an integration step."
                    sh "exit 1"
                }
            }
        }
        stage("prod") {
            steps {
                timeout(time: 10, unit: 'SECONDS') {
                    input "Deploy to production?"
                }
                echo "This is a deploy step."
            }
        }
    }
    post {
        failure {
            updateGitlabCommitStatus(name: STAGE_NAME, state: 'failed')
        }
        unstable {
            updateGitlabCommitStatus(name: STAGE_NAME, state: 'failed')
        }
        success {
            updateGitlabCommitStatus(name: STAGE_NAME, state: 'success')
        }
        aborted {
            updateGitlabCommitStatus(name: STAGE_NAME, state: 'skipped')
        }
        always { 
            archiveArtifacts artifacts: '*.json', fingerprint: true
            deleteDir()                     // clean up workspace
        }
    }
}
```

## github

```
name: Django                                  # workflow name

on:
  push:
    branches:                                 # similar to "only" in GitLab
      - main

jobs:
  build:
    runs-on: ubuntu-20.04   # similar to "image" in GitLab
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

  oast:
    runs-on: ubuntu-20.04
    needs: test
    steps:
      - uses: actions/checkout@v2

      - run: docker run --rm -v $(pwd):/src hysnsec/safety check -r requirements.txt --json > oast-results.json
        continue-on-error: true             # allow the build to fail, similar to "allow_failure: true" in GitLab

      - uses: actions/upload-artifact@v2
        with:
          name: Safety
          path: oast-results.json
        if: always()                        # what is this for?

  integration:
    runs-on: ubuntu-20.04
    needs: oast
    steps:
      - run: echo "This is an integration step"
      - run: exit 1
        continue-on-error: true

  prod:
    runs-on: ubuntu-20.04
    needs: integration
    steps:
      - run: echo "This is a deploy step."
```

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

```
oast-frontend:
  stage: test
  image: node:alpine3.10
  script:
    - npm install
    - npm install -g retire # Install retirejs npm package.
    - retire --outputformat json --outputpath retirejs-report.json --severity high
  artifacts:
    paths: [retirejs-report.json]
    when: always 
    expire_in: one week
  allow_failure: true
```

## jenkins

```
pipeline {
    agent any

    options {
        gitLabConnection('gitlab')
    }

    stages {
        stage("build") {
            agent {
                docker {
                    image 'python:3.6'
                    args '-u root'
                }
            }
            steps {
                sh """
                pip3 install --user virtualenv
                python3 -m virtualenv env
                . env/bin/activate
                pip3 install -r requirements.txt
                python3 manage.py check
                """
            }
        }
        stage("test") {
            agent {
                docker {
                    image 'python:3.6'
                    args '-u root'
                }
            }
            steps {
                sh """
                pip3 install --user virtualenv
                python3 -m virtualenv env
                . env/bin/activate
                pip3 install -r requirements.txt
                python3 manage.py test taskManager
                """
            }
        }
        stage("oast-frontend") {
            agent {
                docker {
                    image 'node:alpine3.10'
                    args '-u root'
                }
            }
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                    sh """
                    npm install
                    npm install -g retire
                    retire --outputformat json --outputpath retirejs-report.json --severity high
                    """
                }
            }
        }
        stage("integration") {
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                    echo "This is an integration step."
                    sh "exit 1"
                }
            }
        }
        stage("prod") {
            steps {
                timeout(time: 10, unit: 'SECONDS') {
                    input "Deploy to production?"
                }
                echo "This is a deploy step."
            }
        }
    }
    post {
        failure {
            updateGitlabCommitStatus(name: STAGE_NAME, state: 'failed')
        }
        unstable {
            updateGitlabCommitStatus(name: STAGE_NAME, state: 'failed')
        }
        success {
            updateGitlabCommitStatus(name: STAGE_NAME, state: 'success')
        }
        aborted {
            updateGitlabCommitStatus(name: STAGE_NAME, state: 'skipped')
        }
        always {
            archiveArtifacts artifacts: '*.json', fingerprint: true
            deleteDir()                     // clean up workspace
        }
    }
}

```
## github

```
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

  oast-frontend:
    runs-on: ubuntu-20.04
    needs: test
    steps:
      - uses: actions/checkout@v2

      - uses: actions/setup-node@v2
        with:
          node-version: '10.x'

      - run: npm install

      - run: docker run --rm -v $(pwd):/src -w /src hysnsec/retire --outputformat json --outputpath retirejs-report.json --severity high
        continue-on-error: true

      - uses: actions/upload-artifact@v2
        with:
          name: RetireJS
          path: retirejs-report.json
        if: always()                        # what is this for?

  integration:
    runs-on: ubuntu-20.04
    needs: oast-frontend
    steps:
      - run: echo "This is an integration step"
      - run: exit 1
        continue-on-error: true

  prod:
    runs-on: ubuntu-20.04
    needs: integration
    steps:
      - run: echo "This is a deploy step."
```

# dependency-check

create a new file called run-depcheck.sh with the following contents in repo.

```
#!/bin/sh

DATA_DIRECTORY="$PWD/data"
REPORT_DIRECTORY="$PWD/reports"

if [ ! -d "$DATA_DIRECTORY" ]; then
  echo "Initially creating persistent directories"
  mkdir -p "$DATA_DIRECTORY"
  chmod -R 777 "$DATA_DIRECTORY"

  mkdir -p "$REPORT_DIRECTORY"
  chmod -R 777 "$REPORT_DIRECTORY"
fi

docker run --rm \
  --volume $(pwd):/src \
  --volume "$DATA_DIRECTORY":/usr/share/dependency-check/data \
  --volume "$REPORT_DIRECTORY":/reports \
  hysnsec/dependency-check \
  --scan /src \
  --format "JSON" \
  --project "Webgoat" \
  --failOnCVSS 4 \
  --out /reports
```

update .gitlab-ci.yml file with following content:

```
image: docker:20.10  # To run all jobs in this pipeline, use the latest docker image

services:
  - docker:dind       # To run all jobs in this pipeline, use a docker image that contains a docker daemon running inside (dind - docker in docker). Reference: https://forum.gitlab.com/t/why-services-docker-dind-is-needed-while-already-having-image-docker/43534

stages:
  - build
  - test
  - release
  - preprod
  - integration
  - prod

build:
  stage: build
  script:
    - echo "This is a build step"

test:
  stage: test
  script:
    - echo "This is a test step"

odc-backend:
  stage: test
  image: gitlab/dind:latest
  script:
    - chmod +x ./run-depcheck.sh
    - ./run-depcheck.sh
  artifacts:
    paths:
      - reports/dependency-check-report.json
    when: always
    expire_in: one week
  allow_failure: true

integration:
  stage: integration
  script:
    - echo "This is an integration step"
    - exit 1
  allow_failure: true # Even if the job fails, continue to the next stages

prod:
  stage: prod
  script:
    - echo "This is a deploy step."
  when: manual # Continuous Delivery
```
## jenkins

```
pipeline {
    agent any

    options {
        gitLabConnection('gitlab')
    }

    stages {
        stage("build") {
            steps {
                echo "This is a build step"
            }
        }
        stage("test") {
            steps {
                echo "This is a test step"
            }
        }
        stage("odc-backend") {
            agent {
                docker { 
                    image 'docker:20.10-dind'
                    args '-u root -v /var/run/docker.sock:/var/run/docker.sock'
                }
            }
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                sh """
                chmod +x run-depcheck.sh
                ./run-depcheck.sh
                """
            }
            post {
                always {
                    archiveArtifacts artifacts: 'reports/dependency-check-report.json', onlyIfSuccessful: false
                    }
                }
            }
        }
        stage("integration") {
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                    echo "This is an integration step."
                    sh "exit 1"
                }
            }
        }
        stage("prod") {
            steps {
                timeout(time: 10, unit: 'SECONDS') {
                    input "Deploy to production?"
                }
                echo "This is a deploy step."
            }
        }
    }
    post {
        failure {
            updateGitlabCommitStatus name: STAGE_NAME, state: 'failed'
        }
        unstable {
            updateGitlabCommitStatus name: STAGE_NAME, state: 'failed'
        }
        success {
            updateGitlabCommitStatus name: STAGE_NAME, state: 'success'
        }
        always {
            archiveArtifacts artifacts: '*.json', fingerprint: true
            deleteDir()                     // clean up workspace
            dir("${WORKSPACE}@tmp") {       // clean up tmp directory
                deleteDir()
            }
            dir("${WORKSPACE}@script") {    // clean up script directory
                deleteDir()
            }
        }
    }
}
```

### github

```
  odc-backend:
    runs-on: ubuntu-20.04
    name: depecheck_test
    steps:
      - name: Checkout
        uses: actions/checkout@v2

      - name: Depcheck
        uses: dependency-check/Dependency-Check_Action@main
        id: Depcheck
        with:
          project: 'webgoat'
          path: '.'
          format: 'JSON'

      - name: Upload Test results
        uses: actions/upload-artifact@master
        with:
           name: Depcheck report
           path: ${{github.workspace}}/reports
```

# snyk
Add another job name oast-snyk under the build stage with the Snyk tool
Sign up for the Snyk’s Free service and generate/copy the token
Store Snyk token in Variables via Project –> Settings –> CI/CD –> Variables https://gitlab-ce-lq84iw0v.lab.practical-devsecops.training/root/django-nv/-/settings/ci_cd
Create a new variable SNYK_TOKEN and put the token you got from the service, and ensure the protected flag is turned on
Use Snyk’s Linux binary to scan the dependencies in the project

```
oast-snyk:
  stage: build
  image: node:alpine3.10
  before_script:
    - wget -O snyk https://github.com/snyk/cli/releases/download/v1.1156.0/snyk-alpine
    - chmod +x snyk
    - mv snyk /usr/local/bin/
  script:
    - npm install
    - snyk auth $SNYK_TOKEN
    - snyk test --json > snyk-results.json
    - cat snyk-results.json
  artifacts:
    paths:
      - snyk-results.json
    when: always
  allow_failure: true
```

# audit-js

```
image: node:alpine3.10

cache:
  paths:
  - node_modules/

stages:
  - build
  - test
  - release
  - preprod
  - integration
  - prod

build:
  stage: build
  script:
    - npm install

test:
  stage: test
  script:
    - echo "This is an test step"

auditjs:
  stage: test
  script:
    - docker run --rm -v $(pwd):/src -w /src hysnsec/auditjs ossi -q -j | tee auditjs-output.json
  artifacts:
    paths: [auditjs-output.json]
    when: always # What is this for?
    expire_in: one week
  allow_failure: true  #<--- allow the build to fail but don't mark it as such

integration:
  stage: integration
  script:
    - echo "This is an integration step"

prod:
  stage: prod
  script:
    - echo "This is a deploy step"
```
