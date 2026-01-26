variable "cluster_admin_iam_user_arn" {
  description = "The ARN of the IAM user to be granted cluster admin access"
}

resource "aws_iam_role" "platform_admin_role" {
  name_prefix = "platform-admin"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = var.cluster_admin_iam_user_arn
        }
        "Action" : "sts:AssumeRole"
      }
    ]
  })

}
resource "aws_iam_role_policy" "platform_admin_policy" {
  name_prefix = "platform_admin"
  role = aws_iam_role.platform_admin_role.id

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "eks:DescribeNodegroup",
          "eks:ListNodegroups",
          "eks:ListAddons",
          "eks:DescribeCluster",
          "eks:DescribeAddon"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

output "platform_admin_role_arn" {
  value = aws_iam_role.platform_admin_role.arn
}