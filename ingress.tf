locals {
  mapped_instance_groups = {
    for ik, iv in var.ingresses : ik => [for ng in iv.nodegroups : module.nodegroup[ng].instance_group]
  }
  mapped_target_pools = {
    for ik, iv in var.ingresses : ik => [for ng in iv.nodegroups : module.nodegroup[ng].target_pool]
  }
}

output "mapped_instance_groups" {
  value = local.mapped_instance_groups
}

module "ingress" {
  for_each               = var.ingresses
  source                 = "./modules/ingress"
  name                   = each.key
  rules                  = each.value.routes
  target_instance_groups = local.mapped_instance_groups[each.key]
  mode                   = each.value.mode
  region                 = var.region
  target_pools           = local.mapped_target_pools[each.key]
}

// calculated after lb is created
locals {
  // Add the lb for the lb to the ingress
  ingresses_withlb = { for k, i in var.ingresses : k => merge(i, module.ingress[k], { "lb_dns" : module.ingress[k].lb_dns }) }
}
