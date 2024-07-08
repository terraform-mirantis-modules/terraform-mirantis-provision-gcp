resource "google_compute_firewall" "provision" {
  count   = length(var.rules)
  project = var.project
  name    = "${var.name}-${lower(var.rules[count.index].description)}-${lower(var.direction)}"
  network = var.network_link

  direction = upper(var.direction)

  priority      = var.rules[count.index].priority
  source_ranges = var.rules[count.index].source_address_prefix
  target_tags   = [for n in var.nodegroups : lower(n)]
  allow {
    protocol = var.rules[count.index].protocol
    ports    = var.rules[count.index].to_port == "*" ? ["0-65535"] : [var.rules[count.index].to_port]
  }
}
