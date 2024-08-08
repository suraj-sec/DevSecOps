curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
NODE_MAJOR=20
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
apt update
apt install nodejs -y

npm install -g @sandworm/audit

sandworm --help

npm install
sandworm audit

ls -l sandworm #to read saved files

sandworm audit --skip-csv 

#Let’s display all keys of the output file.
cat sandworm/owasp-nodejs-goat@1.3.0-report.json | jq 'keys'


#Let’s check how many vulnerabilities are found by filtering the severity field.
cat sandworm/owasp-nodejs-goat@1.3.0-report.json | jq '.dependencyVulnerabilities'
cat sandworm/owasp-nodejs-goat@1.3.0-report.json | jq '.dependencyVulnerabilities | length'


# Resolving issues

sandworm resolve --help
sandworm audit --skip-license-issues
cat sandworm/owasp-nodejs-goat@1.3.0-report.json | jq '.dependencyVulnerabilities[] | select(.severity == "critical") | .githubAdvisoryId'
sandworm resolve --issueId <issue-id-from-previous-command>
