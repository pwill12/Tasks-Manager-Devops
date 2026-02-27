#!/bin/bash
set -e

export KUBECONFIG="${HOME}/.kube/config"

NAME="task-devops-backend"
USERNAME="pwill12"
TAG="latest"
IMAGE="$USERNAME/$NAME:$TAG"

# Ensure minikube is running
echo "Checking minikube status..."
if ! minikube status &>/dev/null; then
    echo "Starting minikube..."
    minikube start --driver=docker
fi

# Switch to minikube context
kubectl config use-context minikube

echo "Building Docker image..."
docker build -t "$IMAGE" .

echo "Pushing image to Docker Hub..."
docker push "$IMAGE"

echo "Deploying to Kubernetes..."
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml

echo "Getting pods..."
kubectl get pods

echo "Getting services..."
kubectl get services

echo "Getting main service..."
kubectl get services "$NAME-service"