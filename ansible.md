```
pip3 install ansible==8.7.0 ansible-lint==6.8.1
```

### creating inventory file

```
cat > inventory.ini <<EOL

# DevSecOps Studio Inventory
[devsecops]
devsecops-box-lq84iw0v

[prod]
prod-lq84iw0v

EOL
```


###  using ssh-keyscan to capture the key signatures beforehand

```
ssh-keyscan -t rsa prod-lq84iw0v >> ~/.ssh/known_hosts
ssh-keyscan -t rsa devsecops-box-lq84iw0v >> ~/.ssh/known_hosts
```
or
```
ssh-keyscan -t rsa prod-lq84iw0v devsecops-box-lq84iw0v >> ~/.ssh/known_hosts
```

### run ansible ad-hoc commands

```
ansible -i inventory.ini prod --list-hosts #to list hosts in inventory file in prod group
ansible -i inventory.ini all -m ping
ansible -i inventory.ini all -m shell -a "hostname"
ansible -i inventory.ini all -m apt -a "name=ntp"
ansible -i inventory.ini  prod -m apt -a "name=ntp state=present"
ansible -i inventory.ini all -m command -a "bash --version"
ansible -i inventory.ini prod -m shell -a "uptime"

ansible -i inventory.ini all -m copy -a "src=/root/notes dest=/root" #copy file
```

### create playbook

```
cat > playbook.yml <<EOL
---
- name: Example playbook to install firewalld
  hosts: prod
  remote_user: root
  become: yes
  gather_facts: no
  vars:
    state: present

  tasks:
  - name: ensure firewalld is at the latest version
    apt:
      name: firewalld
      update_cache: yes
EOL
```

### run playbook

```
ansible-playbook -i inventory.ini playbook.yml

```

### creating ansible config file

```
ansible --version #to check config file

mkdir /etc/ansible/

cat > /etc/ansible/ansible.cfg <<EOF
[defaults]
stdout_callback = yaml
deprecation_warnings = False
host_key_checking = False
retry_files_enabled = False
inventory = /inventory.ini
EOF
```

### ansible-galaxy
```
ansible-galaxy search terraform
ansible-galaxy role install secfigo.terraform
```

### search modules - https://docs.ansible.com/ansible/2.8/modules/list_of_all_modules.html

```
ansible-doc -l | egrep "add_host|amazon.aws.aws"
ansible-doc -l | egrep "copy"

```


### pipeline in gitlab

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

job:
  stage: build
  script:
    - echo "I'm a job"

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

```
