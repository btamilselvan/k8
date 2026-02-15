# Production-Grade Kubernetes on AWS EKS

A comprehensive reference implementation demonstrating production-grade Kubernetes deployment on AWS EKS with Spring Boot microservices, automated GitOps workflows, and infrastructure as code.

## 📖 Documentation
For a high-level overview, stay here. For technical deep dives, architecture diagrams, and advanced configuration, please see our [Detailed Documentation](./README-detail.md).

## 🎯 Project Overview

This project showcases a complete end-to-end implementation of:
- **Production-grade EKS cluster** with Terraform
- **Spring Boot microservices** with service discovery and configuration management
- **GitOps deployment** using ArgoCD
- **Auto-scaling** with HPA and Karpenter
- **Multi-environment support** (local, Docker, Kubernetes)

## 📁 Repository Structure

```
k8/
├── spring-cloud-k8/              # Spring Boot microservices
│   ├── gateway-service/          # API Gateway with routing
│   ├── person-service/           # Demo service with Feign client
│   ├── address-service/          # Downstream service
│   └── cloud-config-server/      # Centralized configuration
├── deployment/                   # Kubernetes deployment configurations
│   ├── cloud/                    # Cloud-specific configs
│   │   ├── infrastructure/       # Terraform IaC for EKS
│   │   └── argocd/              # ArgoCD configurations
│   ├── minikube/                # Local Kubernetes manifests
│   └── helm/                    # Helm charts
├── docker-files/                # Docker configurations
└── api-testing/                 # API test scripts
```

## 🏗️ Architecture

### High-Level Architecture

```
Internet
   ↓
Route 53 (DNS)
   ↓
AWS WAF (Security)
   ↓
Application Load Balancer
   ↓
Kubernetes Ingress
   ↓
Spring Cloud Gateway
   ↓
Microservices (Person, Address, Config)
   ↓
AWS Services (RDS, ElastiCache, etc.)
```

### EKS Cluster Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    EKS Control Plane                    │
│  (AWS-managed: API Server, Scheduler, etcd, Controllers)│
└─────────────────────────────────────────────────────────┘
                   ▲                      ▲
                   │                      │
        ┌──────────┘                      └───────────┐
        │                                               │
        ▼                                               ▼
 ┌───────────────┐                           ┌────────────────┐
 │  System Node  │                           │   App Node     │
 │   Group       │                           │   Group(s)     │
 │ (tainted)     │                           │ (untainted)    │
 │---------------│                           │----------------│
 │ CoreDNS       │                           │ gateway-service│
 │ kube-proxy    │                           │ person-service │
 │ VPC CNI       │                           │ address-service│
 │ ALB Controller│                           │ config-server  │
 │ MetricsServer │                           │ HA replicas    │
 │ Karpenter     │                           │                │
 └───────────────┘                           └────────────────┘
```

## 🚀 Key Features

### Infrastructure (Terraform)
- **EKS Cluster** with managed node groups
- **VPC Configuration** with public/private subnets
- **IAM Roles & Policies** with least privilege
- **Karpenter** for intelligent node provisioning
- **AWS Load Balancer Controller** for ingress
- **EKS Pod Identity** for secure AWS access
- **Private API endpoint** for enhanced security

### Microservices (Spring Boot)
- **Spring Cloud Gateway** - Reactive API gateway with routing and load balancing
- **Service Discovery** - Kubernetes-native service discovery
- **Configuration Management** - Centralized config with Spring Cloud Config
- **Multi-Environment Support** - Local, Docker, and Kubernetes profiles
- **Feign Clients** - Declarative HTTP clients for inter-service communication
- **Health Checks** - Built-in health endpoints for monitoring

### GitOps & Deployment
- **ArgoCD** - Declarative GitOps continuous delivery
- **App of Apps Pattern** - Hierarchical application management
- **Automated Sync** - Self-healing and auto-sync policies
- **Helm Charts** - Reusable templates for microservices
- **CI/CD Integration** - Automated image tag updates

### Auto-Scaling
- **Horizontal Pod Autoscaler (HPA)** - Scales pods based on CPU/memory
- **Karpenter** - Intelligent node provisioning and scaling
- **NodePool & NodeClass** - Fine-grained node configuration
- **PodDisruptionBudget** - Ensures availability during updates

### Security
- **IAM Roles for Service Accounts (IRSA)** - Fine-grained AWS permissions
- **EKS Pod Identity** - Secure pod-to-AWS authentication
- **RBAC** - Kubernetes role-based access control
- **Private API Server** - Control plane in private network
- **Secrets Management** - Kubernetes secrets and AWS Secrets Manager
- **Network Policies** - Pod-to-pod communication control

## 📚 Documentation

### Core Documentation
- **[Deployment Guide](deployment/README.md)** - Comprehensive EKS deployment guide with architecture details
- **[Spring Cloud Microservices](spring-cloud-k8/README.md)** - Spring Boot microservices architecture and configuration
- **[ArgoCD Setup](../argocd-trocks-apps/README.md)** - GitOps deployment with App of Apps pattern

### Service Documentation
- **[Gateway Service](spring-cloud-k8/gateway-service/README.md)** - API Gateway configuration and routing
- **[Person Service](spring-cloud-k8/person-service/README.md)** - Service discovery and Feign client usage
- **[Address Service](spring-cloud-k8/address-service/README.md)** - Config client with fail-fast and retry
- **[Config Server](spring-cloud-k8/cloud-config-server/README.md)** - Centralized configuration management

## 🛠️ Technology Stack

### Infrastructure
- **AWS EKS** - Managed Kubernetes service
- **Terraform** - Infrastructure as Code
- **Karpenter** - Kubernetes node autoscaler
- **AWS Load Balancer Controller** - Ingress controller

### Application
- **Java 17** - Programming language
- **Spring Boot 3.x** - Application framework
- **Spring Cloud Gateway** - API Gateway
- **Spring Cloud Kubernetes** - Service discovery
- **Spring Cloud Config** - Configuration management
- **Spring Cloud OpenFeign** - HTTP client

### DevOps
- **ArgoCD** - GitOps continuous delivery
- **Helm** - Kubernetes package manager
- **Docker** - Container runtime
- **Maven** - Build tool

### Monitoring & Observability
- **Spring Boot Actuator** - Application metrics
- **Kubernetes Metrics Server** - Resource metrics
- **CloudWatch** - AWS monitoring (optional)

## 🚦 Getting Started

### Prerequisites
- AWS Account with appropriate permissions
- AWS CLI configured
- kubectl installed
- Terraform installed
- Docker installed
- Java 17 installed
- Maven installed

### Quick Start

#### 1. Build Microservices
```bash
cd spring-cloud-k8
mvn clean package -DskipTests
```

#### 2. Local Development
```bash
# Start services locally
java -jar cloud-config-server/target/cloud-config-server-1.0-SNAPSHOT.jar --spring.profiles.active=local
java -jar address-service/target/address-service-1.0-SNAPSHOT.jar --spring.profiles.active=local
java -jar person-service/target/person-service-1.0-SNAPSHOT.jar --spring.profiles.active=local
java -jar gateway-service/target/gateway-service-1.0-SNAPSHOT.jar --spring.profiles.active=local
```

#### 3. Docker Compose
```bash
cd spring-cloud-k8
docker compose build
docker compose up -d
```

#### 4. Deploy to EKS
```bash
# Deploy infrastructure with Terraform
cd deployment/cloud/infrastructure
terraform init
terraform plan
terraform apply

# Deploy applications with ArgoCD
# See argocd-trocks-apps repository for details
```

### Testing the Deployment

```bash
# Test gateway health
curl http://localhost:8080/health

# Test routed services
curl http://localhost:8080/person/health
curl http://localhost:8080/address/health
curl http://localhost:8080/config/person-service/kubernetes
```

## 📖 Key Concepts Explained

### EKS Control Plane
The EKS control plane is AWS-managed and includes:
- **API Server** - Front door for all cluster operations
- **etcd** - Distributed key-value store for cluster state
- **Scheduler** - Assigns pods to nodes
- **Controller Manager** - Runs controllers for deployments, services, etc.

**Important**: Worker nodes initiate connections to the control plane, not vice versa.

### Service Discovery
Three approaches demonstrated:
1. **Kubernetes DNS** - `http://service-name:port` (L4 load balancing)
2. **Spring Cloud LoadBalancer** - `lb://service-name` (L7 load balancing)
3. **Direct URLs** - `http://service.namespace.svc.cluster.local:port`

### Configuration Management
Multiple backends supported:
- **Local (Native)** - Filesystem-based for development
- **Git** - Remote repository for version control
- **Kubernetes** - ConfigMaps and Secrets for cloud-native

### Auto-Scaling Flow
```
Traffic Increases
   ↓
HPA scales pods
   ↓
No node capacity
   ↓
Karpenter provisions new nodes
   ↓
Pods scheduled on new nodes
```

### GitOps Workflow
```
Code Change
   ↓
CI builds Docker image
   ↓
CI updates image tag in Git
   ↓
ArgoCD detects change
   ↓
ArgoCD syncs to cluster
   ↓
New version deployed
```

## 🔄 Detailed Request Flow

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
│  │   Ingress   │ ◀── External LoadBalancer (ALB/NLB)                      │
│  │ Controller  │                                                           │
│  │   (AWS ALB) │                                                           │
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

## 🌐 Kubernetes DNS & Service Discovery

### DNS Resolution in Kubernetes

Kubernetes provides automatic DNS resolution for services within the cluster:

#### DNS Naming Convention
```
<service-name>.<namespace>.svc.cluster.local
```

#### Service DNS Examples
| Service | Short Name | Full DNS Name |
|---------|------------|---------------|
| Gateway Service | `gateway-service` | `gateway-service.default.svc.cluster.local` |
| Person Service | `person-service` | `person-service.default.svc.cluster.local` |
| Address Service | `address-service` | `address-service.default.svc.cluster.local` |
| Config Server | `cloud-config-server` | `cloud-config-server.default.svc.cluster.local` |

#### DNS Resolution Hierarchy
1. **Same Namespace**: `service-name` (short name)
2. **Cross Namespace**: `service-name.namespace`
3. **Full FQDN**: `service-name.namespace.svc.cluster.local`
4. **External**: External DNS resolution

### Load Balancing Strategy

#### Multiple Layers
1. **Kubernetes Service** - L4 load balancing (kube-proxy)
2. **Ingress Controller** - HTTP routing and SSL termination
3. **Spring Cloud Gateway** - API routing and filters
4. **Spring Cloud LoadBalancer** - Request-level distribution

#### Service URLs by Environment
| Environment | URL Format | Example |
|-------------|------------|---------|
| Local | `http://localhost:port` | `http://localhost:8081` |
| Docker | `http://service-name:port` | `http://person-service:8080` |
| Kubernetes | `lb://service-name` | `lb://person-service` |

## 📦 Kubernetes Deployment

### Deployment Files Structure

The `deployment/` directory contains comprehensive Kubernetes manifests:

#### Core Deployment Files
- **`deployment.yml`** - Deployments for all services (gateway, person, address, config-server)
- **`service.yml`** - Kubernetes Services for internal communication
- **`ingress.yml`** - Ingress for external access
- **`access-control.yml`** - RBAC configuration (ServiceAccount, ClusterRole, ClusterRoleBinding)
- **`secrets_configmap.yml`** - ConfigMaps and Secrets for configuration

#### Deployment Features
- **Multi-replica deployments** - Gateway (2), Person (2), Address (2), Config (1)
- **RBAC permissions** - ServiceAccount for K8s API access
- **Environment profiles** - `dev,kubernetes` for all services
- **Service discovery labels** - Auto-discovery configuration
- **Health checks** - Liveness and readiness probes
- **Resource management** - CPU/memory limits and requests
- **Auto-scaling** - HPA configuration for pod scaling

### Port Configuration
- **port** - Port exposed by Service (used inside cluster)
- **targetPort** - Port inside Pod/Container (where traffic is routed)
- **nodePort** - Port exposed on all node IPs (external access for dev/testing)
- **endpoints** - Real pod IPs/ports receiving traffic (set by Kubernetes automatically)

### Traffic Flow Patterns

**Direct NodePort Access (Development):**
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
Ingress (ALB)
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

## 🛠️ Useful Commands

### Minikube Management (Local Development)
```bash
minikube start                                    # Start Minikube cluster
minikube tunnel                                   # Enable LoadBalancer access (required for Ingress)
minikube ssh                                      # SSH into Minikube environment
crictl images                                     # List container images (inside Minikube)
minikube dashboard                                # Open Kubernetes dashboard
minikube addons enable ingress                    # Enable NGINX Ingress controller
minikube addons enable metrics-server             # Enable metrics for HPA
minikube stop                                     # Stop Minikube cluster
```

### Docker Environment (Minikube)
```bash
eval $(minikube docker-env)                       # Point Docker to Minikube's Docker engine
eval $(minikube docker-env -u)                    # Revert to local Docker
```

**Important:** Docker images must be built within Minikube's Docker environment using `eval $(minikube docker-env)` before deployment. Otherwise, Kubernetes deployments will fail with "ImagePullBackOff" or "ErrImagePull" errors.

### Namespace Operations
```bash
kubectl create namespace trocks-api              # Create namespace
kubectl get namespaces                            # List all namespaces
kubectl config set-context --current --namespace=trocks-api  # Set default namespace
```

### Deployment & Pod Management
```bash
kubectl get deployments                          # List deployments
kubectl get pods                                 # List pods
kubectl get pods -o wide                         # List pods with node info
kubectl describe pod <pod_name>                  # Pod details
kubectl get services                             # List services
kubectl get endpoints                            # View service endpoints
kubectl rollout restart deployment person-service # Restart deployment
kubectl rollout status deployment person-service  # Check rollout status
kubectl logs <pod_name>                          # View pod logs
kubectl logs -f <pod_name>                       # Follow pod logs
kubectl exec -it <pod_name> -- /bin/sh          # Shell into pod
```

### Secrets & ConfigMaps Management
```bash
kubectl apply -f secrets.yaml                    # Apply secrets from file
kubectl create secret generic person-service --from-literal=username=user --from-literal=password=pass
kubectl get secrets                              # List secrets
kubectl describe secrets                         # Describe secrets
kubectl get secrets person-service -o yaml       # View secret details
kubectl get configmaps                           # List ConfigMaps
kubectl describe configmap <name>                # ConfigMap details
```

### Service Testing & Debugging
```bash
kubectl port-forward service/gateway-service 8080:80  # Port forward to local
kubectl exec -it <pod_name> -- curl http://service-name/health  # Test service connectivity
kubectl get events --sort-by='.lastTimestamp'    # View recent events
kubectl top pods                                 # View pod resource usage
kubectl top nodes                                # View node resource usage
```

### Cleanup Operations
```bash
kubectl delete pods --all                        # Delete all pods (will recreate if managed)
kubectl delete deployment person-service         # Delete deployment (stops recreation)
kubectl delete -f deployment/                    # Delete all resources from manifests
kubectl delete namespace trocks-api              # Delete namespace and all resources
```

### EKS-Specific Commands
```bash
# Update kubeconfig for EKS
aws eks update-kubeconfig --name trocks-cluster --region us-east-2

# Update kubeconfig with IAM role
aws eks update-kubeconfig --name trocks-cluster --region us-east-2 --role-arn <role-arn>

# List EKS clusters
aws eks list-clusters --region us-east-2

# Describe cluster
aws eks describe-cluster --name trocks-cluster --region us-east-2
```

## 🧪 API Testing

### Gateway Service Endpoints
```bash
# Gateway functions
curl http://localhost:8080/health
curl -X POST http://localhost:8080/concat1 -d "Hello World"
curl http://localhost:8080/ucase

# Routed requests
curl http://localhost:8080/person/health
curl http://localhost:8080/address/health
curl http://localhost:8080/config/person-service/kubernetes
```

### Accessing Services via Ingress (Minikube)

**Prerequisites:**
1. Run `minikube tunnel` in a separate terminal (required for LoadBalancer access)
2. Add host mapping to `/etc/hosts`:
   ```
   127.0.0.1 api.localhost
   ```

**API Access Examples:**
```bash
# Gateway endpoints
curl http://api.localhost/health
curl http://api.localhost/ucase

# Routed services
curl http://api.localhost/person/health
curl http://api.localhost/address/health
curl http://api.localhost/config/person-service/kubernetes
```

**Note:** `minikube tunnel` must be running to access Ingress endpoints. Without it, LoadBalancer services remain in "Pending" stateuilds Docker image
   ↓
CI updates image tag in Git
   ↓
ArgoCD detects change
   ↓
ArgoCD syncs to cluster
   ↓
New version deployed
```

## 🔐 Security Best Practices

### IAM & Authentication
- Use EKS Pod Identity for AWS service access
- Implement least-privilege IAM policies
- Use RBAC for Kubernetes access control
- Map IAM roles to Kubernetes groups via access entries

### Network Security
- Private API server endpoint
- Security groups for pods
- Network policies for pod-to-pod communication
- WAF for external traffic filtering

### Secrets Management
- Use Kubernetes Secrets for sensitive data
- Consider AWS Secrets Manager for external secrets
- Enable encryption at rest for etcd
- Never commit secrets to Git

### Node Security
- Taint system nodes to isolate workloads
- Use separate node groups for system and app pods
- Enable encryption for EBS volumes
- Regular security patches and updates

## 📊 Monitoring & Operations

### Health Checks
All services expose health endpoints:
- Gateway: `http://gateway:8080/health`
- Person: `http://person-service:8080/health`
- Address: `http://address-service:8080/health`
- Config: `http://cloud-config-server:8888/actuator/health`

### Useful kubectl Commands
```bash
# View all resources
kubectl get all -n default

# Check pod logs
kubectl logs -f deployment/gateway-service

# Describe pod for troubleshooting
kubectl describe pod <pod-name>

# Check HPA status
kubectl get hpa

# View Karpenter nodes
kubectl get nodeclaim
kubectl get nodepool
```

### ArgoCD Management
```bash
# Login to ArgoCD
argocd login <alb-endpoint> --grpc-web --username admin

# List applications
argocd app list --grpc-web

# Sync application
argocd app sync gateway-service --grpc-web

# View application details
argocd app get gateway-service --grpc-web
```

## 🎓 Learning Resources

### Kubernetes Fundamentals
- Control plane components and their roles
- Pod lifecycle and scheduling
- Services and networking
- ConfigMaps and Secrets
- RBAC and security

### EKS-Specific
- Managed vs self-managed node groups
- EKS Pod Identity
- AWS Load Balancer Controller
- VPC CNI networking
- Karpenter node provisioning

### Spring Cloud
- Service discovery patterns
- API Gateway routing
- Configuration management
- Feign clients
- Load balancing strategies

### GitOps
- Declarative infrastructure
- Git as single source of truth
- ArgoCD App of Apps pattern
- Automated sync and self-healing
- Helm chart management

## 🔧 Troubleshooting

### Common Issues

**Pods not scheduling**
- Check node capacity: `kubectl describe nodes`
- Verify taints and tolerations
- Check resource requests/limits

**Service discovery failing**
- Verify service labels match discovery config
- Check RBAC permissions
- Ensure services are in correct namespace

**Configuration not loading**
- Verify Config Server is running
- Check fail-fast and retry settings
- Validate profile activation

**Karpenter not provisioning nodes**
- Check NodePool and NodeClass configuration
- Verify IAM permissions
- Review Karpenter logs: `kubectl logs -n karpenter -l app.kubernetes.io/name=karpenter`

## 🤝 Contributing

This is a reference implementation for learning purposes. Feel free to:
- Fork and experiment
- Adapt for your use cases
- Share improvements and feedback

## 📝 Notes

### Important Considerations
- **etcd** stores all cluster state - protect it carefully
- **Kubernetes is eventually consistent** - not continuously dependent
- **Control plane never initiates connections** to worker nodes
- **Taints and tolerations** are key to workload isolation
- **Always use PodDisruptionBudgets** for production workloads

### Best Practices
- Never run production services with 1 replica
- Use separate node groups for system and application pods
- Implement proper RBAC policies
- Enable encryption at rest and in transit
- Use GitOps for all deployments
- Monitor resource usage and set appropriate limits

## 📚 References

### AWS Documentation
- [Amazon EKS User Guide](https://docs.aws.amazon.com/eks/)
- [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
- [Karpenter Documentation](https://karpenter.sh/)

### Kubernetes
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Kubernetes Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)

### Spring Cloud
- [Spring Cloud Kubernetes](https://cloud.spring.io/spring-cloud-kubernetes/)
- [Spring Cloud Gateway](https://docs.spring.io/spring-cloud-gateway/)
- [Spring Cloud Config](https://docs.spring.io/spring-cloud-config/)

### GitOps
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Helm Documentation](https://helm.sh/docs/)

## 📄 License

This project is for educational and reference purposes.

---

**Built with ❤️ for learning Kubernetes, EKS, and Cloud-Native architectures**
