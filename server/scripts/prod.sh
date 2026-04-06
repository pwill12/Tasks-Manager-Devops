#!/bin/bash
set -e

# Allow user to specify Kubernetes context via environment variable
# Usage: K8S_CONTEXT=minikube ./deploy.sh (to use Minikube)
K8S_CONTEXT="${K8S_CONTEXT:-minikube}"

# Set KUBECONFIG to Windows Docker Desktop location when running from WSL
if [[ -f "/mnt/c/Users/USER/.kube/config" ]]; then
    export KUBECONFIG="/mnt/c/Users/USER/.kube/config"
elif [[ -f "${HOME}/.kube/config" ]]; then
    export KUBECONFIG="${HOME}/.kube/config"
else
    echo "Error: Kubernetes config not found."
    exit 1
fi

# For minikube, fix the kubeconfig paths from Windows to WSL format
if [[ "$K8S_CONTEXT" == "minikube" ]]; then
    echo "Setting up minikube context..."
    
    # Check if minikube is running
    if ! minikube status &>/dev/null; then
        echo "Starting minikube..."
        minikube start
    fi
    
    # Use minikube's docker daemon for building images
    echo "Configuring Docker to use minikube's daemon..."
    eval $(minikube docker-env)
fi

# Switch to specified context
echo "Switching to $K8S_CONTEXT context..."
kubectl config use-context "$K8S_CONTEXT"

# Verify kubectl can connect
if ! kubectl cluster-info &>/dev/null; then
    echo "Error: Cannot connect to Kubernetes cluster."
    if [[ "$K8S_CONTEXT" == "docker-desktop" ]]; then
        echo "Please ensure Docker Desktop Kubernetes is enabled and running."
        echo "To enable: Docker Desktop -> Settings -> Kubernetes -> Enable Kubernetes"
    elif [[ "$K8S_CONTEXT" == "minikube" ]]; then
        echo "Please ensure minikube is installed and running."
        echo "To start: minikube start"
    fi
    exit 1
fi

echo "Connected to Kubernetes cluster ($K8S_CONTEXT) successfully!"

NAME="task-devops-backend"
USERNAME="pwill12"
TAG="latest"
IMAGE="$USERNAME/$NAME:$TAG"

echo "Building Docker Image..."
docker build -t $IMAGE .

# Only push to registry if not using minikube (minikube uses local images)
if [[ "$K8S_CONTEXT" != "minikube" ]]; then
    echo "Pushing Docker Image to registry..."
    docker push $IMAGE
else
    echo "Skipping push (using minikube's local Docker daemon)..."
fi

echo "Deploying to Kubernetes..."
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml

echo "Getting pods..."
kubectl get pods

echo "Getting services..."
kubectl get services

echo "Getting main service..."
kubectl get services $NAME-service
