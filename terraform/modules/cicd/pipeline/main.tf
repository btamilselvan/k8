resource "aws_codestarconnections_connection" "github" {
  name          = "Github"
  provider_type = "GitHub"
}

resource "aws_codebuild_project" "build" {
  artifacts {
    type = "CODEPIPELINE"
  }
  cache {
    location = "${var.cicd_bucket}/${var.service_name}"
    type     = "S3"
  }
  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:6.0"
    privileged_mode = true
    type            = "LINUX_CONTAINER"
    environment_variable {
      name  = "REPOSITORY_URI"
      value = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.region}.amazonaws.com/${var.service_name}"
    }
    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.current.account_id
    }
    environment_variable {
      name  = "AWS_REGION"
      value = data.aws_region.current.region
    }
  }
  name         = var.service_name
  service_role = var.codebuild_role_arn
  source {
    buildspec = "spring-cloud-k8/${var.service_name}/CICD/buildspec-aws.yml"
    type      = "CODEPIPELINE"
  }
}

resource "aws_codepipeline" "pipeline" {
  name = var.service_name
  artifact_store {
    location = var.cicd_bucket
    type     = "S3"
  }
  role_arn = var.codepipeline_role_arn

  #source
  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]
      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.github.arn
        FullRepositoryId = var.git_repo_id
        BranchName       = var.git_branch_name
        DetectChanges    = false
      }
    }
  }

  #Build
  stage {
    name = "Build"
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = 1
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      configuration = {
        ProjectName = var.service_name
      }
    }
  }

#   #Deploy
#   stage {
#     name = "Deploy"
#     action {
#       name            = "Deploy"
#       category        = "Deploy"
#       owner           = "AWS"
#       provider        = "ECS"
#       version         = 1
#       input_artifacts = ["build_output"]
#       configuration = {
#         ClusterName = var.ecs_cluster_name
#         ServiceName = var.service_name
#         FileName    = "imagedefinitions.json"
#       }
#     }
#   }
}