#!/bin/bash

set -e

mkdir -p k8s
cd k8s

echo "Creating Kubernetes YAML files for PROD..."

# =========================
# 1. NAMESPACE
# =========================
cat <<EOF > namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: prod
EOF

# =========================
# 2. SECRET (RDS PASSWORD)
# =========================
cat <<EOF > rds-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: rds-secret
  namespace: prod
type: Opaque
stringData:
  DB_PASSWORD: MySecurePass123   # 🔴 change if needed
EOF

# =========================
# 3. CONFIGMAP (DB CONFIG)
# =========================
cat <<EOF > backend-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: backend-config
  namespace: prod
data:
  SPRING_DATASOURCE_URL: jdbc:mysql://myapp-db.c3miyesogyny.ap-south-1.rds.amazonaws.com:3306/myapp
  SPRING_DATASOURCE_USERNAME: admin
EOF

# =========================
# 4. BACKEND DEPLOYMENT
# =========================
cat <<EOF > backend-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: prod
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
        - name: backend
          image: 081139831993.dkr.ecr.ap-south-1.amazonaws.com/demo-backend:latest
          ports:
            - containerPort: 8080
          env:
            - name: SPRING_DATASOURCE_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: rds-secret
                  key: DB_PASSWORD
          envFrom:
            - configMapRef:
                name: backend-config
EOF

# =========================
# 5. BACKEND SERVICE
# =========================
cat <<EOF > backend-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: backend-service
  namespace: prod
spec:
  selector:
    app: backend
  ports:
    - port: 80
      targetPort: 8080
EOF

# =========================
# 6. FRONTEND DEPLOYMENT
# =========================
cat <<EOF > frontend-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: prod
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
        - name: frontend
          image: 081139831993.dkr.ecr.ap-south-1.amazonaws.com/demo-frontend:latest
          ports:
            - containerPort: 80
EOF

# =========================
# 7. FRONTEND SERVICE
# =========================
cat <<EOF > frontend-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
  namespace: prod
spec:
  selector:
    app: frontend
  ports:
    - port: 80
      targetPort: 80
EOF

# =========================
# 8. INGRESS (ALB)
# =========================
cat <<EOF > ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  namespace: prod
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
spec:
  ingressClassName: alb
  rules:
    - http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: frontend-service
                port:
                  number: 80
          - path: /api
            pathType: Prefix
            backend:
              service:
                name: backend-service
                port:
                  number: 80
EOF

echo "✅ All Kubernetes YAML files created in ./k8s"
