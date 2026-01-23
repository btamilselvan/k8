#### data
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

variable "cicd_bucket_name" {
}

## create a code build role to build docker container
resource "aws_iam_role" "codebuild-role" {
  name_prefix        = "codebuild-"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
        "Effect": "Allow",
        "Principal": {
            "Service": "codebuild.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
        }
    ]
  }
EOF
  lifecycle {
    create_before_destroy = true
  }
}

#give access to pull parameters from param store
resource "aws_iam_role_policy" "codebuild_ssm_access" {
  name = "ssm"
  role = aws_iam_role.codebuild-role.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["ssm:GetParameters"]
        Effect   = "Allow"
        Resource = ["arn:aws:ssm:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:parameter/CodeBuild/*"]
      },
    ]
  })
}

#give access to get/put objects from cicd bucket
resource "aws_iam_role_policy" "codebuild_s3_access" {
  name = "s3"
  role = aws_iam_role.codebuild-role.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["s3:GetObject", "s3:PutObject"]
        Effect   = "Allow"
        Resource = ["arn:aws:s3:::${var.cicd_bucket_name}/*"]
      },
      {
        Action   = ["s3:ListBucket"]
        Effect   = "Allow"
        Resource = ["arn:aws:s3:::${var.cicd_bucket_name}"]
      }
    ]
  })
}
#give access upload docker images to ecr repo
resource "aws_iam_role_policy" "codebuild_ecr_access" {
  name = "ecr"
  role = aws_iam_role.codebuild-role.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["ecr:GetDownloadUrlForLayer", "ecr:BatchGetImage", "ecr:BatchCheckLayerAvailability",
        "ecr:PutImage", "ecr:InitiateLayerUpload", "ecr:UploadLayerPart", "ecr:CompleteLayerUpload"]
        Effect   = "Allow"
        Resource = ["arn:aws:ecr:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:repository/*"]
      },
      {
        Action   = "ecr:GetAuthorizationToken"
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}
#give codebuild role access to cloudwatch logs
resource "aws_iam_role_policy" "codebuild_cloudwatch_access" {
  name = "cloudwatch"
  role = aws_iam_role.codebuild-role.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Effect   = "Allow"
        Resource = ["arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/*"]
      },
    ]
  })
}

## code pipeline role for ecs build and deployment
resource "aws_iam_role" "codepipeline" {
  name_prefix        = "ecs-codepipeline-"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
    "Statement": [
        {
        "Effect": "Allow",
        "Principal": {
            "Service": "codepipeline.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
        }
    ]
  }
EOF
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "attach_admin_access" {
  role       = aws_iam_role.codepipeline.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

output "codebuild_role_arn" {
  value = aws_iam_role.codebuild-role.arn
}

output "codepipeline_role_arn" {
  value = aws_iam_role.codepipeline.arn
}