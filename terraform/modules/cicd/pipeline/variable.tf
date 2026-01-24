variable "cicd_bucket" {
}
variable "service_name" {
}
variable "codebuild_role_arn" {
}
variable "codepipeline_role_arn" {
}
variable "git_repo_id" {
}
variable "git_branch_name" {
}
variable "codestar_connection_arn" {
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}
