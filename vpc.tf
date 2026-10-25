resource "google_compute_network" "vpc" {
  project                                   = var.project
  name                                      = "${var.name}-vpc"
  auto_create_subnetworks                   = false
  network_firewall_policy_enforcement_order = "BEFORE_CLASSIC_FIREWALL"
  mtu                                       = 1460
}

resource "google_compute_subnetwork" "public" {
  for_each                 = var.subnets
  name                     = "${var.name}-${each.key}-subnet"
  description              = "${each.key}-subnet"
  ip_cidr_range            = each.value.cidr
  region                   = var.region
  network                  = google_compute_network.vpc.id
  private_ip_google_access = each.value.private
}

