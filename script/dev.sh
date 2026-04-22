#!/bin/bash
set -e

export KUBECONFIG="${HOME}/.kube/config"

TAG="local"
BACKEND_IMAGE="backend:$TAG"
FRONTEND_IMAGE="frontend:$TAG"
NAMESPACE="task-devops"

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo "❌ Error: Docker is not running!"
    echo "   Please start Docker Desktop and try again."
    exit 1
fi

# Ensure minikube is running
echo "Checking minikube status..."
if ! minikube status &>/dev/null; then
    echo "Starting minikube..."
    minikube start --driver=docker
fi

# Switch to minikube context
kubectl config use-context minikube

# Create namespace first
echo "Creating namespace..."
kubectl apply -f k8s/00-namespace.yaml

# Build images
echo "Building Docker backend image..."
docker build -t "$BACKEND_IMAGE" ./server

echo "Building Docker frontend image..."
docker build --build-arg VITE_API_URL=http://localhost:8000/api -t "$FRONTEND_IMAGE" ./client

# Load images into minikube
echo "Loading backend image into minikube..."
minikube image load "$BACKEND_IMAGE"

echo "Loading frontend image into minikube..."
minikube image load "$FRONTEND_IMAGE"

echo "Listing images in minikube..."
minikube image ls

# Deploy to Kubernetes
echo "Deploying mongo..."
kubectl apply -f k8s/01-mongo.yaml

echo "Deploying backend..."
kubectl apply -f k8s/02-backend.yaml

echo "Deploying frontend..."
kubectl apply -f k8s/03-frontend.yaml

# Wait for all deployments to be ready
echo "Waiting for pods to be ready..."
kubectl rollout status deployment/mongo -n $NAMESPACE
kubectl rollout status deployment/backend -n $NAMESPACE
kubectl rollout status deployment/frontend -n $NAMESPACE

echo ""
echo "Getting pods..."
kubectl get pods -n $NAMESPACE

echo ""
echo "Getting services..."
kubectl get services -n $NAMESPACE

# Kill any existing port forwards
echo ""
echo "Cleaning up existing port forwards..."
pkill -f "kubectl port-forward" 2>/dev/null || true

# Start port forwarding in background
# echo "Starting port forwarding..."
# kubectl port-forward service/frontend-service 3000:3000 -n $NAMESPACE &
# kubectl port-forward service/backend-service 8000:8000 -n $NAMESPACE &

# Wait for port forwards to start
# sleep 2

echo ""
echo "✅ Deployment complete!"
echo ""
echo "🚀 Frontend: http://localhost:3000"
echo "🚀 Backend:  http://localhost:8000/api"
echo ""
echo "To stop port forwarding run:"
echo "pkill -f 'kubectl port-forward'"