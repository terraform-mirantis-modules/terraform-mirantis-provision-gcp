locals {
  sub_merged = { for sk, sv in google_compute_subnetwork.public : sk => merge(sv, var.pub_subnets[sk]) }
}

output "sub_merged" {
  value = local.sub_merged
}

module "nodegroup" {
  for_each     = var.nodegroups
  source       = "./modules/nodegroup"
  name         = var.name
  ssh_user     = var.nodegroups[each.key].ssh_user
  machine_type = var.nodegroups[each.key].type
  vm_count     = var.nodegroups[each.key].count
  source_image = {
    family    = var.nodegroups[each.key].family
    project   = var.nodegroups[each.key].project
    self_link = var.nodegroups[each.key].self_link
  }
  subnet      = [for s in local.sub_merged : s.name if contains(s.nodegroups, each.key)]
  tags        = [each.key]
  project     = var.project
  extra_tags  = var.extra_tags
  user_data   = each.value.user_data
  pub_key     = module.key.public_key
  volume_size = each.value.volume_size
}

output "nodes" {
  value = { for k, ng in var.nodegroups : k => module.nodegroup[k].nodes }
}

// locals created after node groups are provisioned.
locals {
  // combine node-group asg & node information after creation
  nodegroups = { for k, ng in var.nodegroups : k => merge(ng, {
    nodes : module.nodegroup[k].nodes
  }) }

  // a safer nodegroup listing that doesn't have any sensitive data.
  nodegroups_safer = { for k, ng in var.nodegroups : k => merge(ng, {
    nodes : [for j, i in module.nodegroup[k].nodes : {
      nodegroup       = k
      index           = j
      id              = "${k}-${j}"
      label           = i.labels
      instance_id     = i.instance_id
      private_ip      = i.network_interface[0].network_ip
      private_dns     = "" // there is not private dns in the instance output
      private_address = trimspace(coalesce("", i.network_interface[0].network_ip, " "))
      public_ip       = i.network_interface[0].access_config[0].nat_ip
      public_dns      = "" // there is not public dns in the instance output
      public_address  = trimspace(coalesce("", i.network_interface[0].access_config[0].nat_ip, " "))
    }]
  }) }
}
