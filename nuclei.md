```
wget https://github.com/projectdiscovery/nuclei/releases/download/v2.9.12/nuclei_2.9.12_linux_amd64.zip
unzip nuclei_2.9.12_linux_amd64.zip
mv nuclei /usr/bin/
nuclei

wget https://github.com/projectdiscovery/katana/releases/download/v1.0.3/katana_1.0.3_linux_amd64.zip
unzip katana_1.0.3_linux_amd64.zip
mv katana /usr/bin/

katana -u https://public-firing-range.appspot.com/ -f qurl -o endpoints.txt
sed -i '/^$/d' endpoints.txt

git clone https://github.com/projectdiscovery/fuzzing-templates.git
nuclei -list endpoints.txt -t fuzzing-templates [-verbose]

nuclei -w django-workflow.yaml -validate

time nuclei -u https://prod-lq84iw0v.lab.practical-devsecops.training/ -w django-workflow.yaml
time nuclei -u https://prod-lq84iw0v.lab.practical-devsecops.training/ -t /root/nuclei-templates/
```
