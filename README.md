# Operability Take Home Exercise - L. Masubelele

# Prerequisites:
- docker
- minikube
  
## Minikube setup
```bash
minikube start
minikube addons enable ingress
```
###### Output
>lmasu@b0be836ea5ba ~ % minikube start
> ...
> 🏄  Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default
> minikube addons enable ingress
> ...
> 🌟  The 'ingress' addon is enabled
## Prepare app image
```bash
mkdir -p python-app
cd python-app
```
#### Create source code
```bash
cat > app.py <<EOF
from flask import Flask
app = Flask(__name__)

@app.route('/')
def hello_world():
    return 'Hello, World!'

@app.route('/healthz')
def health():
    return 'OK!'

if __name__ == '__main__':
    app.run()
EOF
```
#### Create requirements.txt file for python dependencies
```bash
cat > requirements.txt <<EOF
Flask==2.2.5
gunicorn==21.2.0
EOF

```
### Create Dockerfile
```bash
cat > Dockerfile <<EOF
FROM  python:slim-bookworm
WORKDIR /app

COPY ./app.py  .
COPY requirements.txt .

RUN apt-get update --no-install-recommends && \
    apt-get install --no-install-recommends -y gcc && \
    pip install --no-cache-dir -r requirements.txt && \
    chown nobody . -R

USER nobody
EXPOSE 8000
ENTRYPOINT  gunicorn -w 4 -b 0.0.0.0 app:app
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 CMD curl -f http://localhost:8000/healthz || exit 1
EOF
```
#### Build image
```bash
minikube image build -t python-app:v1 .
```
###### Output
> ...
> #9 DONE 21.7s
> #10 exporting to image
> #10 exporting layers
> #10 exporting layers 0.4s done
> #10 writing image sha256:49f3af263f43526f8e702e358f37b582fbc42ca7f2395db1abd7b19d72f42935 done
> #10 naming to docker.io/library/python-app:v1 done
> #10 DONE 0.4s
## Deploy app
#### Create deployment
```bash
export IMAGE=python-app:v1
export APP_NAME=python-app

cat <<EOF | envsubst | minikube kubectl -- apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${APP_NAME}
  namespace: default
  labels:
    app: ${APP_NAME}
spec:
  selector:
    matchLabels:
      app: ${APP_NAME}
  replicas: 3
  strategy:
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 25%
    type: RollingUpdate
  template:
    metadata:
      labels:
        app: ${APP_NAME}
    spec:
      containers:
      - name: ${APP_NAME}
        image: ${IMAGE}
        imagePullPolicy: Never
        resources:
          requests:
            cpu: 100m
            memory: 100Mi
          limits:
            cpu: 100m
            memory: 100Mi
        livenessProbe:
          httpGet:
            path: /healthz
            port: 8000
          initialDelaySeconds: 5
          timeoutSeconds: 2
          successThreshold: 1
          failureThreshold: 3
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /healthz
            port: 8000
          initialDelaySeconds: 5
          timeoutSeconds: 2
          successThreshold: 1
          failureThreshold: 3
          periodSeconds: 10
        ports:
        - containerPort: 8000
          name: http
      restartPolicy: Always
EOF
```
###### Output
> deployment.apps/python-app created

#### Create service
```bash
cat <<EOF | envsubst | minikube kubectl -- apply -f -
kind: Service
apiVersion: v1
metadata:
  name: ${APP_NAME}-service
  namespace: default
spec:
  selector:
    app: ${APP_NAME}
  ports:
    - port: 80
      targetPort: 8000
EOF
```
###### Output
> service/python-app-service created

#### Create ingress
```bash
cat <<EOF | envsubst | minikube kubectl -- apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ${APP_NAME}-ingress
  namespace: default
  annotations:
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
spec:
  rules:
    - http:
        paths:
          - pathType: Prefix
            path: /
            backend:
              service:
                name: ${APP_NAME}-service
                port:
                  number: 80
EOF
```
###### Output
> ingress.networking.k8s.io/python-app-ingress created
#### Verify deployment
```bash 
minikube kubectl -- get pods -n default
```
###### Output
| NAME | READY | STATUS | RESTARTS | AGE |
|------|-------|--------|----------|-----|
| python-app-xxxxx-xxxx | 1/1 | Running | 0 | 3m24s |
| python-app-xxxxx-xxxx | 1/1 | Running | 0 | 3m24s |
| python-app-xxxxx-xxxx | 1/1 | Running | 0 | 3m24s |

## Access the app
```bash
minikube tunnel
```
###### Output: - Enter password if prompted
> ✅  Tunnel successfully started
> 📌  NOTE: Please do not close this terminal as this process must stay alive for the tunnel to be accessible ...
> ❗  The service/ingress python-app-ingress requires privileged ports to be exposed: [80 443]
> 🔑  sudo permission will be asked for it.
> 🏃  Starting tunnel for service python-app-ingress.
> Password:

### Visit https://127.0.0.1/ on your browser.

## Clean up
```bash
minikube delete --all
```