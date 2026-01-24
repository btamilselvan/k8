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
