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

# ## allow the ALB controller to describe load balancers
# module "iam_policy" {
#   source = "terraform-aws-modules/iam/aws//modules/iam-policy"

#   name        = "k8-service-account-policy"
#   path        = "/"
#   description = "My example policy"

#   policy = <<-EOF
#     {
#       "Version": "2012-10-17",
#       "Statement": [
#         {
#           "Action": [
#             "elasticloadbalancing:DescribeLoadBalancers"
#           ],
#           "Effect": "Allow",
#           "Resource": "*"
#         }
#       ]
#     }
#   EOF

#   tags = {
#     Terraform   = "true"
#     Environment = terraform.workspace
#   }
# }

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

  # policies = {
  #   custom = module.iam_policy.arn
  # }

  ## provide elasticloadbalancing:DescribeLoadBalancers permission


  tags = {
    Terraform   = "true"
    Environment = terraform.workspace
  }
}

# variable "tolerations_list" {
#   description = "List of tolerations to apply to pods"
#   type        = list(any)
#   default = [
#     {
#       key      = "node-role.kubernetes.io/system"
#       operator = "Equal"
#       value    = "true"
#       effect   = "NoSchedule"
#     }
#   ]
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
        annotations = {
          "eks.amazonaws.com/role-arn" = module.iam.arn
        }
      }
      replicaCount = terraform.workspace == "prod" ? 2 : 1
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

#app chart - create only ingress (ALB) for gateway-service
resource "helm_release" "gateway_service" {
  name      = "gateway-service"
  chart     = "${path.module}/apps/base-service"
  namespace = kubernetes_namespace_v1.trocks_namespace.metadata[0].name
  # version       = "1.0.0"

  set = [{
    name  = "ingress.enabled"
    value = true
    },
    {
      name  = "namespace"
      value = kubernetes_namespace_v1.trocks_namespace.metadata[0].name
    },
    # {
    #   name  = "app.name"
    #   value = "gateway-service"
    # },
    # {
    #   name  = "spring.profiles.active"
    #   value = terraform.workspace == "prod" ? "prod,kubernetes" : "dev,kubernetes"
    # }
  ]
}

resource "helm_release" "argocd" {
  depends_on       = [helm_release.gateway_service]
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = kubernetes_namespace_v1.argocd_namespace.metadata[0].name
  # create_namespace = true

  set = [
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
      type = "string"
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
    }
  ]

}
