#!/bin/bash
# One command to set up Kind, Docker, and deploy app
set -e
echo "Creating Kind cluster..."
kind create cluster --config kind-config.yaml

echo "Building Docker image..."
docker build -t devsecops-app:latest app

echo "Loading image into Kind..."
kind load docker-image devsecops-app:latest

echo "Deploying to cluster..."
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml

echo "All done! You can access your app with:"
kubectl get svc -n production