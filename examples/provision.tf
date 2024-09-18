locals {
  // combine the nodegroup definition with the platform data
  nodegroups_wplatform = { for k, ngd in var.nodegroups : k => merge(ngd, local.platforms_with_image[ngd.platform]) }
  mke_ingresses = {
    "mke" = {
      description = "MKE ingress for UI and Kube"
      nodegroups  = [for k, ng in var.nodegroups : k if ng.role == "manager"]

      routes = {
        "mke" = {
          port_incoming = 443
          port_target   = 443
          protocol      = "TCP"
        }
        "kube" = {
          port_incoming = 6443
          port_target   = 6443
          protocol      = "TCP"
        }
      }
    }
  }
}

module "provision" {
  source  = "../"
  region  = var.region
  name    = var.name
  project = var.project
  nodegroups = { for k, ngd in local.nodegroups_wplatform : k => {
    source_image : {
      project : ngd.project
      family : ngd.family
      self_link : ngd.self_link
    }
    type : ngd.type
    count : ngd.count
    volume_size : ngd.volume_size
    role : ngd.role
    public : ngd.public
    user_data : ngd.user_data
    ssh_user : ngd.ssh_user
  } }
  subnets    = var.subnets
  firewalls  = local.mke_firewalls
  ingresses  = local.mke_ingresses
  extra_tags = var.common_tags
}

locals {
  // combine each node-group & platform definition with the provisioned nodes
  nodegroups = { for k, ngp in local.nodegroups_wplatform : k => merge({ "name" : k }, ngp, module.provision.nodegroups[k]) }
  ingresses  = { for k, i in local.launchpad_ingresses : k => merge({ "name" : k }, i, module.provision.ingresses[k]) }
}

output "nodegroups" {
  value = local.nodegroups
}

output "ingresses" {
  value = local.ingresses
}
