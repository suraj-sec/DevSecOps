### Playbooks are a collection of Ansible tasks, you can run a playbook against a local or a remote machine. They help us in configuring machine(s) according to the requirements. Ansible uses the YAML format to declare the configurations.
Playbooks follow a directory layout. A sample playbook directory structure is shown below:

```
tasks/              # task files included from playbooks
    01-install.yml  # task file to install something
    02-config.yml   # task file to copy configuration to remote machine
    main.yml        # master task playbook
roles/
    common/         # this hierarchy represents a "role"
vars/
    main.yml        # vars file to save variables
main.yml            # master playbook
```

### creating playbook

```
mkdir simple-playbook && cd simple-playbook
mkdir tasks


# creating main.yml file

cat > tasks/main.yml <<EOL
---
- name: Install nginx
  apt:
    name: nginx
    state: present
    update_cache: true

- name: Copy the configuration
  template:
    src: templates/default.j2
    dest: /etc/nginx/sites-enabled/default

- name: Start nginx service
  service:
    name: nginx
    state: started
    enabled: yes

- name: Clone django repository
  git:
    repo: https://gitlab.practical-devsecops.training/pdso/django.nv.git
    dest: /opt/django

- name: Install dependencies
  command: pip3 install -r requirements.txt
  args:
    chdir: /opt/django

- name: Database migration
  command: python3 manage.py migrate
  args:
    chdir: /opt/django

- name: Load data from the fixtures
  shell: python3 manage.py loaddata fixtures/*
  args:
    chdir: /opt/django

- name: Run an application in the background
  shell: nohup python3 manage.py runserver 0.0.0.0:8000 &
  args:
    chdir: /opt/django
EOL

# creating template file

mkdir templates

cat > templates/default.j2 <<EOL
{% raw %}
server {
    listen      80;
    server_name localhost;

    access_log  /var/log/nginx/django_access.log;
    error_log   /var/log/nginx/django_error.log;

    proxy_buffers 16 64k;
    proxy_buffer_size 128k;

    location / {
        proxy_pass  http://localhost:8000;
        proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;
        proxy_redirect off;

        proxy_set_header    Host \$host;
        proxy_set_header    X-Real-IP \$remote_addr;
        proxy_set_header    X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header    X-Forwarded-Proto http;
    }
}
{% endraw %}
EOL

# create a main.yml playbook file that uses the main.yml under the tasks folder
cat > main.yml <<EOL
---
- name: Simple playbook
  hosts: sandbox
  remote_user: root
  gather_facts: no

  tasks:
  - include: tasks/main.yml
EOL

mv ../inventory.ini .

ansible-playbook -i inventory.ini main.yml

```

### playbooks conditionals

```
# nginx using stat, msg and apt modules

cat > /challenges/main.yml <<EOL
- name: Playbook to install nginx
  hosts: sandbox
  remote_user: root
  become: yes

  # We are checking availability of nginx binary at a specific location
  tasks:
    - name: check if nginx installed
      stat:
        path: /usr/sbin/nginx
      register: stat_nginx

    - name: get nginx version
      command: nginx -v
      register: nginx_version
      when: stat_nginx.stat.exists

    - name: Print version
      debug:
        msg: "{{ nginx_version.stderr }}"
      when:
        - nginx_version is defined
        - stat_nginx.stat.exists

    - name: install nginx if not exist
      apt:
        name: nginx
        state: present
        update_cache: true
      when: not stat_nginx.stat.exists
EOL


# check if the system is ubuntu using register and stdout

cat > main.yml <<EOL
---
- name: Simple playbook
  hosts: all
  remote_user: root
  gather_facts: no     # what does it mean?

  tasks:
  - name: Show the content of /etc/os-release
    command: cat /etc/os-release
    register: os_release

  - debug:
      msg: "This system uses Ubuntu-based distro"
    when: os_release.stdout.find('Ubuntu') != -1
EOL
```

###
