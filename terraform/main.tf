terraform {
  required_version = "~> 1.14.3" #terraform version
  required_providers {
    # this installs the aws provider
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.28.0" #provider version
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 3.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 3.1.1"
    }
  }
  backend "s3" {
    bucket = "trocks-eks-tfstate-develop"
    key    = "tfstate"
    region = "us-east-2"
  }
}

### workspace validation - Start
# Validate that the workspace is one of the allowed values
locals {
  allowed_workspaces = ["dev", "staging", "production"]
}
resource "null_resource" "workspace_validation" {
  lifecycle {
    precondition {
      condition     = terraform.workspace != "default" && contains(local.allowed_workspaces, terraform.workspace)
      error_message = "Workspace cannot be 'default'"
    }
  }
}

## Phase 1 - Start
# VPC module
# module "vpc" {
#   source = "./modules/vpc"
# }

module "iam" {
  source                     = "./modules/iam"
  cluster_admin_iam_user_arn = var.platform_iam_user_arn
}

# EKS module
module "eks" {
  source = "./modules/eks"
  #   vpc_id                      = module.vpc.vpc_id
  vpc_id = "vpc-31ce655a"
  #   subnet_ids                  = module.vpc.private_subnet_ids
  subnet_ids                  = ["subnet-e9c11282", "subnet-b3d2dbc9", "subnet-1bc4b557"]
  cluster_platform_admin_role = module.iam.platform_admin_role_arn
}
## Phase 1 - End

## Phase 2 - kubernetes provider configuration - Start
# Configure Kubernetes provider using EKS module outputs

data "aws_eks_cluster_auth" "trocks_eks" {
  name = module.eks.cluster_name
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_cert_auth_data)
  token                  = data.aws_eks_cluster_auth.trocks_eks.token
}

# configure helm provider
provider "helm" {
  kubernetes = {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_cert_auth_data)
    token                  = data.aws_eks_cluster_auth.trocks_eks.token
    # exec = {
    #   api_version = "client.authentication.k8s.io/v1beta1"
    #   args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    #   command     = "aws"
    # }
  }
}

# provider "kubernetes" {
#   host                   = module.eks.cluster_endpoint
#   cluster_ca_certificate = base64decode(module.eks.cluster_cert_auth_data)
#   exec {
#     api_version = "client.authentication.k8s.io/v1beta1"
#     command     = "aws"
#     args = [
#       "eks",
#       "get-token",
#       "--cluster-name",
#         module.eks.cluster_name,
#       "--role-arn",
#       module.iam.platform_admin_role_arn
#     ]
#   }
# }

## Phase 2 - End

# Step 3 - k8s resources - Start
# Kubernetes resources using the provider configured above
module "k8_resources" {
  depends_on        = [module.eks]
  source            = "./modules/k8-resources"
  oidc_provider_arn = module.eks.oidc_provider_arn
  cluster_name      = module.eks.cluster_name
  #   vpc_id                      = module.vpc.vpc_id
  vpc_id = "vpc-31ce655a"
}
## cicd module
module "cicd" {
  source = "./modules/cicd"
}
# Step 3 - k8s resources - End
