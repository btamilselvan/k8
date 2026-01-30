# EKS Infrastructure Automation

Complete Terraform infrastructure for deploying production-ready EKS clusters with ArgoCD, ALB Controller, and CI/CD pipelines.

## Architecture

This infrastructure creates a fully automated Kubernetes environment with:

- **EKS Cluster** - Managed Kubernetes cluster with worker nodes
- **VPC & Networking** - Secure network configuration (optional module)
- **IAM Roles & Policies** - Proper access controls and service accounts
- **ALB Controller** - AWS Load Balancer Controller for ingress
- **ArgoCD** - GitOps continuous deployment
- **CI/CD Pipeline** - ECR repositories and build automation
- **SSL/TLS** - Automatic certificate management

## Project Structure

```
infrastructure/
├── modules/
│   ├── vpc/              # VPC, subnets, security groups
│   ├── iam/              # IAM roles and policies
│   ├── eks/              # EKS cluster and node groups
│   ├── k8-resources/     # Kubernetes resources (ALB, ArgoCD)
│   └── cicd/             # ECR repositories and pipelines
├── main.tf               # Root module configuration
├── providers.tf          # AWS, Kubernetes, Helm providers
├── variable.tf           # Input variables
├── dev.tfvars           # Development environment values
└── README.md            # This file
```

## Prerequisites

### 1. Create S3 Bucket for Terraform State
```bash
aws s3 mb s3://trocks-eks-tfstate-develop --region us-east-2
aws s3api put-bucket-versioning \
  --bucket trocks-eks-tfstate-develop \
  --versioning-configuration Status=Enabled
```

### 2. Create IAM User with Admin Access
```bash
# Create IAM user
aws iam create-user --user-name trocks-eks

# Attach admin policy
aws iam attach-user-policy \
  --user-name trocks-eks \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

# Create access keys
aws iam create-access-key --user-name trocks-eks
```

### 3. Configure AWS CLI
```bash
aws configure
# Enter the access key and secret from step 2
# Region: us-east-2
# Output format: json
```

### 4. Install Required Tools
- Terraform >= 1.14.3
- AWS CLI >= 2.0
- kubectl >= 1.28

## Quick Start

### 1. Clone and Initialize
```bash
git clone <repository-url>
cd infrastructure
terraform init
```

### 2. Create Workspace
```bash
# Create development workspace
terraform workspace new dev

# Or select existing workspace
terraform workspace select dev
```

### 3. Plan and Apply
```bash
# Review planned changes
terraform plan -var-file=dev.tfvars

# Apply infrastructure
terraform apply -var-file=dev.tfvars
```

### 4. Configure kubectl
```bash
# Update kubeconfig
aws eks update-kubeconfig --region us-east-2 --name trocks-eks

# Verify cluster access
kubectl get nodes
```

## Configuration

### Environment Variables (`dev.tfvars`)
```hcl
platform_iam_user_arn = "arn:aws:iam::194205500841:user/trocks-eks"
cluster_name = "trocks-eks"
argocd_ui_password = "$2a$10$W1ywL80nr/fmRPJ4yoCls.pefjrWhcRoQBMa0hfOlfrIzlo7X1Yi2"
argocd_ui_password_modified_at = "2026-01-28T19:46:45Z"
trocks_domain_name = "*.tamils.rocks"
```

### Terraform Backend (`main.tf`)
```hcl
backend "s3" {
  bucket = "trocks-eks-tfstate-develop"
  key    = "tfstate"
  region = "us-east-2"
}
```

## Modules

### VPC Module
- Creates VPC with public/private subnets
- Configures NAT gateways and internet gateway
- Sets up security groups for EKS

### IAM Module
- Platform admin role for cluster management
- Service account roles for AWS integrations
- OIDC provider for pod-level permissions

### EKS Module
- Managed EKS cluster with latest Kubernetes version
- Auto-scaling node groups with mixed instance types
- Cluster security groups and networking

### K8s Resources Module
- **ALB Controller** - Helm chart for AWS Load Balancer Controller
- **ArgoCD** - GitOps deployment with ingress configuration
- **Namespaces** - Organized resource separation
- **SSL Certificates** - ACM certificate with DNS validation

### CI/CD Module
- ECR repositories for container images
- CodeBuild projects for automated builds
- IAM roles for pipeline execution

## Providers

### AWS Provider
- Manages AWS resources (EKS, VPC, IAM, ALB)
- Version: ~> 6.28.0

### Kubernetes Provider
- Manages Kubernetes resources using EKS cluster
- Authenticates via AWS EKS token

### Helm Provider
- Deploys Helm charts (ALB Controller, ArgoCD)
- Uses Kubernetes provider for cluster access

## Deployment Phases

### Phase 1: Core Infrastructure
1. IAM roles and policies
2. EKS cluster creation
3. Node group provisioning

### Phase 2: Provider Configuration
1. Configure Kubernetes provider with EKS credentials
2. Set up Helm provider for chart deployments

### Phase 3: Kubernetes Resources
1. Deploy ALB Controller via Helm
2. Install ArgoCD with ingress configuration
3. Create namespaces and RBAC

## ArgoCD Integration

### Access ArgoCD UI
```bash
# Get ALB endpoint
kubectl get ingress -n argocd

# Access via browser
https://<alb-endpoint>/argo-cd
```

### Deploy Applications
Applications are deployed using ArgoCD from a separate Git repository containing Helm templates and configurations.

**Repository Structure:**
```
argocd-apps/
├── bootstrap/           # Parent app (App of Apps pattern)
├── charts/base-service/ # Reusable Helm chart
└── apps/               # Individual service configurations
```

### Bootstrap Application
```bash
kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: bootstrap-parent-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: 'https://github.com/btamilselvan/argocd-trocks-apps.git'
    targetRevision: develop
    path: bootstrap
  destination:
    server: https://kubernetes.default.svc
    namespace: terraform-trocks-namespace
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF
```

## Workspace Management

### Supported Workspaces
- `dev` - Development environment
- `staging` - Staging environment  
- `production` - Production environment

### Workspace Commands
```bash
# List workspaces
terraform workspace list

# Create new workspace
terraform workspace new staging

# Switch workspace
terraform workspace select production

# Delete workspace
terraform workspace delete dev
```

## Security Features

### Network Security
- Private subnets for worker nodes
- Security groups with minimal required access
- VPC endpoints for AWS services

### Access Control
- RBAC for Kubernetes resources
- IAM roles with least privilege
- Service accounts for pod-level permissions

### SSL/TLS
- ACM certificates with automatic renewal
- HTTPS-only ingress configuration
- Secure communication between components

## Monitoring & Management

### Cluster Health
```bash
# Check cluster status
kubectl get nodes
kubectl get pods --all-namespaces

# View cluster info
kubectl cluster-info
```

### ArgoCD Applications
```bash
# List applications
kubectl get applications -n argocd

# Check application status
kubectl describe application <app-name> -n argocd
```

### Load Balancer
```bash
# Check ALB status
kubectl get ingress --all-namespaces

# View ALB target groups
aws elbv2 describe-target-groups
```

## Troubleshooting

### Common Issues

**1. Terraform State Lock**
```bash
# Force unlock if needed
terraform force-unlock <lock-id>
```

**2. EKS Access Denied**
```bash
# Update kubeconfig
aws eks update-kubeconfig --region us-east-2 --name trocks-eks

# Check IAM permissions
aws sts get-caller-identity
```

**3. ArgoCD Login Issues**
```bash
# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### Debug Commands
```bash
# Check Terraform state
terraform show

# Validate configuration
terraform validate

# View detailed logs
terraform apply -var-file=dev.tfvars -auto-approve -log-level=DEBUG
```

## Cleanup

### Destroy Infrastructure
```bash
# Destroy all resources
terraform destroy -var-file=dev.tfvars

# Delete workspace
terraform workspace select default
terraform workspace delete dev
```

### Manual Cleanup
Some resources may require manual deletion:
- ALB target groups
- Security groups with dependencies
- ECR repositories with images

## Cost Optimization

### Resource Sizing
- Use spot instances for non-production workloads
- Configure cluster autoscaler for dynamic scaling
- Set appropriate resource requests/limits

### Monitoring Costs
- Enable AWS Cost Explorer
- Set up billing alerts
- Use AWS Trusted Advisor recommendations

## References

- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)