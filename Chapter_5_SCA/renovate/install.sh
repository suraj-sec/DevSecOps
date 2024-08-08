mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
NODE_MAJOR=20
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
apt update

apt install nodejs -y

npm install -g renovate

# fix issues after running renivate first time
echo "deb http://ppa.launchpad.net/git-core/ppa/ubuntu $(lsb_release -cs) main"  >> /etc/apt/sources.list
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys E1DD270288B4E6030699E45FA1715D88E1DF1F24
apt update && apt install git -y


export RENOVATE_TOKEN="<your_token>" #github token

renovate <github_username>/webapp

git pull origin main