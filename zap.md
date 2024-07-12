```
docker pull softwaresecurityproject/zap-stable:2.13.0
docker run --rm softwaresecurityproject/zap-stable:2.13.0 zap-baseline.py --help

docker run --user $(id -u):$(id -g) -w /zap -v $(pwd):/zap/wrk:rw --rm softwaresecurityproject/zap-stable:2.13.0 zap-baseline.py -t https://prod-lq84iw0v.lab.practical-devsecops.training -J zap-output.json
```

Option	Description
rw	Sets the volume mount to read-write mode. Recommended by ZAP for volume mounting.
-w /zap	Sets /zap as the container’s working directory, required for baseline scans


The purpose of Progress File is to list vulnerabilities, enabling quick identification of whether an issue is new or already being addressed.
By marking known issues as IN-PROGRESS in the scan output, it simplifies the process of spotting new issues.

```
cat > progress-file.json << EOL
{
    "site": "https://prod-lq84iw0v.lab.practical-devsecops.training",
    "issues": [
        {
            "id": "10099",
            "name": "Source Code Disclosure - SQL",
            "state": "inprogress",
            "link": "[FP] INTDENDED VULNERALBILITES, A FALSE POSITIVE [FP]"

        },
        {
            "id": "10063",
            "name": "[EXAMPLE] Insert the issue name here! [EXAMPLE]",
            "state": "inprogress",
            "link": "[EXAMPLE] Insert tracked / on progress issue here! [EXAMPLE]"
        },
        {
            "id": "10036",
            "name": "Server Leaks Version Information via \"Server\" HTTP Response Header Field",
            "state": "inprogress",
            "link": "https://dojo-lq84iw0v.lab.practical-devsecops.training/finding/4"
        },
        {
            "id": "10035",
            "name": "Strict-Transport-Security Header Not Set",
            "state": "inprogress",
            "link": "https://dojo-lq84iw0v.lab.practical-devsecops.training/finding/3"
        }
    ]
}
EOL

docker run --user $(id -u):$(id -g) -w /zap -v $(pwd):/zap/wrk:rw --rm  softwaresecurityproject/zap-stable:2.13.0 zap-baseline.py -t https://prod-lq84iw0v.lab.practical-devsecops.training -p progress-file.json -J zap-output.json

```

The Config File organizes issues into WARN, FAIL, and OUTOFSCOPE categories, simplifying analysis to distinguish between new problems and those already under attention.
By appropriately marking known issues in the scan results, the process of spotting new problems becomes easier.

Let’s begin by creating a Config File named default.conf from the results of the scan using the -g option with the following command:

```
docker run --user $(id -u):$(id -g) -w /zap -v $(pwd):/zap/wrk:rw --rm softwaresecurityproject/zap-stable:2.13.0 zap-baseline.py -t https://prod-lq84iw0v.lab.practical-devsecops.training -g default.conf  # -g option, generate default config file (all rules set to WARN).
```

https://www.zaproxy.org/docs/docker/baseline-scan/#configuration-file

```
docker run --user $(id -u):$(id -g) -w /zap -v $(pwd):/zap/wrk:rw --rm softwaresecurityproject/zap-stable:2.13.0 zap-baseline.py -t https://prod-lq84iw0v.lab.practical-devsecops.training -g default.conf -J zap-output.json
```
