# Operability Take Home Exercise - L. Masubelele

# Prerequisites:
- docker
- minikube
  
## Minikube setup
```bash
minikube start
minikube addons enable ingress
```
## Prepare app image
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
uWSGI==2.0.21
EOF

```
#### Build image
```bash
minikube image build -t python-app:v1 .
```
## Deploy app
##### Create deployment
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
            port: 5000
          initialDelaySeconds: 5
          timeoutSeconds: 2
          successThreshold: 1
          failureThreshold: 3
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /healthz
            port: 5000
          initialDelaySeconds: 5
          timeoutSeconds: 2
          successThreshold: 1
          failureThreshold: 3
          periodSeconds: 10
        ports:
        - containerPort: 5000
          name: http
      restartPolicy: Always
EOF
```
> Output:
> deployment.apps/python-app created

##### Create service
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
      targetPort: 5000
EOF
```
##### Create ingress
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
```bash 
minikube kubectl -- get pods -n default
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