terraform {
  required_providers {
    argocd = {
      source  = "argoproj-labs/argocd"
      version = "7.12.5"
    }
  }
}

resource "aws_acm_certificate" "trocks" {
  domain_name       = var.trocks_domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn = aws_acm_certificate.trocks.arn
}

resource "kubernetes_namespace_v1" "trocks_namespace" {
  metadata {
    annotations = {
      name = "trocks-ns"
    }

    labels = {
      Environment = terraform.workspace
    }

    name = "terraform-trocks-namespace"
  }
}

resource "kubernetes_namespace_v1" "argocd_namespace" {
  metadata {
    annotations = {
      name = "argoCD-ns"
    }

    labels = {
      Environment = terraform.workspace
    }

    name = "argocd"
  }
}

## create IAM role used by Pods. this role trusts EKS Pod Identity service.
## the role will have ssm get parameter permssions for now. 
#use the below 4 steps or use app_pod_identity module below
# Step 1
# data "aws_iam_policy_document" "pod_identity_trust_policy" {
#   statement {
#     effect  = "Allow"
#     actions = ["sts:AssumeRole", "sts:TagSession"]
#     principals {
#       type        = "Service"
#       identifiers = ["pods.eks.amazonaws.com"]
#     }
#   }
# }

# #Step 2
# resource "aws_iam_role" "pod_role" {
#   name_prefix = "trocks-pod-role-${var.cluster_name}"
#   assume_role_policy = data.aws_iam_policy_document.pod_identity_trust_policy.json

#   tags = {
#     Environment = terraform.workspace
#     Terraform   = "true"
#   }
# }
# #Step 3 - add required permissions to the role
# resource "aws_iam_role_policy_attachment" "pod_role_ssm_get_parameter" {
#   role       = aws_iam_role.pod_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
# }

# #step 4 - link role to k8 service account using pod-identity-association
# resource "aws_eks_pod_identity_association" "pod_role_association" {
#   cluster_name    = var.cluster_name
#   namespace       =  kubernetes_namespace_v1.trocks_namespace.metadata[0].name
#   service_account = var.pod_service_account

#   role_arn = aws_iam_role.pod_role.arn

#   tags = {
#     Environment = terraform.workspace
#     Terraform   = "true"
#   }
# }

## either use above 4 steps or just this module
module "app_pod_identity" {
  source = "terraform-aws-modules/eks-pod-identity/aws"

  name = "trocks-pod-${var.cluster_name}"
  use_name_prefix = true

  additional_policy_arns = {
    SSM_READ_ONLY_ACCESS = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
  }

  attach_custom_policy = true

  policy_statements = [
    {
      sid = "s3access"
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:ListBucket",
      ]
      resources = ["*"]
    }
  ]

  associations = {
    custom-association = {
      cluster_name    = var.cluster_name
      namespace       = kubernetes_namespace_v1.trocks_namespace.metadata[0].name
      service_account = var.pod_service_account
    }
  }

  tags = {
    Environment = terraform.workspace
    Terraform   = "true"
  }
}

## IAM role to be attached to AWS load balancer controller (not needed if you use pod identity association)
module "iam" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version = "~> 6.3.0"

  name = "k8-alb-controller-${var.cluster_name}"

  attach_vpc_cni_policy                  = true
  vpc_cni_enable_ipv4                    = true
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    this = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }

  tags = {
    Terraform   = "true"
    Environment = terraform.workspace
  }
}

# ## create pod identity association for aws load balancer controller - new way of creating the role for load balancer controller,
# # and create pod-identity-association between service account and IAM role.  - doesn't work???
# #https://registry.terraform.io/modules/terraform-aws-modules/eks-pod-identity/aws/2.7.0?utm_content=documentLink&utm_medium=Visual+Studio+Code&utm_source=terraform-ls
# module "aws_lb_controller_pod_identity" {
#   source = "terraform-aws-modules/eks-pod-identity/aws"

#   name = "aws-lbc"
#   version = "2.7.0"

#   # This helper attaches the exact permissions the ALB controller needs
#   attach_aws_lb_controller_policy = true

#   associations = {
#     this = {
#       cluster_name    = var.cluster_name
#       namespace       = "kube-system"
#       service_account = "aws-load-balancer-controller"
#     }
#   }

#   tags = {
#     Environment = terraform.workspace
#     Terraform   = "true"
#   }
# }

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.17.1"
  timeout    = 300
  # wait_for_jobs = true

  # set = [
  #   {
  #     name  = "clusterName"
  #     value = var.cluster_name
  #   },
  #   {
  #     name  = "serviceAccount.create"
  #     value = true
  #   },
  #   {
  #     name  = "serviceAccount.name"
  #     value = "aws-load-balancer-controller"
  #   },
  #   {
  #     name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
  #     value = module.iam.arn
  #   },
  #   {
  #     name  = "region"
  #     value = "us-east-2"
  #   }
  # ]

  values = [
    yamlencode({
      clusterName = var.cluster_name
      vpcId       = var.vpc_id
      serviceAccount = {
        name   = "aws-load-balancer-controller"
        create = true
        region = "us-east-2"
        # annotations not needed if we use pod identity association
        annotations = {
          "eks.amazonaws.com/role-arn" = module.iam.arn
        }
      }
      replicaCount = 2
      nodeSelector = {
        role = "system"
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
  ]
}

#app chart - create only ingress (ALB)
resource "helm_release" "alb_ingress" {
  depends_on = [helm_release.aws_load_balancer_controller]
  name       = "alb-ingress"
  chart      = "${path.module}/argocd"
  # namespace = kubernetes_namespace_v1.trocks_namespace.metadata[0].name
  # version       = "1.0.0"

  set = [{
    name  = "alb.group_name"
    value = "trocks-k8-shared-alb"
    },
    {
      name  = "namespace"
      value = kubernetes_namespace_v1.argocd_namespace.metadata[0].name
    },
    {
      name  = "ingress.name"
      value = local.ingress_name
    },
    {
      name  = "alb.certificate_arn"
      value = aws_acm_certificate_validation.cert_validation.certificate_arn
    }
  ]
}

# argoCD controller - this will create the argocd controller, ALB target group
resource "helm_release" "argocd" {
  depends_on = [helm_release.aws_load_balancer_controller]
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace_v1.argocd_namespace.metadata[0].name
  version    = "9.3.7"

  # values = [
  #   yamlencode({
  #     server = {
  #       replicas = 2
  #       affinity = {
  #         podAffinity = {
  #           preferredDuringSchedulingIgnoredDuringExecution = [
  #             {
  #               weight = 100
  #               podAffinityTerm = {
  #                 labelSelector = {
  #                   matchLabels = {
  #                     app.kubernetes.io/name = "argocd-server"
  #                   }
  #                 }
  #                 topologyKey = "kubernetes.io/hostname"
  #               }
  #             },
  #             {
  #               weight = 50
  #               podAffinityTerm = {
  #                 labelSelector = {
  #                   matchLabels = {
  #                     app.kubernetes.io/name = "argocd-server"
  #                   }
  #                 }
  #                 topologyKey = "topology.kubernetes.io/zone"
  #               }
  #             }
  #           ]
  #         }
  #       }
  #     }
  #     repoServer = {
  #       replicas = 1
  #     }
  #   })
  # ]
  ## or - this automatically sets affinity as well
  # values = [yamlencode({
  #   global = {
  #     ha = {
  #       enabled = true
  #     }
  #   }
  # })]

  # create_namespace = true
  # values = [
  #   templatefile("${path.module}/argocd-values.tftpl", {
  #     alb_security_group_id = var.alb_security_group_id
  #     alb_group_name = "trocks-k8-shared-alb"
  #   })
  # ]

  set = [
    # {
    #   name  = "server.ingress.enabled"
    #   value = true
    # },
    # {
    #   name  = "server.ingress.ingressClassName"
    #   value = "alb"
    # },
    # {
    #   name  = "server.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/group\\.name"
    #   value = "trocks-k8-shared-alb"
    # },
    # {
    #   name  = "server.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/scheme"
    #   value = "internet-facing"
    # },
    # {
    #   name  = "server.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/target-type"
    #   value = "ip"
    # },
    # {
    #   name  = "server.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/listen-ports"
    #   value = "[\\{\"HTTP\": 80\\}]"
    # },
    # {
    #   name  = "server.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/healthcheck-path"
    #   value = "/healthz"
    # },
    # {
    #   #security group
    #   name  = "server.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/security-groups"
    #   value = "${var.alb_security_group_id}"
    # },
    # {
    #   name  = "server.ingress.paths[0]"
    #   value = "/argo-cd"
    # },
    {
      name  = "global.tolerations[0].key"
      value = "node-role.kubernetes.io/system"
    },
    {
      name  = "global.tolerations[0].operator"
      value = "Equal"
    },
    {
      name  = "global.tolerations[0].value"
      value = "true"
      type  = "string"
    },
    {
      name  = "global.tolerations[0].effect"
      value = "NoSchedule"
    },
    {
      name  = "global.nodeSelector.role"
      value = "system"
    },
    {
      #Disable internal TLS so ALB can talk to it over HTTP
      name  = "server.extraArgs"
      value = "{--insecure,--rootpath=/argo-cd}"
    },
    {
      #Update the base href for the UI
      name  = "configs.params.server.basehref"
      value = "/argo-cd"
    },
    {
      name  = "configs.secret.argocdServerAdminPassword"
      value = var.argocd_ui_password
    },
    {
      name = "configs.secret.argocdServerAdminPasswordMtime"
      # value = timestamp()
      value = var.argocd_ui_password_modified_at ## constant value to avoid changes on every apply
    },
    # {
    #   name  = "server.additionalApplications[0].name"
    #   value = "trocks-master-app"
    # },
    # {
    #   name  = "server.additionalApplications[0].namespace"
    #   value = kubernetes_namespace_v1.argocd_namespace.metadata[0].name
    # },
    # {
    #   name  = "server.additionalApplications[0].source.repoURL"
    #   value = local.argocd.repo_url
    # },
    # {
    #   name  = "server.additionalApplications[0].source.targetRevision"
    #   value = "develop"
    # },
    # {
    #   name  = "server.additionalApplications[0].source.path"
    #   value = "bootstrap"
    # },
    # {
    #   name  = "server.additionalApplications[0].destination.server"
    #   value = "https://kubernetes.default.svc"
    # },
    # {
    #   name  = "server.additionalApplications[0].destination.namespace"
    #   value = kubernetes_namespace_v1.argocd_namespace.metadata[0].name
    # },
    # {
    #   name  = "server.additionalApplications[0].syncPolicy.automated.prune"
    #   value = "true"
    # },
    # {
    #   name  = "server.additionalApplications[0].syncPolicy.automated.selfHeal"
    #   value = "true"
    # }
    # {
    #   name  = "server.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/backend-protocol"
    #   value = "HTTP"
    # },
    # {
    #   name  = "server.ingress.pathType"
    #   value = "Prefix"
    # }
  ]
}

data "kubernetes_ingress_v1" "alb_ingress" {
  metadata {
    name      = local.ingress_name
    namespace = kubernetes_namespace_v1.argocd_namespace.metadata[0].name
  }
}

data "kubernetes_secret_v1" "argocd_initial_admin_secret" {
  metadata {
    name      = "argocd-initial-admin-secret"
    namespace = kubernetes_namespace_v1.argocd_namespace.metadata[0].name
  }
  depends_on = [helm_release.argocd]
}

# provider "argocd" {
#   server_addr = data.kubernetes_ingress_v1.alb_ingress.status.0.load_balancer.0.ingress.0.hostname
#   base_path   = "/argo-cd"
#   username    = "admin"
#   password    = var.argocd_ui_password
#   plain_text = true
#   insecure    = true
# }

# resource "argocd_application" "trocks_master_app" {
#   metadata {
#     name      = "trocks-master-app"
#     namespace = kubernetes_namespace_v1.argocd_namespace.metadata[0].name
#   }
#   spec {
#     source {
#       repo_url        = "https://github.com/btamilselvan/argocd-trocks-apps.git"
#       target_revision = "develop"
#       path            = "bootstrap"
#     }
#     destination {
#       server    = "https://kubernetes.default.svc"
#       namespace = kubernetes_namespace_v1.argocd_namespace.metadata[0].name
#     }
#     sync_policy {
#       automated {
#         prune     = true
#         self_heal = true
#       }
#       retry {
#         limit = 5
#         backoff {
#           duration     = "5s"
#           factor       = 2
#           max_duration = "1m"
#         }
#       }
#     }
#   }
# }

## create the IAM role for the Nodes karpenter will create
module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 21.15.1"

  cluster_name = var.cluster_name

  node_iam_role_use_name_prefix = false
  node_iam_role_name = "Karpenter-${var.cluster_name}"

  # Attach additional IAM policies to the Karpenter node IAM role
  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }


  tags = {
    Terraform   = "true"
    Environment = terraform.workspace
  }
}

# data "aws_region" "current" {}

data "aws_ecrpublic_authorization_token" "token" {
  region = "us-east-1"
}

resource "helm_release" "karpenter" {
  namespace           = "kube-system"
  name                = "karpenter"
  repository          = "oci://public.ecr.aws/karpenter"
  repository_username = data.aws_ecrpublic_authorization_token.token.user_name
  repository_password = data.aws_ecrpublic_authorization_token.token.password
  chart               = "karpenter"
  version             = "1.9.0"
  wait                = false

  # set = [{
  #   name  = "nodeSelector.role"
  #   value = "karpenter"
  #   },
  #   {
  #     name  = "tolerations[0].key"
  #     value = "KarpenterNodsOnly"
  #   },
  #   {
  #     name  = "tolerations[0].operator"
  #     value = "Equal"
  #   },
  #   {
  #     name  = "tolerations[0].value"
  #     value = "true"
  #     type  = "string"
  #   },
  #   {
  #     name  = "tolerations[0].effect"
  #     value = "NoSchedule"
  #   }
  # ]

  values = [
    <<-EOT
    serviceAccount:
      annotations:
        eks.amazonaws.com/role-arn: ${module.karpenter.iam_role_arn}
    settings:
      clusterName: ${var.cluster_name}
      clusterEndpoint: ${var.cluster_endpoint}
      interruptionQueue: ${module.karpenter.queue_name}
    webhook:
      enabled: false
    
    # add node selector and tolerations to run on system nodes only
    nodeSelector:
      role: karpenter
    tolerations:
      - key: KarpenterNodsOnly
        operator: Equal
        value: "true"
        effect: NoSchedule
    EOT
  ]

  lifecycle {
    ignore_changes = [repository_password]
  }
}

# resource "helm_release" "karpenter" {
#   namespace           = "kube-system"
#   name                = "karpenter"
#   repository          = "oci://public.ecr.aws/karpenter"
#   repository_username = data.aws_ecrpublic_authorization_token.token.user_name
#   repository_password = data.aws_ecrpublic_authorization_token.token.password
#   chart               = "karpenter"
#   version             = "1.9.0"
#   wait                = false

#   values = [
#     <<-EOT
#     nodeSelector:
#       karpenter.sh/controller: 'true'
#     dnsPolicy: Default
#     settings:
#       clusterName: ${var.cluster_name}
#       clusterEndpoint: ${module.eks.cluster_endpoint}
#       interruptionQueue: ${module.karpenter.queue_name}
#     webhook:
#       enabled: false
#     EOT
#   ]
# }

output "alb_dns" {
  value = data.kubernetes_ingress_v1.alb_ingress.status.0.load_balancer.0.ingress.0.hostname
}
output "argo_secret" {
  value     = data.kubernetes_secret_v1.argocd_initial_admin_secret.data["password"]
  sensitive = false
}
