output "alb_dns" {
  value = module.k8_resources.alb_dns
}
# output "argo_secret" {
#   value = module.k8_resources.argo_secret
#   sensitive = false
# }