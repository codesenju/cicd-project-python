#!/bin/bash

# Create source code
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
echo Created source code

# Create requirements.txt file for python dependencies
cat > requirements.txt <<EOF
Flask==2.2.5
uWSGI==2.0.21
EOF
echo Created requirements.txt file for python dependencies

# Create Dockerfile
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
EXPOSE 5000
ENTRYPOINT uwsgi --http 0.0.0.0:5000 --wsgi-file app.py --callable app
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:5000/healthz || exit 1
EOF
echo Created a Dockerfile for the python app

# Build image
echo Building image...
minikube image build -t python-app:v1 .

# Create deployment
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


# Create service
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

# Create ingress
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

# Verify deployment
minikube kubectl -- get pods -n default