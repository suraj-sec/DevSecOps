### creating profile

```
mkdir inspec-profile && cd inspec-profile
inspec init profile ubuntu --chef-license accept

```

### creating task 

```
cat > ubuntu/controls/example.rb <<EOL
describe file('/etc/shadow') do
    it { should exist }
    it { should be_file }
    it { should be_owned_by 'root' }
  end
EOL
```

### validate the task

```
inspec check ubuntu
```

### running profile on local machine 

```
inspec exec ubuntu
```

### pipeline job

```
cat >.gitlab-ci.yml<<EOF
image: docker:20.10

services:
  - docker:dind

stages:
  - test

compliance:
  stage: test
  script:
    - docker run -i --rm -v $(pwd):/share chef/inspec check challenge --chef-license accept
    - docker run -i --rm -v $(pwd):/share chef/inspec exec challenge --chef-license accept
  allow_failure: true
EOF
```

or 

```
cat >.gitlab-ci.yml<<EOF
image: docker:20.10

services:
  - docker:dind

stages:
  - test

compliance:
  stage: test
  script:
    - docker run -i --rm -v $(pwd):/share chef/inspec check challenge --chef-license accept
    - docker run -i --rm -v $(pwd):/share chef/inspec exec challenge --chef-license accept
  allow_failure: true
EOF
```

## Inspec Shell

```
echo "StrictHostKeyChecking accept-new" >> ~/.ssh/config
inspec shell -t ssh://root@prod-lq84iw0v -i ~/.ssh/id_rsa --chef-license accept

```

### shell commands

```
help
help resources

file('/tmp').class.superclass.instance_methods(false).sort

file('/tmp').directory?

file('/tmp').exist?

file('/tmp').content

describe file('/tmp') do
it { should be_directory }
end

os_env('PATH')

os_env('PATH').content

os_env('PATH').split

exit
```

### resource command 

```
cat > ubuntu/controls/example.rb <<EOL
control 'ubuntu-1.3.2' do
   title 'Ensure sudo commands use pty'
   desc 'Attackers can run a malicious program using sudo, which would again fork a background process that remains even when the main program has finished executing.'
   describe command('grep -Ei "^\s*Defaults\s+([^#]+,\s*)?use_pty(,\s+\S+\s*)*(\s+#.*)?$" /etc/sudoers /etc/sudoers.d/*') do
      its('stdout') { should match /Defaults(\s*)use_pty/ }
   end
end
EOL

inspec check ubuntu

inspec exec ubuntu

echo "StrictHostKeyChecking accept-new" >> ~/.ssh/config

inspec exec ubuntu -t ssh://root@prod-lq84iw0v -i ~/.ssh/id_rsa --chef-license accept
```

### file resource

```
cat > ubuntu/controls/example.rb <<EOL
control 'ubuntu-1.3.2' do
   title 'Ensure sudo commands use pty'
   desc 'Attackers can run a malicious program using sudo, which would again fork a background process that remains even when the main program has finished executing.'
   describe file('/etc/sudoers') do
      its('content') { should match /Defaults(\s*)use_pty/ }
   end
end
EOL

inspec check ubuntu

inspec exec ubuntu

echo "StrictHostKeyChecking accept-new" >> ~/.ssh/config

inspec exec ubuntu -t ssh://root@prod-lq84iw0v -i ~/.ssh/id_rsa --chef-license accept

```

### custom matchers - Ensure permissions on /etc/ssh/sshd_config are configured

```
##we can see, we have 0666 as permission bits.

stat /etc/ssh/sshd_config

##we will change its permissions and ownership.

chown root:root /etc/ssh/sshd_config
chmod og-rwx /etc/ssh/sshd_config

# we are checking for three things.
#1. Ensure the owner of the file is root.
#2. Ensure this file belongs to the root group.
#3. The mode/permissions are read-only for root.

cat > ubuntu/controls/example.rb <<EOL
control 'ubuntu-5.2.1' do
   title 'Ensure permissions on /etc/ssh/sshd_config are configured'
   desc 'The /etc/ssh/sshd_configfile contains configuration specifications for sshd. The command below checks whether the owner and group of the file is root.'
   describe file('/etc/ssh/sshd_config') do
     its('owner') { should eq 'root'}
     its('group') { should eq 'root'}
     its('mode') { should cmp '0600' }
   end
end
EOL

#local machine
inspec check ubuntu
inspec exec ubuntu

#remote machine
echo "StrictHostKeyChecking accept-new" >> ~/.ssh/config 
inspec exec ubuntu -t ssh://root@prod-lq84iw0v -i ~/.ssh/id_rsa --chef-license accept
```

### dependency

We can include different sources of the profiles such as a path, URL, GitHub, supermarkets or compliance. In this exercise, we fetch 2 profiles, the SSH baseline from GitHub via the URL and Linux Baseline from the Supermarket. We need to specify the included profiles into the including profile’s inspec.yml file in the depends section. Example:

```
rm ubuntu/inspec.yml

cat >> ubuntu/inspec.yml <<EOL
name: profile-dependency
title: Profile with Dependencies
maintainer: InSpec Authors
copyright: InSpec Authors
copyright_email: support@chef.io
license: Apache-2.0
summary: InSpec Profile that is only consuming dependencies
version: 0.2.0
depends:
  - name: SSH baseline
    url: https://github.com/dev-sec/ssh-baseline/archive/master.tar.gz
  - name: Linux Baseline
    url: https://github.com/dev-sec/linux-baseline/archive/master.tar.gz
EOL

cd ubuntu

inspec vendor # to create cache locally and generate inspec.lock file

cd ..

echo "StrictHostKeyChecking accept-new" >> ~/.ssh/config #commands prevent the ssh agent from prompting YES or NO question


#add include_controls inside ubuntu/controls/example.rb file to make inspec able to include the dependencies in scanning.
cat >> ubuntu/controls/example.rb << EOL
# copyright: 2018, The Authors

title "sample section"

# you can also use plain tests
describe file("/tmp") do
  it { should be_directory }
end

# you add controls here
control "tmp-1.0" do                        # A unique ID for this control
  impact 0.7                                # The criticality, if this control fails.
  title "Create /tmp directory"             # A human-readable title
  desc "An optional description..."
  describe file("/tmp") do                  # The actual test
    it { should be_directory }
  end
end

include_controls 'SSH baseline'
include_controls 'Linux Baseline'
EOL


inspec exec ubuntu -t ssh://root@prod-lq84iw0v -i ~/.ssh/id_rsa --chef-license accept
```

### cis controls

```
mkdir cis-ubuntu && cd cis-ubuntu
inspec init profile ubuntu --chef-license accept

# create sudo task in ubuntu profile based on CIS benchmarks
cat >> ubuntu/controls/configure_sudo.rb <<EOL
control 'ubuntu-1.3.1' do
   title 'Ensure sudo is installed'
   desc 'sudo allows a permitted user to execute a command as the superuser or another user, as specified by the security policy.'
   describe package('sudo') do
      it { should be_installed }
   end
end

control 'ubuntu-1.3.2' do
   title 'Ensure sudo commands use pty'
   desc 'Attackers can run a malicious program using sudo, which would again fork a background process that remains even when the main program has finished executing.'
   describe command('grep -Ei "^\s*Defaults\s+([^#]+,\s*)?use_pty(,\s+\S+\s*)*(\s+#.*)?$" /etc/sudoers').stdout do
      it { should include 'Defaults use_pty' }
   end
end

control 'ubuntu-1.3.3' do
   title 'Ensure sudo log file exists'
   desc 'Attackers can run a malicious program using sudo, which would again fork a background process that remains even when the main program has finished executing.'
   describe command('grep -Ei "^\s*Defaults\s+logfile=\S+" /etc/sudoers').stdout do
      it { should include 'Defaults logfile=' }
   end
end
EOL

rm ubuntu/controls/example.rb

# run locally 

inspec check ubuntu
inspec exec ubuntu

# run remotely

echo "StrictHostKeyChecking accept-new" >> ~/.ssh/config
inspec exec ubuntu -t ssh://root@prod-lq84iw0v -i ~/.ssh/id_rsa --chef-license accept

## edit the /etc/sudoers file, it should look like the following output
sudo visudo
Defaults use_pty
Defaults logfile="/var/log/sudo.log"

```

### asvs

```
mkdir inspec-asvs && cd inspec-asvs
inspec init profile asvs --chef-license accept


cat > asvs/controls/example.rb <<EOL
control 'ASVS-14.4.1' do
    impact 0.7
    title 'Safe character set'
    desc 'HTTP response contains content type header with safe character set'
    describe http('https://prod-lq84iw0v.lab.practical-devsecops.training') do
        its ('headers.Content-type') { should cmp 'text/html; charset=utf-8'}
    end
end

control 'ASVS-14.4.2' do
    impact 0.7
    title 'Contain Content Disposition header attachment'
    desc "Add Content-Disposition header to the server's configuration, Add 'attachment' directive to the header."
    describe http('https://prod-lq84iw0v.lab.practical-devsecops.training') do
        its ('headers.content-disposition') { should cmp 'attachment' }
    end
end

control 'ASVS-14.4.3' do
    impact 0.7
    title 'Content Security Policy Options != none / contain unsafe-inline;unsafe-eval;\* '
    desc "Ensure that CSP is not configured with the directives: 'unsafe-inline', 'unsafe-eval' and wildcards."
    describe http('https://prod-lq84iw0v.lab.practical-devsecops.training') do
        its ('headers.content-security-policy') { should_not cmp 'none' }
        its ('headers.content-security-policy') { should_not include 'unsafe-inline;unsafe-eval;\*'}
    end
end

control 'ASVS-14.4.4' do
    impact 0.7
    title 'Content type Options = no sniff'
    desc 'All responses should contain X-Content-Type-Options=nosniff'
    describe http('https://prod-lq84iw0v.lab.practical-devsecops.training') do
        its ('headers.x-content-type-options') { should cmp 'nosniff'}
    end
end

control 'ASVS-14.4.5' do
    impact 0.7
    title 'HSTS is using directives max-age=15724800'
    desc 'Verify that HTTP Strict Transport Security headers are included on all responses and for all subdomains, such as Strict-Transport-Security: max-age=15724800; includeSubDomains.'
    describe http('https://prod-lq84iw0v.lab.practical-devsecops.training') do
        its ('headers.Strict-Transport-Security') { should match /\d/ }
    end
end

control 'ASVS-14.4.6' do
    impact 0.7
    title "'Referrer-Policy' header is included"
    desc "HTTP requests may include Referrer header, which may expose sensitive information. Referrer-Policy restiricts how much information is sent in the Referer header."
    describe http('https://prod-lq84iw0v.lab.practical-devsecops.training') do
        its ('headers.referrer-policy') { should cmp 'no-referrer; same-origin' }
    end
end
EOL

inspec exec asvs
```

### docker

```
mkdir inspec && cd inspec



# The output changes from 21 successful controls to 35 and 36 control failures to 47. This change is because of skipped container runtime checks as no containers were running when we first used this inspec profile. After we started a container, Inspec also included runtime checks as part of the scan.

inspec exec https://github.com/dev-sec/cis-docker-benchmark.git --chef-license accept

# run docker
docker run -d --name alpine -it alpine /bin/sh
docker ps
inspec exec https://github.com/dev-sec/linux-baseline.git --chef-license accept -t docker://alpine
inspec exec https://github.com/dev-sec/cis-docker-benchmark.git --chef-license accept


```


### jenkinsfile

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
                input "Deploy to production?"
                echo "This is a deploy step."
            }
        }
        stage("Inspec"){
            agent {
                docker {
                    image 'hysnsec/inspec'
                    args '-u root'
                }
            }
            steps {
                sshagent(['ssh-prod']) {
                    catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {     // Allow the sast stage to fail
                        sh "inspec exec https://github.com/dev-sec/linux-baseline.git -t ssh://root@prod-server --chef-license accept --reporter json:inspec-output.json"
                    }
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: 'inspec-output.json', fingerprint: true
                }
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
            deleteDir()                     // clean up workspace
        }
    }
}
```

