Task 1
Implement SCA, SAST, DAST for the django.nv project
As per the best practices, we need to test DevSecOps tools locally before embedding them into CI/CD pipeline.
So lets go ahead and test them out.

Software Component Analysis (SCA)
ProTip: Please remember to run the tool locally before embedding it into the CI/CD pipeline.

Before running the scan, let’s clone our source code from the GitLab server.

```
git clone http://gitlab-ce-lq84iw0v.lab.practical-devsecops.training/root/django-nv.git webapp
cd webapp
```

Lets run the command locally on the DevSecOps Box to test if all commands are working properly.

For front-end:

```
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
NODE_MAJOR=20
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
apt update
```

`apt install nodejs -y`

`npm install -g retire # Install retirejs npm package`

`retire --outputformat json --outputpath retirejs-report.json --severity high`


For backend:

`docker run --rm -v $(pwd):/src hysnsec/safety check -r requirements.txt --json > oast-results.json`

Static Application Security Testing (SAST)
For secrets scanning:

`docker run --rm -v $(pwd):/src hysnsec/trufflehog filesystem /src --json | tee trufflehog-output.json`

For static analysis:

`docker run --user $(id -u):$(id -g) --rm -v $(pwd):/src hysnsec/bandit -r /src -f json -o /src/bandit-output.json`

Dynamic Application Security Testing (DAST)
For SSL Scan:

`docker run --rm -v $(pwd):/tmp hysnsec/sslyze prod-lq84iw0v.lab.practical-devsecops.training:443 --json_out /tmp/sslyze-output.json`

For Nmap:

`docker run --rm -v $(pwd):/tmp hysnsec/nmap prod-lq84iw0v -oX /tmp/nmap-output.xml`

For Dynamic analysis:

`docker run --user $(id -u):$(id -g) -w /zap -v $(pwd):/zap/wrk:rw --rm softwaresecurityproject/zap-stable:2.13.0 zap-baseline.py -t https://prod-lq84iw0v.lab.practical-devsecops.training -J zap-output.json`

Task 2
Please embed these tests in CI/CD pipeline
Considering your DevOps team created a simple CI pipeline with the following contents.

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
We will try to do these challenges step by step as mentioned in the courseware. SCA, SAST and then DAST.

Software Component Analysis (SCA)
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
Note

If you are wondering why the sca-frontend job does not use Docker commands like other jobs, it’s because we need to install the component before the scan, and it’s easier to use npm directly instead of Docker commands, which might be a bit complex.

Static Application Security Testing (SAST)

# Git Secrets Scanning
secrets-scanning:
  stage: build
  script:
    - apk add git
    - git checkout main
    - docker run --rm -v $(pwd):/src hysnsec/trufflehog filesystem /src --json | tee trufflehog-output.json
  artifacts:
    paths: [trufflehog-output.json]
    when: always # What is this for?
    expire_in: one week
  allow_failure: true   #<--- allow the build to fail but don't mark it as such

# Static Application Security Testing
sast:
  stage: build
  script:
    - docker pull hysnsec/bandit  # Download bandit docker container
    # Run docker container, please refer docker security course, if this doesn't make sense to you.
    - docker run --user $(id -u):$(id -g) --rm -v $(pwd):/src hysnsec/bandit -r /src -f json -o /src/bandit-output.json
  artifacts:
    paths: [bandit-output.json]
    when: always
  allow_failure: true   #<--- allow the build to fail but don't mark it as such
Dynamic Application Security Testing (DAST)

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
    - docker run --user $(id -u):$(id -g) -w /zap -v $(pwd):/zap/wrk:rw --rm softwaresecurityproject/zap-stable:2.13.0 zap-baseline.py -t https://prod-lq84iw0v.lab.practical-devsecops.training -J zap-output.json
  after_script:
    - docker rmi softwaresecurityproject/zap-stable:2.13.0  # clean up the image to save the disk space
  artifacts:
    paths: [zap-output.json]
    when: always # What does this do?
  allow_failure: true

```
Let’s combine the SCA, SAST and DAST steps into a Gitlab CI script.

We will login into the GitLab using the following details and execute this pipeline.

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

Verify the pipeline run

Task 3
Ensure all the best practices covered in the course videos, labs and mattermost discussion are being implemented

We tried to implement all the best practices we have learned in the course
1. Tested the tools locally before embedding in the pipeline
2. Ensured the scans finish within 10 minutes
3. Ensured they each run in their own jobs
4. We saved the output in a file
5. We didn’t fail the builds

There’s more to the best practices, we leave it to you, to implement and suggest the remaining best practices.


Task 1
Harden the production machine
As per the best practices, we need to test DevSecOps tools locally before embedding them into CI/CD pipeline.
So lets go ahead and test them out.

IaC
We need the inventory.ini first, so lets create one
```
cat > inventory.ini <<EOL
# DevSecOps Studio Inventory
[prod]
prod-lq84iw0v

EOL
```

Let’s download the role
`ansible-galaxy install dev-sec.os-hardening`

Next, let’s create a playbook
```
cat > ansible-hardening.yml <<EOL
---
- name: Playbook to harden Ubuntu OS.
  hosts: prod
  remote_user: root
  become: yes

  roles:
    - dev-sec.os-hardening

EOL
```

Let’s run the pipeline now.

`ansible-playbook -i inventory.ini ansible-hardening.yml`

Task 2
Ensure it stays compliant with linux-baseline Inspec Profile

We can verify if the machine stays hardened using Inspec.
`docker run --rm -v ~/.ssh:/root/.ssh -v $(pwd):/share hysnsec/inspec exec https://github.com/dev-sec/linux-baseline.git -t ssh://root@$DEPLOYMENT_SERVER -i /root/.ssh/id_rsa --chef-license accept --reporter json:/share/inspec-output.json`

Note

/share directory should be used when using hysnsec/inspec image. Because it’s a custom image adding another directory would not work when you are saving the inspec output.

If there are any discrepancies in the results, we need to explore and fix them.

Task 3
Embed these tests as part of CI/CD pipeline

Infrastructure as Code (IaC)
```
# Infrastructure as Code
# PLEASE ENSURE YOU HAVE SETUP THE ENVIRONMENT VARIABLES APPROPRIATELY
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
Compliance as Code (CaC)


# Compliance as Code
# PLEASE ENSURE YOU HAVE SETUP THE ENVIRONMENT VARIABLES APPROPRIATELY
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
    - docker run --rm -v ~/.ssh:/root/.ssh -v $(pwd):/share hysnsec/inspec exec https://github.com/dev-sec/linux-baseline.git -t ssh://root@$DEPLOYMENT_SERVER -i /root/.ssh/id_rsa --chef-license accept --reporter json:/share/inspec-output.json
  artifacts:
    paths: [inspec-output.json]
    when: always

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
