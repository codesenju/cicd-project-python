# Operability Take Home Exercise - L. Masubelele

## Setup virtual python environment
```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt 
```
## Minikube setup
```bash
minikube start
minikube addons enable ingress
```
## Prepare image
```bash
minikube image build -t python-app:v1 .
```

## Deploy app
```bash
minikube kubectl -- apply -f k8s/manifests.yaml   
minikube kubectl -- get pods -n default -w
```

##  Access the app
```bash
minikube tunnel
```
> Visit http://localhost/ on yout browser.

## Clean up
```bash
minikube delete --all
```

# Reference:
- https://devopscube.com/minikube-mac/
- https://minikube.sigs.k8s.io/docs/drivers/qemu/