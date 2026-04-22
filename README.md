DevSecOps End-to-End Project

Node.js · GitHub Actions · Docker · Trivy · Kind · ArgoCD · SonarQube · Prometheus · Grafana

Architecture

Developer → GitHub Repository
  ↓
GitHub Actions (CI Pipeline)
 ├── Jest Tests
 ├── SonarCloud Code Analysis
 ├── Trivy Security Scan (vulnerabilities in Docker image)
 ├── Docker Build
 └── Push to Docker Hub
  ↓
ArgoCD (GitOps)
  ↓
Kind Kubernetes Cluster
 └── production namespace
   └── Node.js Application Pods
     ↓
   /metrics endpoint (prom-client)
     ↓
Prometheus (metrics scraping)
     ↓
Grafana (dashboards)
     ↓
Alertmanager (alerts)

Prerequisites
Tool	Install
Docker	https://docs.docker.com/get-docker/

kind	brew install kind
kubectl	brew install kubectl
helm	brew install helm
git	brew install git
Quick Start (Local Setup)
git clone https://github.com/Aijazkhan123/devsecops-project
cd devsecops-project

chmod +x setup.sh
./setup.sh

Access app:

kubectl port-forward svc/nodejs-app-service -n production 300:80
curl http://localhost:300
Step-by-Step Guide
Step 1 — Create Kind Cluster
kind create cluster --name devsecops --config kind-config.yaml
kubectl cluster-info --context kind-devsecops
Step 2 — Run Node.js App
cd app
npm install
npm test
npm start
Step 3 — Docker Build
docker build -t nodejs-app:latest ./app
kind load docker-image nodejs-app:latest --name devsecops
Step 4 — Kubernetes Deployment
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
Step 5 — ArgoCD Setup
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

Access:

kubectl port-forward svc/argocd-server -n argocd 8090:443
Step 6 — Prometheus + Grafana
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

kubectl create namespace monitoring

helm install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring

Access Grafana:

kubectl port-forward svc/monitoring-grafana -n monitoring 300:80

Access Prometheus:

kubectl port-forward svc/monitoring-kube-prometheus-prometheus -n monitoring 9090:9090
Step 7 — SonarCloud Setup
Create account on https://sonarcloud.io
Add SONAR_TOKEN in GitHub Secrets
Configure sonar-project.properties
Step 8 — CI/CD Pipeline

GitHub Actions runs:

Jest tests
SonarCloud scan
Trivy security scan
Docker build
Push to Docker Hub
ArgoCD auto deploy
Useful Commands
kubectl get pods -A
kubectl logs -n production -l app=nodejs-app -f
kubectl get application -n argocd

Grafana:

kubectl port-forward svc/monitoring-grafana -n monitoring 300:80

Prometheus:

kubectl port-forward svc/monitoring-kube-prometheus-prometheus -n monitoring 9090:9090
Project Structure
devsecops-project/
├── app/
│   ├── src/
│   │   ├── index.js
│   │   └── index.test.js
│   ├── Dockerfile
│   ├── package.json
│   └── sonar-project.properties
├── k8s/
│   ├── namespace.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   └── argocd-app.yaml
├── monitoring/
│   ├── servicemonitor.yaml
│   └── alertrules.yaml
├── .github/
│   └── workflows/
│       └── main.yaml
├── kind-config.yaml
├── setup.sh
└── README.md
