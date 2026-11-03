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
    # A rule carries a range only when from_port names a real lower bound.
    # "*" means "unspecified", not "port zero": pairing it with a numeric
    # to_port produced specifications such as "*-6443", which the API
    # rejects with
    #   Invalid value for field 'resource.allowed[0].ports[0]': '*-6443'.
    #   Invalid port range specification.
    # so a wildcard from_port falls back to the single to_port.
    ports = (
      var.rules[count.index].to_port == "*" ? ["0-65535"] :
      (
        var.rules[count.index].from_port != "*" &&
        var.rules[count.index].from_port != "" &&
        var.rules[count.index].from_port != var.rules[count.index].to_port
      ) ?
      ["${var.rules[count.index].from_port}-${var.rules[count.index].to_port}"] :
      [var.rules[count.index].to_port]
    )
  }
}
