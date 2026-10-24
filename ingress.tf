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

# tcp mode: point each nodegroup's instance-group manager at the ingress
# target pool so new instances register automatically.
locals {
  tcp_pool_bindings = merge([
    for ik, iv in var.ingresses : {
      for ng in iv.nodegroups : "${ik}-${ng}" => {
        nodegroup = ng
        pool      = module.ingress[ik].target_pool
      }
    } if iv.mode == "tcp"
  ]...)
}

// calculated after lb is created
locals {
  // Add the lb for the lb to the ingress
  ingresses_withlb = { for k, i in var.ingresses : k => merge(i, module.ingress[k], { "lb_dns" : module.ingress[k].lb_dns }) }
}
