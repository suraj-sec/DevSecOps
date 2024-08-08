pip3 install pip-audit==1.1.2
pip-audit -r ./requirements.txt -f json | tee pip-audit-output.json