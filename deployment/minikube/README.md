# Minikube Local Development Guide

A comprehensive guide for running and testing Kubernetes applications locally using Minikube.

## Prerequisites

- Minikube installed
- kubectl installed
- Docker installed

## Quick Start

### 1. Start Minikube
```bash
minikube start
minikube dashboard                                # Open Kubernetes dashboard
```

### 2. Enable Required Addons
```bash
minikube addons enable ingress                    # Enable NGINX Ingress controller
minikube addons enable metrics-server             # Enable metrics for HPA
```

### 3. Configure Docker Environment
```bash
# Point Docker to Minikube's internal Docker engine
eval $(minikube docker-env)

# Build your images here
docker compose build

# Revert to local Docker when done
eval $(minikube docker-env -u)
```

**Important:** Images must be built within Minikube's Docker environment, otherwise deployments will fail with "ImagePullBackOff" errors.

### 4. Deploy Applications
```bash
# Create namespace
kubectl create namespace trocks-api

# Apply manifests
kubectl apply -f deployment.yml
kubectl apply -f service.yml
kubectl apply -f ingress.yml
```

## Minikube Management

### Cluster Operations
```bash
minikube start                                    # Start cluster
minikube stop                                     # Stop cluster
minikube delete                                   # Delete cluster
minikube status                                   # Check cluster status
minikube ssh                                      # SSH into Minikube VM
```

### Accessing Services
```bash
# Test service directly (opens in browser)
minikube service gateway-service -n trocks-api

# Enable LoadBalancer access (required for Ingress)
minikube tunnel                                   # Run in separate terminal
```

### Minikube Environment
```bash
minikube ip                                       # Get Minikube IP
minikube kubectl -- version --client              # Check kubectl version
crictl images                                     # List images (inside Minikube)
```

## Namespace Operations

```bash
# Create namespace
kubectl create namespace trocks-api

# List all namespaces
kubectl get namespaces

# Set default namespace for current context
kubectl config set-context --current --namespace=trocks-api
```

## Deployment Management

### View Resources
```bash
kubectl get deployments                           # List deployments
kubectl get pods                                  # List pods
kubectl get pods -o wide                          # List pods with node info
kubectl get services                              # List services
kubectl get ingress                               # List ingress resources
kubectl get all                                   # List all resources
```

### Describe Resources
```bash
kubectl describe pod <pod_name>                   # Pod details
kubectl describe deployment <deployment_name>     # Deployment details
kubectl describe service <service_name>           # Service details
```

### Restart Deployments
```bash
kubectl rollout restart deployment gateway-service
kubectl rollout status deployment gateway-service # Check rollout status
```

### View Logs
```bash
kubectl logs <pod_name>                           # View pod logs
kubectl logs -f <pod_name>                        # Follow pod logs
kubectl logs deployment/gateway-service           # View deployment logs

# Example
kubectl logs gateway-service-64bcf64c4f-8pcrd
```

## Secrets & ConfigMaps

### Create Secrets
```bash
# From literals
kubectl create secret generic person-service \
  --from-literal=username=trocks \
  --from-literal=password=SecurePass123

# From file
kubectl apply -f secrets.yaml
```

### View Secrets
```bash
kubectl get secrets                               # List secrets
kubectl describe secrets                          # Describe all secrets
kubectl get secrets person-service -o yaml        # View secret details
```

### ConfigMaps
```bash
kubectl get configmaps                            # List ConfigMaps
kubectl describe configmap <name>                 # ConfigMap details
```

## Service Exposure

### Expose Deployment
```bash
# Expose deployment without service file
kubectl expose deployment gateway-service \
  --type=NodePort \
  --port=8080
```

### Port Forwarding
```bash
# Forward service port to local machine
kubectl port-forward service/gateway-service 8080:80

# Forward pod port
kubectl port-forward pod/<pod_name> 8080:8080
```

## Testing & Debugging

### Test Service Connectivity
```bash
# Execute command in pod
kubectl exec -it <pod_name> -- /bin/sh
kubectl exec -it <pod_name> -- curl http://person-service/health
```

### View Events
```bash
kubectl get events --sort-by='.lastTimestamp'     # Recent events
kubectl get events -w                             # Watch events
```

### Resource Usage
```bash
kubectl top nodes                                 # Node resource usage
kubectl top pods                                  # Pod resource usage
```

## Node Management

### Drain Node
```bash
# Drain node (evict all pods for maintenance)
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data --force

# Example
kubectl drain ip-172-31-32-115.us-east-2.compute.internal --ignore-daemonsets --delete-emptydir-data --force

# Uncordon node (mark as schedulable again)
kubectl uncordon <node-name>
```

### View Nodes
```bash
kubectl get nodes                                 # List all nodes
kubectl get nodes -o wide                         # Nodes with detailed info
kubectl describe node <node-name>                 # Node details
kubectl get pods -o wide -A                       # List all pods with nodes
```

## Cleanup Operations

```bash
# Delete specific resources
kubectl delete pod <pod_name>                     # Delete pod (recreates if managed)
kubectl delete deployment person-service          # Delete deployment (stops recreation)
kubectl delete service gateway-service            # Delete service

# Delete all pods (will recreate if managed by deployment)
kubectl delete pods --all

# Delete all resources from manifests
kubectl delete -f deployment/

# Delete namespace and all resources
kubectl delete namespace trocks-api
```

## Port Configuration

### Understanding Kubernetes Ports

| Port Type | Description | Usage |
|-----------|-------------|-------|
| **port** | Port exposed by Service | Used inside the cluster |
| **targetPort** | Port inside Pod/Container | Where traffic is routed |
| **nodePort** | Port exposed on all node IPs | External access (dev/testing) |
| **endpoints** | Real pod IPs/ports | Set by Kubernetes automatically |

### Traffic Flow Patterns

**Direct NodePort Access:**
```
User (browser)
  ↓
<NodeIP>:30080 (NodePort)
  ↓
Service:80 (ClusterIP)
  ↓
Pod:8080 (TargetPort)
```

**With Ingress (Production):**
```
Client
  ↓
Ingress
  ↓
Gateway Service (80 → 8080)
  ↓
Gateway Pod
  ↓
http://person-service:80
  ↓
person-service Pod (8080)
```

## Accessing Services via Ingress

### Prerequisites
1. Enable ingress addon: `minikube addons enable ingress`
2. Run `minikube tunnel` in a separate terminal
3. Add host mapping to `/etc/hosts`:
   ```
   127.0.0.1 api.localhost
   ```

### Test Endpoints
```bash
# Gateway endpoints
curl http://api.localhost/health
curl http://api.localhost/ucase

# Routed services
curl http://api.localhost/person/health
curl http://api.localhost/address/health
curl http://api.localhost/config/person-service/kubernetes
```

## Common Issues & Solutions

### ImagePullBackOff Error
**Problem:** Kubernetes can't find the Docker image

**Solution:**
```bash
# Build images in Minikube's Docker environment
eval $(minikube docker-env)
docker compose build
```

### Ingress Not Working
**Problem:** Can't access services via Ingress

**Solution:**
```bash
# Ensure ingress addon is enabled
minikube addons enable ingress

# Run tunnel in separate terminal
minikube tunnel

# Add host to /etc/hosts
echo "127.0.0.1 api.localhost" | sudo tee -a /etc/hosts
```

### Service Discovery Failing
**Problem:** Services can't discover each other

**Solution:**
- Check service labels match discovery configuration
- Verify RBAC permissions (ServiceAccount, ClusterRole)
- Ensure services are in correct namespace

## Notes

- **crictl** - Command-line interface for CRI-compatible container runtimes. Used to inspect and debug containers on Kubernetes nodes.
- **Auto-scaling** - Pods can scale automatically based on CPU/memory usage. Configure HPA in deployment.yml.
- **Persistent Data** - Minikube data persists between stops but is lost on delete.

## References

- [Minikube Documentation](https://minikube.sigs.k8s.io/docs/)
- [Kubernetes Secrets Management](https://spacelift.io/blog/kubernetes-secrets)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
