variable "oidc_provider_arn" {
  description = "The ARN of the OIDC provider for the EKS cluster"
  type        = string
}
variable "cluster_name" {
}
variable "vpc_id" {
  description = "The VPC ID for the EKS cluster"
  type        = string
}

variable "alb_security_group_id" {
  description = "Security Group ID for ALB"
  type        = string
}
variable "argocd_ui_password" {
  description = "The initial password for the ArgoCD UI"
  type        = string
}
variable "argocd_ui_password_modified_at" {
}

locals {
  ingress_name = "argocd-ingress"
  argocd = {
    repo_url = "https://github.com/btamilselvan/argocd-trocks-apps.git"
  }
}