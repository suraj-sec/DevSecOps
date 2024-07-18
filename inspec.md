### install inspec

```
wget https://packages.chef.io/files/stable/inspec/5.22.29/ubuntu/18.04/inspec_5.22.29-1_amd64.deb
dpkg -i inspec_5.22.29-1_amd64.deb
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

###
