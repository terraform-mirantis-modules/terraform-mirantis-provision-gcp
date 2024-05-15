resource "google_compute_network" "vpc" {
  project                                   = var.project
  name                                      = "${var.name}-vpc"
  auto_create_subnetworks                   = false
  network_firewall_policy_enforcement_order = "BEFORE_CLASSIC_FIREWALL"
  mtu                                       = 1460
}

resource "google_compute_subnetwork" "vpc" {
  # count         = var.network.public_subnet_count > length(data.google_compute_zones.available.names) ? length(data.google_compute_zones.available.names) : var.network.public_subnet_count
  count         = var.network.public_subnet_count
  name          = "${var.name}-subnet-${count.index}"
  description   = "${var.name}-subnet-${count.index}"
  ip_cidr_range = cidrsubnet(var.network.cidr, 4, count.index)
  region        = var.region
  network       = google_compute_network.vpc.id
}


# resource "google_compute_firewall" "default" {
#   name    = "test-firewall"
#   network = google_compute_network.main.name

#   allow {
#     protocol = "icmp"
#   }

#   allow {
#     protocol = "tcp"
#     ports    = ["80", "8080", "1000-2000"]
#   }

#   source_tags = ["web"]
# }


# # Create a virtual network within the resource group
# resource "azurerm_subnet" "public_subnet" {
#   name                 = "public-subnet"
#   resource_group_name  = azurerm_resource_group.rg.name
#   virtual_network_name = azurerm_virtual_network.main.name
#   address_prefixes     = [var.network.cidr]
# }

# resource "azurerm_public_ip" "public_ip" {
#   name                = var.name
#   region            = azurerm_resource_group.rg.region
#   resource_group_name = azurerm_resource_group.rg.name
#   alregion_method   = "Dynamic"
# }
