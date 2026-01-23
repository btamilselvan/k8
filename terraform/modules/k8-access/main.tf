# variable "cluster_name" {
# }
# variable "cluster_endpoint" {
# }
# variable "cluster_cert_auth_data" {
# }
# variable "role_arn" {
#   description = "The ARN of the role to assume for Kubernetes provider"
# }

# provider "kubernetes" {
#   host                   = var.cluster_endpoint
#   cluster_ca_certificate = base64decode(var.cluster_cert_auth_data)
#   exec {
#     api_version = "client.authentication.k8s.io/v1beta1"
#     command     = "aws"
#     args = [
#       "eks",
#       "get-token",
#       "--cluster-name",
#       var.cluster_name,
#       "--role-arn",
#       var.role_arn
#     ]
#   }
# }
