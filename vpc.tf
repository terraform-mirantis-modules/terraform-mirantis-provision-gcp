resource "google_compute_network" "vpc" {
  project                                   = var.project
  name                                      = "${var.name}-vpc"
  auto_create_subnetworks                   = false
  network_firewall_policy_enforcement_order = "BEFORE_CLASSIC_FIREWALL"
  mtu                                       = 1460
}

resource "google_compute_firewall" "vpc_ingress" {
  project = var.project
  name    = "ingress-vpc"
  network = google_compute_network.vpc.name

  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "vpc_egress" {
  project = var.project
  name    = "egress-vpc"
  network = google_compute_network.vpc.name

  direction = "EGRESS"

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_subnetwork" "public" {
  for_each                 = var.subnets
  name                     = "${each.key}-subnet"
  description              = "${each.key}-subnet"
  ip_cidr_range            = each.value.cidr
  region                   = var.region
  network                  = google_compute_network.vpc.id
  private_ip_google_access = each.value.private
}

