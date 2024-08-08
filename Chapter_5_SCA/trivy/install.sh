wget https://github.com/aquasecurity/trivy/releases/download/v0.48.1/trivy_0.48.1_Linux-64bit.deb && dpkg -i trivy_*.deb
trivy -h

trivy filesystem .