wget https://github.com/gitleaks/gitleaks/releases/download/v8.18.1/gitleaks_8.18.1_linux_x64.tar.gz && tar -xvzf gitleaks_8.18.1_linux_x64.tar.gz && mv gitleaks /usr/local/bin
gitleaks detect . --report-path gitleaks-output.txt
gitleaks detect . --report-path gitleaks-redact50.txt --redact=50
