apt update
apt install ruby-full -y
gem install brakeman -v 5.2.1
brakeman -f json | tee result.json
