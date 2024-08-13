pip3 install bandit==1.7.4
bandit -r . -f json | tee bandit-output.json
