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
