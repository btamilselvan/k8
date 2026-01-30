locals {
  services = {
    gateway-service = {
      name   = "gateway-service"
      branch = "master"
      repo   = "btamilselvan/k8"
    }
    person-service = {
      name   = "person-service"
      branch = "master"
      repo   = "btamilselvan/k8"
    }
    address-service = {
      name   = "address-service"
      branch = "master"
      repo   = "btamilselvan/k8"
    }
    cloud-config-server = {
      name   = "cloud-config-server"
      branch = "master"
      repo   = "btamilselvan/k8"
    }
  }
}
