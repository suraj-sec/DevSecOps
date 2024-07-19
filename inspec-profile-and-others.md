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
```
