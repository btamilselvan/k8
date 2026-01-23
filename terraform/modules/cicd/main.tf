
module "ecr" {
  source    = "./ecr"
  for_each  = local.services
  repo_name = each.value.name
}

module "s3_cicd_bucket" {
  source = "./s3"
  bucket_prefix = "cicd-bucket"
}

module "iam" {
  source           = "./iam"
  cicd_bucket_name = module.s3_cicd_bucket.bucket_name
}

module "pipeline" {
  source = "./pipeline"
  for_each  = local.services
  cicd_bucket = module.s3_cicd_bucket.bucket_name
  codebuild_role_arn = module.iam.codebuild_role_arn
  codepipeline_role_arn = module.iam.codepipeline_role_arn
  git_repo_id = each.value.repo
  service_name = each.value.name
  git_branch_name = each.value.branch
}