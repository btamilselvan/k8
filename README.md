# Spring Cloud Kubernetes Integration Demo

A comprehensive demonstration of Spring Cloud capabilities with Kubernetes integration, showcasing microservices architecture, service discovery, configuration management, and API gateway patterns.

## Project Overview

This repository demonstrates enterprise-grade Spring Cloud features integrated with Kubernetes, including:

- **API Gateway** with Spring Cloud Gateway WebFlux
- **Service Discovery** using Kubernetes native discovery
- **Configuration Management** with Spring Cloud Config Server
- **Inter-service Communication** using OpenFeign clients
- **Multi-environment Support** (Local, Docker Compose, Kubernetes)
- **Load Balancing** with Spring Cloud LoadBalancer

## Architecture

```
┌─────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Ingress   │───▶│  Gateway Service │───▶│  Person Service │
│  (NGINX)    │    │   (Port 8080)    │    │   (Port 8080)   │
└─────────────┘    └──────────┬───────┘    └─────────┬───────┘
                            │                      │
                            ▼                      │
                   ┌─────────────────┐             │
                   │ Address Service │             │
                   │   (Port 8080)   │             │
                   └─────────┬───────┘             │
                            │                      │
                            ▼                      ▼
                   ┌──────────────────┐    ┌──────────────────┐
                   │ Config Server    │    | Address Service  │
                   │   (Port 8888)    │    │   (Port 8080)    │
                   └──────────────────┘    └──────────────────┘
```

## Detailed Request Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           Kubernetes Cluster                               │
│  ┌─────────────┐                                                           │
│  │   Browser   │                                                           │
│  │   Request   │                                                           │
│  └──────┬──────┘                                                           │
│         │ HTTP Request                                                      │
│         ▼                                                                  │
│  ┌─────────────┐                                                           │
│  │   Ingress   │ ◀── External LoadBalancer (NodePort/LoadBalancer)        │
│  │ Controller  │                                                           │
│  │   (NGINX)   │                                                           │
│  └──────┬──────┘                                                           │
│         │ Routes based on path/host                                        │
│         ▼                                                                  │
│  ┌─────────────┐                                                           │
│  │ K8s Service │ ◀── ClusterIP (Internal Load Balancer)                   │
│  │ gateway-svc │                                                           │
│  │  (Port 80)  │                                                           │
│  └──────┬──────┘                                                           │
│         │ Load balances to available pods                                  │
│         ▼                                                                  │
│  ┌─────────────┐     ┌─────────────┐                                      │
│  │Gateway Pod 1│     │Gateway Pod 2│ ◀── Multiple replicas               │
│  │             │     │             │                                      │
│  │ ┌─────────┐ │     │ ┌─────────┐ │                                      │
│  │ │Container│ │     │ │Container│ │ ◀── Spring Boot App                 │
│  │ │Port 8080│ │     │ │Port 8080│ │                                      │
│  │ └─────────┘ │     │ └─────────┘ │                                      │
│  └──────┬──────┘     └─────────────┘                                      │
│         │ Spring Cloud Gateway routes request                             │
│         ▼                                                                  │
│  ┌─────────────┐                                                           │
│  │ K8s Service │ ◀── Internal service discovery (lb://person-service)     │
│  │ person-svc  │                                                           │
│  │  (Port 80)  │                                                           │
│  └──────┬──────┘                                                           │
│         │ Routes to person service pods                                    │
│         ▼                                                                  │
│  ┌─────────────┐     ┌─────────────┐                                      │
│  │Person Pod 1 │     │Person Pod 2 │ ◀── Auto-scaled replicas            │
│  │             │     │             │                                      │
│  │ ┌─────────┐ │     │ ┌─────────┐ │                                      │
│  │ │Container│ │     │ │Container│ │ ◀── Business Logic                  │
│  │ │Port 8080│ │     │ │Port 8080│ │                                      │
│  │ └─────────┘ │     │ └─────────┘ │                                      │
│  └─────────────┘     └─────────────┘                                      │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Services

### Gateway Service
- **Spring Cloud Gateway WebFlux** for reactive routing
- **Path-based routing** with rewrite filters
- **Load balancing** using `lb://` URIs
- **Function endpoints** (uppercase, concat)
- **Health checks** and actuator endpoints

### Person Service
- **OpenFeign client** for inter-service communication
- **Circuit breaker** integration
- **Service discovery** client
- **REST API** endpoints

### Address Service
- **Downstream microservice** with business logic
- **Multiple replicas** for load balancing
- **Health check** endpoints

### Config Server
- **Centralized configuration** management
- **Multi-backend support** (Native, Git, Kubernetes)
- **Profile-based** configuration
- **Environment-specific** properties

## Key Features

### Service Discovery
- **Kubernetes Native Discovery** - Auto-discovers services using labels
- **Spring Cloud LoadBalancer** - Request-level load balancing
- **Multi-environment URLs** - Different discovery mechanisms per environment

### Configuration Management
- **Spring Cloud Config Server** with multiple backends:
  - **Native** - Local file-based configuration
  - **Git** - Remote repository with versioning
  - **Kubernetes** - ConfigMaps and Secrets integration

### API Gateway Capabilities
- **Reactive Routing** with WebFlux
- **Path Rewriting** - Strips service prefixes
- **Load Balancing** - Distributes requests across replicas
- **Function Endpoints** - Serverless-style functions
- **CORS Support** and security filters

### Multi-Environment Support
| Environment | Service Discovery | Configuration | Deployment |
|-------------|------------------|---------------|------------|
| **Local** | `localhost:port` | File-based | JAR execution |
| **Docker** | Service names | Config server | Docker Compose |
| **Kubernetes** | `lb://service` | ConfigMaps | K8s deployments |

## Quick Start

### Prerequisites
- Java 21
- Maven 3.8+
- Docker & Docker Compose
- Kubernetes cluster (Minikube/Kind)

### Local Development
```bash
# Build all services
mvn clean package -DskipTests

# Start services in order
java -jar cloud-config-server/target/cloud-config-server-1.0-SNAPSHOT.jar --spring.profiles.active=local
java -jar address-service/target/address-service-1.0-SNAPSHOT.jar --spring.profiles.active=local
java -jar person-service/target/person-service-1.0-SNAPSHOT.jar --spring.profiles.active=local
java -jar gateway-service/target/gateway-service-1.0-SNAPSHOT.jar --spring.profiles.active=local
```

### Docker Compose
```bash
cd spring-cloud-k8
docker compose build
docker compose up -d
```

### Kubernetes Deployment
```bash
# Build images for Minikube
eval $(minikube docker-env)
cd spring-cloud-k8
docker compose build

# Deploy to Kubernetes
cd ../deployment
kubectl apply -f .
```

## Kubernetes Deployment Scripts

The `k8/deployment/` directory contains comprehensive Kubernetes manifests:

### Core Deployment Files
- **`deployment.yml`** - Deployments for all services (gateway, person, address, config-server)
- **`service.yml`** - Kubernetes Services for internal communication
- **`ingress.yml`** - NGINX Ingress for external access
- **`access-control.yml`** - RBAC configuration (ServiceAccount, ClusterRole, ClusterRoleBinding)
- **`secrets_configmap.yml`** - ConfigMaps and Secrets for configuration
- **`secrets.yml`** - Additional secrets management

### Deployment Features
- **Multi-replica deployments** - Gateway (2), Person (2), Address (2), Config (1)
- **RBAC permissions** - ServiceAccount `gateway-trocks-account` for K8s API access
- **Environment profiles** - `dev,kubernetes` for all services
- **Service discovery labels** - Auto-discovery configuration
- **Health checks** - Liveness and readiness probes
- **Resource management** - CPU/memory limits and requests
- **Auto-scaling** - Pods scale based on CPU/memory usage (configure in deployment.yml)

### Port Configuration
- **port** - Port exposed by Service (used inside cluster)
- **targetPort** - Port inside Pod/Container (where traffic is routed)
- **nodePort** - Port exposed on all node IPs (external access for dev/testing)
- **endpoints** - Real pod IPs/ports receiving traffic (set by Kubernetes automatically)

### Traffic Flow

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

### Deployment Commands
```bash
# Apply all manifests
kubectl apply -f deployment/

# Apply specific components
kubectl apply -f deployment/access-control.yml
kubectl apply -f deployment/secrets_configmap.yml
kubectl apply -f deployment/deployment.yml
kubectl apply -f deployment/service.yml
kubectl apply -f deployment/ingress.yml

# Verify deployment
kubectl get pods,svc,ingress
kubectl get endpoints
```

## Useful Kubernetes Commands

### Minikube Management
```bash
minikube start                                    # Start Minikube cluster
minikube ssh                                      # SSH into Minikube environment
crictl images                                     # List container images (inside Minikube)
minikube dashboard                                # Open Kubernetes dashboard
minikube addons enable ingress                    # Enable NGINX Ingress controller
minikube stop                                     # Stop Minikube cluster
```

### Docker Environment
```bash
eval $(minikube docker-env)                       # Point Docker to Minikube's Docker engine
eval $(minikube docker-env -u)                    # Revert to local Docker
```

### Namespace Operations
```bash
kubectl create namespace trocks-api              # Create namespace
kubectl get namespaces                            # List all namespaces
```

### Deployment & Pod Management
```bash
kubectl -n trocks-api get deployments            # List deployments
kubectl -n trocks-api get pods                   # List pods
kubectl -n trocks-api describe pod <pod_name>    # Pod details
kubectl -n trocks-api get services               # List services
kubectl rollout restart deployment person-service # Restart deployment
kubectl logs <pod_name> -n trocks-api            # View pod logs
```

### Secrets Management
```bash
kubectl -n trocks-api apply -f secrets.yaml      # Apply secrets from file
kubectl create secret generic person-service --from-literal=username=user --from-literal=password=pass
kubectl -n trocks-api get secrets                # List secrets
kubectl -n trocks-api describe secrets           # Describe secrets
kubectl get secrets person-service -o yaml        # View secret details
```

### Service Exposure & Testing
```bash
minikube service ordering-service -n trocks-api   # Test service locally
kubectl expose deployment ordering-service --type=NodePort --port=8080  # Expose without service file
```

### Cleanup Operations
```bash
kubectl delete pods --all                         # Delete all pods (will recreate if managed)
kubectl delete deployment person-service          # Delete deployment (stops recreation)
```

## API Endpoints

### Gateway Service (Port 8080)
- `GET /health` - Gateway health check
- `POST /concat1` - String concatenation function
- `GET /ucase` - Uppercase transformation function
- `GET /actuator/**` - Management endpoints

### Routed Services
- `GET /person/**` - Routes to person-service
- `GET /address/**` - Routes to address-service
- `GET /config/**` - Routes to config-server

### Example Requests
```bash
# Gateway functions
curl http://localhost:8080/health
curl -X POST http://localhost:8080/concat1 -d "Hello World"

# Routed requests
curl http://localhost:8080/person/health
curl http://localhost:8080/address/health
curl http://localhost:8080/config/person-service/kubernetes
```

## Configuration Profiles

### Spring Profiles
- **local** - Local development with localhost URLs
- **docker** - Docker Compose with service names
- **kubernetes** - K8s with service discovery
- **dev/qa/prod** - Environment-specific configurations

### Config Server Backends
- **Native** - `spring.profiles.active=native`
- **Git** - `spring.cloud.config.server.git.uri=...`
- **Kubernetes** - `spring.cloud.kubernetes.config.enabled=true`

## Kubernetes Integration

### Service Discovery
```yaml
# Automatic service discovery with labels
metadata:
  labels:
    discovery-enabled: "true"
```

### RBAC Configuration
```yaml
# ServiceAccount for accessing K8s API
apiVersion: v1
kind: ServiceAccount
metadata:
  name: gateway-trocks-account
```

### Ingress Configuration
```yaml
# NGINX Ingress for external access
spec:
  ingressClassName: nginx
  rules:
    - http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: gateway-service
                port:
                  number: 80
```

## Load Balancing Strategy

### Multiple Layers
1. **Kubernetes Service** - L4 load balancing (kube-proxy)
2. **Ingress Controller** - HTTP routing and SSL termination
3. **Spring Cloud Gateway** - API routing and filters
4. **Spring Cloud LoadBalancer** - Request-level distribution

### Service URLs by Environment
| Environment | URL Format | Example |
|-------------|------------|---------|
| Local | `http://localhost:port` | `http://localhost:8081` |
| Docker | `http://service-name:port` | `http://person-service:8080` |
| Kubernetes | `lb://service-name` | `lb://person-service` |

## Monitoring & Management

### Health Checks
- **Liveness probes** for container health
- **Readiness probes** for traffic routing
- **Custom health indicators** per service

### Actuator Endpoints
- `/actuator/health` - Service health status
- `/actuator/info` - Application information
- `/actuator/metrics` - Performance metrics
- `/actuator/env` - Environment properties

## Development Workflow

### Building Services
```bash
# Build specific service
mvn clean package -pl gateway-service -am -DskipTests

# Build all services
mvn clean package -DskipTests
```

### Testing
```bash
# Run tests
mvn test

# Integration tests
mvn verify -Pintegration-tests
```

### Docker Images
```bash
# Build images
docker compose build

# Push to registry
docker tag gateway-service:latest your-registry/gateway-service:v1.0
docker push your-registry/gateway-service:v1.0
```

## Key Dependencies

### Gateway Service
- `spring-cloud-starter-gateway-server-webflux`
- `spring-cloud-starter-kubernetes-client`
- `spring-cloud-starter-loadbalancer`
- `spring-boot-starter-actuator`

### Person Service
- `spring-cloud-starter-openfeign`
- `spring-cloud-starter-kubernetes-client`
- `spring-boot-starter-web`

### Config Server
- `spring-cloud-config-server`
- `spring-cloud-starter-kubernetes-config`

## Best Practices Demonstrated

### Configuration Management
- **Externalized configuration** using Config Server
- **Environment-specific profiles** for different deployments
- **Secrets management** with Kubernetes Secrets

### Service Communication
- **Declarative REST clients** with OpenFeign
- **Circuit breaker patterns** for resilience
- **Load balancing** across service instances

### Kubernetes Integration
- **Native service discovery** without external dependencies
- **RBAC permissions** for secure API access
- **Health checks** for proper lifecycle management

### Observability
- **Structured logging** with correlation IDs
- **Metrics collection** via Actuator
- **Health monitoring** at multiple levels

## Troubleshooting

### Common Issues
1. **Service Discovery** - Ensure proper RBAC permissions
2. **Config Server** - Verify profile activation and backend configuration
3. **Load Balancing** - Check service labels and discovery settings
4. **Ingress** - Validate ingress controller and DNS resolution

### Debug Commands
```bash
# Check service discovery
kubectl get endpoints

# View service logs
kubectl logs -f deployment/gateway-service

# Test service connectivity
kubectl exec -it pod-name -- curl http://service-name/health
```

## References
- [Spring Cloud Gateway](https://docs.spring.io/spring-cloud-gateway/docs/current/reference/html/)
- [Spring Cloud Kubernetes](https://docs.spring.io/spring-cloud-kubernetes/docs/current/reference/html/)
- [Spring Cloud Config](https://docs.spring.io/spring-cloud-config/docs/current/reference/html/)
- [Spring Cloud OpenFeign](https://docs.spring.io/spring-cloud-openfeign/docs/current/reference/html/)