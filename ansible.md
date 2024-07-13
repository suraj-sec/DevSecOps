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

### run ansible commands

```
ansible -i inventory.ini  prod -m apt -a "name=ntp state=present"
ansible -i inventory.ini all -m command -a "bash --version"
```
