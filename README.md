# Operability Take Home Exercise

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
docker build -t python-app:v1 .
```