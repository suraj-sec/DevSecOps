curl -sL https://deb.nodesource.com/setup_14.x | bash -
apt install nodejs -y
npm install
npm audit --json | tee results.json