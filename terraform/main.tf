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
  }
  backend "s3" {
    bucket = "trocks-eks-tfstate-develop"
    key    = "tfstate"
    region = "us-east-2"
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

## Phase 2 - kubernetes provider module - Start
# This should be done after the EKS cluster is created in Phase 1
# Configure the kubernetes provider to connect to the EKS cluster created in Phase 1
module "eks_provider" {
  depends_on             = [module.eks]
  source                 = "./modules/k8-access"
  cluster_name           = module.eks.cluster_name
  cluster_endpoint       = module.eks.cluster_endpoint
  cluster_cert_auth_data = module.eks.cluster_cert_auth_data
  role_arn               = module.iam.platform_admin_role_arn
}
## Phase 2 - End

# Step 3 - k8s resources - Start
# This should be done after the EKS cluster is created in Phase 1
# Add your kubernetes resources here using the kubernetes provider configured in the eks_provider module
module "k8_resources" {
  depends_on = [module.eks_provider]
  source     = "./modules/k8-resources"
}
# Step 3 - k8s resources - End
