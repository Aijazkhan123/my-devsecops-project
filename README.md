# DevSecOps End-to-End Project
> Node.js · GitHub Actions · Docker ·Trivy . Kind · ArgoCD · SonarQube · Prometheus · Grafana

## Architecture

```
Developer → GitHub Repository   ↓ GitHub Actions (CI Pipeline)  ├── Jest Tests  ├── SonarCloud Code Analysis  ├── Trivy Security Scan (vulnerabilities in Docker image)  ├── Docker Build  └── Push to Docker Hub   ↓ ArgoCD (GitOps)   ↓ Kind Kubernetes Cluster  └── production namespace    └── Node.js Application Pods      ↓    /metrics endpoint (prom-client)      ↓ Prometheus (metrics scraping)      ↓ Grafana (dashboards)      ↓ Alertmanager (alerts)
```

## Prerequisites

Install these tools before running setup:

| Tool | Install |
|------|---------|
| Docker | https://docs.docker.com/get-docker/ |
| kind | `brew install kind` or https://kind.sigs.k8s.io |
| kubectl | `brew install kubectl` |
| helm | `brew install helm` |
| git | `brew install git` |

---

## Quick Start (Local Setup)

```bash
# 1. Clone your repo
git clone https://github.com/Aijazkhan123/devsecops-project
cd devsecops-project

# 2. Run the full setup script
chmod +x setup.sh
./setup.sh

# 3. Access the app
kubectl port-forward svc/nodejs-app-service -n production 3000:80
curl http://localhost:3000
```

---

## Step-by-Step Guide

### Step 1 — Create the Kind Cluster

```bash
kind create cluster --name devsecops --config kind-config.yaml
kubectl cluster-info --context kind-devsecops
```

### Step 2 — Build & test the Node.js app locally

```bash
cd app
npm install
npm test              # runs Jest tests with coverage
npm start             # starts on http://localhost:3000
```

Test endpoints:
- `GET /`        → welcome message + hostname
- `GET /health`  → liveness check
- `GET /ready`   → readiness check
- `GET /metrics` → Prometheus metrics
- `GET /api/items` → sample API response

### Step 3 — Build Docker image & load into kind

```bash
# Build
docker build -t nodejs-app:latest ./app

# Load directly into kind (no registry needed locally)
kind load docker-image nodejs-app:latest --name devsecops
```

### Step 4 — Deploy to Kubernetes

```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml

# Watch pods come up
kubectl get pods -n production -w

# Port-forward to test
kubectl port-forward svc/nodejs-app-service -n production 3000:80
curl http://localhost:3000
```

### Step 5 — Install ArgoCD (GitOps)

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for it
kubectl wait --namespace argocd \
  --for=condition=available deployment/argocd-server --timeout=180s

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d

# Access UI
kubectl port-forward svc/argocd-server -n argocd 8090:443
# Open https://localhost:8090  (user: admin)
```

Edit `k8s/argocd-app.yaml` and set your GitHub repo URL, then:

```bash
kubectl apply -f k8s/argocd-app.yaml
```

ArgoCD will now auto-sync every time you push to the `k8s/` folder.

### Step 6 — Install Prometheus + Grafana

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

kubectl create namespace monitoring

helm install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set grafana.adminPassword=admin123

# Access Grafana
kubectl port-forward svc/monitoring-grafana -n monitoring 300:80
# Open http://localhost:300  

# Access Prometheus
kubectl port-forward svc/monitoring-kube-prometheus-prometheus -n monitoring 9090:9090
# Open http://localhost:9090
```

Apply monitoring config:
```bash
kubectl apply -f monitoring/servicemonitor.yaml
kubectl apply -f monitoring/alertrules.yaml
```

### Step 7 — Set up SonarQube (SonarCloud)

1. Go to https://sonarcloud.io and create a free account
2. Create a new project → link to your GitHub repo
3. Copy your `SONAR_TOKEN`
4. Add secrets to GitHub repo → Settings → Secrets:
   - `SONAR_TOKEN`
   - `DOCKER_USERNAME`
   - `DOCKER_PASSWORD`
5. Update `app/sonar-project.properties` with your project key

### Step 8 — Push to GitHub and trigger CI

```bash
git add .
git commit -m "feat: initial devSecOps project"
git push origin main
```

GitHub Actions will:
1. Run Jest tests + coverage
2. Run SonarQube scan
3. Build Docker image
4. Push to Docker Hub
5. Update `k8s/deployment.yaml` with new image tag
6. ArgoCD detects the change and deploys automatically

---

## Useful Commands

```bash
# See all pods across namespaces
kubectl get pods -A

# Follow app logs
kubectl logs -n production -l app=nodejs-app -f

# Describe a pod (troubleshoot)
kubectl describe pod -n production -l app=nodejs-app

# Check ArgoCD sync status
kubectl get application -n argocd

# Check Prometheus targets
# http://localhost:9090/targets  (after port-forwarding)

# Reload Grafana dashboards
# Dashboards → Import → ID 1860 (Node Exporter Full)
# Dashboards → Import → ID 6417 (Kubernetes Pods)

# Delete everything and start fresh
kind delete cluster --name devsecops
```

---

## Grafana Dashboard IDs to Import

| Dashboard | ID |
|-----------|-----|
| Kubernetes Cluster Overview | `7249` |
| Kubernetes Pods | `6417` |
| Node Exporter Full | `1860` |
| NGINX Ingress | `9614` |

---

## Project Structure

```
devsecops-project/
├── app/
│   ├── src/
│   │   ├── index.js              # Express app + Prometheus metrics
│   │   └── index.test.js         # Jest tests
│   ├── Dockerfile                # Multi-stage build
│   ├── package.json
│   └── sonar-project.properties  # SonarQube config
├── k8s/
│   ├── namespace.yaml            # production namespace
│   ├── deployment.yaml           # app deployment (ArgoCD updates image tag)
│   ├── service.yaml              # ClusterIP service + Ingress
│   └── argocd-app.yaml          # ArgoCD Application CR
├── monitoring/
│   ├── servicemonitor.yaml       # Prometheus scrape config
│   └── alertrules.yaml           # Alert rules (down, high error rate, latency)
├── .github/
│   └── workflows/
│       └── main.yaml               # Full CI/CD pipeline
├── kind-config.yaml              # Kind cluster definition
├── setup.sh                      # One-shot local setup script
└── README.md
