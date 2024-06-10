// Map the firewalls to their respective subnets
// It's a match between the nodegroups in the subnet and the nodegroups in the firewall
locals {
  mapped_in_firewalls = {
    for firewall, firewall_config in var.firewalls : firewall => { "rules" : [for fck, fcv in firewall_config.ingress_ipv4 : fcv], "nodegroups" : flatten(firewall_config.nodegroups) }
  }
  mapped_out_firewalls = {
    for firewall, firewall_config in var.firewalls : firewall => { "rules" : [for fck, fcv in firewall_config.egress_ipv4 : fcv], "nodegroups" : flatten(firewall_config.nodegroups) }
  }
}

module "firewall_ingress" {
  for_each     = local.mapped_in_firewalls
  source       = "./modules/firewall"
  project      = var.project
  name         = each.key
  rules        = each.value.rules
  nodegroups   = each.value.nodegroups
  direction    = "INGRESS"
  network_link = google_compute_network.vpc.self_link
}

module "firewall_egress" {
  for_each     = local.mapped_out_firewalls
  source       = "./modules/firewall"
  project      = var.project
  name         = each.key
  rules        = each.value.rules
  nodegroups   = each.value.nodegroups
  direction    = "EGRESS"
  network_link = google_compute_network.vpc.self_link
}
