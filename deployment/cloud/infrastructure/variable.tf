variable "platform_iam_user_arn" {
  description = "The ARN of the IAM user to be granted cluster admin access"
}
variable "cluster_name" {
}

variable "network_cidr" {
  description = "The CIDR block for the network"
  default = "172.31.0.0/16"
}

variable "argocd_ui_password" {
}
variable "argocd_ui_password_modified_at" {
}