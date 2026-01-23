# provider configuration - specify region, alias, etc.. 
# The provider name 'aws' should match the name used in the required_providers block in main.tf
provider "aws" {
  region = "us-east-2"
}

## Optional: If you want to use the kubernetes provider with local kubeconfig file
## Uncomment the below provider block and comment out the kubernetes provider block in the k8-access module
# to use the local kubeconfig file for authentication
# provider "kubernetes" {
#   config_path = "~/.kube/config"
# }

## Optional: If you want to use the helm provider with local kubeconfig file
# provider "helm" {
#   kubernetes = {
#     config_path = "~/.kube/config"
#   }
# }