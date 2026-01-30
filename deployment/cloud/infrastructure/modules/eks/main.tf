variable "cluster_name" {
  default = "trocks-eks"
}

variable "network_cidr" {
}

# create security group for ALB
resource "aws_security_group" "alb_sg" {
  name        = "trocks-alb-sg-${var.cluster_name}"
  description = "Security group for ALB"
  vpc_id      = var.vpc_id
  tags = {
    Name        = "trocks-alb-sg-${var.cluster_name}"
    Environment = terraform.workspace
    Terraform   = "true"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_all_https_traffic_ipv4" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "allow_all_http_traffic_ipv4" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

# create additional security group for the worker nodes to allow traffic from ALB SG
# resource "aws_security_group" "node_sg" {
#   name        = "trocks-node-sg-${var.cluster_name}"
#   description = "Security group for worker nodes"
#   vpc_id      = var.vpc_id
#   tags = {
#     Name        = "trocks-node-sg-${var.cluster_name}"
#     Environment = terraform.workspace
#     Terraform   = "true"
#   }
# }

# # create additional security group rules for the worker nodes to allow traffic from ALB SG
# resource "aws_vpc_security_group_ingress_rule" "allow_alb_to_worker_nodes_http" {
#   security_group_id            = aws_security_group.node_sg.id
#   referenced_security_group_id = aws_security_group.alb_sg.id
#   from_port                    = 80
#   ip_protocol                  = "tcp"
#   to_port                      = 80
# }

# resource "aws_vpc_security_group_ingress_rule" "allow_alb_to_worker_nodes_https" {
#   security_group_id            = aws_security_group.node_sg.id
#   referenced_security_group_id = aws_security_group.alb_sg.id
#   from_port                    = 443
#   ip_protocol                  = "tcp"
#   to_port                      = 443
# }

# resource "aws_vpc_security_group_ingress_rule" "allow_alb_to_worker_nodes_https" {
#   security_group_id            = aws_security_group.node_sg.id
#   referenced_security_group_id = aws_security_group.alb_sg.id
#   from_port                    = 443
#   ip_protocol                  = "tcp"
#   to_port                      = 443
# }

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  #Step 1 - Cluster configuration
  name                                     = var.cluster_name
  create_iam_role                          = true
  kubernetes_version                       = "1.35" #get this from AWS EKS console
  enable_cluster_creator_admin_permissions = true
  authentication_mode                      = "API_AND_CONFIG_MAP"

  kms_key_aliases                        = ["trocks/eks"]
  kms_key_deletion_window_in_days        = 7
  cloudwatch_log_group_retention_in_days = 7

  #   iam_role_arn                             = ""     #set this if create_iam_role is false
  #   deletion_protection = true

  #   zonal_shift_config = {

  #   }
  #   encryption_config = {
  #   }

  control_plane_scaling_config = {
    tier = "standard"
  }

  #Step 2 - Networking
  vpc_id                   = var.vpc_id
  subnet_ids               = var.subnet_ids
  control_plane_subnet_ids = var.subnet_ids #optional
  # AWS automatically creates a cluster security group on cluster creation 
  # to facilitate communication between worker nodes and control plane.
  #   security_group_id = "" 
  ip_family                  = "ipv4"
  endpoint_private_access    = true
  endpoint_public_access     = true
  create_node_security_group = true
  # node_security_group_id     = aws_security_group.node_sg.id
  # node_security_group_enable_recommended_rules = true
  # node_security_group_additional_rules = {
  #   ingress_alb_http = {
  #     description                     = "Allow HTTP from ALB"
  #     protocol                        = "tcp"
  #     from_port                       = 80
  #     to_port                         = 80
  #     type                            = "ingress"
  #     source_security_group_id        = aws_security_group.alb_sg.id
  #     source_security_group_rule_type = "referenced"
  #   }
  #   ingress_alb_https = {
  #     description                     = "Allow HTTPS from ALB"
  #     protocol                        = "tcp"
  #     from_port                       = 443
  #     to_port                         = 443
  #     type                            = "ingress"
  #     source_security_group_id        = aws_security_group.alb_sg.id
  #     source_security_group_rule_type = "referenced"
  #   }
  #   ingress_alb_http_8080 = {
  #     description                     = "Allow HTTP traffic from ALB in port 8080"
  #     protocol                        = "tcp"
  #     from_port                       = 8080
  #     to_port                         = 8080
  #     type                            = "ingress"
  #     source_security_group_id        = aws_security_group.alb_sg.id
  #     source_security_group_rule_type = "referenced"
  #   }
  # }

  # Step 3 - observability -

  # Step 4 - add-ons
  addons = {
    coredns = {
      #   most_recent = true # AWS automatically selects a default version
      # add node selector and tolerations to run on system nodes only
      # coreDNS does not run on all nodes by default
      configuration_values = jsonencode({
        nodeSelector = {
          "role" = "system"
        }
        tolerations = [
          {
            key      = "node-role.kubernetes.io/system"
            operator = "Equal"
            value    = "true"
            effect   = "NoSchedule"
          }
        ]
      })
    }
    kube-proxy = {
      #   most_recent = true
      # these pods should run on all nodes - and AWS adds tolerations by default
    }
    vpc-cni = {
      #   most_recent = true
      before_compute = true ## important - to ensure this is created before node groups - required for networking
      # these pods should run on all nodes - and AWS adds tolerations by default
    }
    eks-pod-identity-agent = {
      before_compute = true ## important - to ensure this is created before node groups
      # these pods should run on all nodes - and AWS adds tolerations by default
    }
  }

  # Node groups
  eks_managed_node_groups = {
    system-node-group = {
      name                   = "system-node-group"
      ami_type               = "AL2023_x86_64_STANDARD"
      ami_release_version    = "1.35.0-20260120" #optional - to pin to a specific AMI version
      force_update_version   = false
      create_launch_template = true
      launch_template_name   = "system-node-group-template"
      instance_types         = ["t2.small"]
      min_size               = 2
      max_size               = 4
      desired_size           = 3

      labels = {
        role = "system"
        name = "system"
      }
      taints = { system = {
        key    = "node-role.kubernetes.io/system"
        value  = "true"
        effect = "NO_SCHEDULE"
        }
      }
      lifecycle = {
        ignore_changes = ["ami_release_version", "release_version"]
      }
    }
    app-node-group = {
      name                   = "app-node-group"
      ami_type               = "AL2023_x86_64_STANDARD"
      ami_release_version    = "1.35.0-20260120" #optional - to pin to a specific AMI version
      force_update_version   = false
      create_launch_template = true
      launch_template_name   = "app-node-group-template"
      instance_types         = ["t2.small"]
      min_size               = 2
      max_size               = 5
      desired_size           = 3
      labels = {
        role = "app"
        name = "app"
      }
    }
  }

  access_entries = {
    platform_admin = {
      principal_arn = var.cluster_platform_admin_role

      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  tags = {
    Environment = terraform.workspace
    Terraform   = "true"
  }
}

resource "aws_security_group_rule" "alb_egress_to_nodes" {
  type                     = "egress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  security_group_id        = aws_security_group.alb_sg.id      # The ALB SG
  source_security_group_id = module.eks.node_security_group_id # The EKS Node SG
}
