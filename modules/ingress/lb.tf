locals {
  l7 = var.mode == "l7_https"
  # Passthrough NLBs cannot translate ports: the forwarding rule delivers to
  # the same port on the backend. Routes that remap (port_incoming !=
  # port_target) are rejected in tcp mode; expose the target port directly
  # instead (MKE 4 supports a port in apiServer.externalAddress).
  tcp_rules = var.mode == "tcp" ? var.rules : {}
}

resource "terraform_data" "validate_tcp_rules" {
  count = var.mode == "tcp" ? 1 : 0
  lifecycle {
    precondition {
      condition     = alltrue([for k, r in var.rules : r.port_incoming == r.port_target])
      error_message = "mode=tcp cannot translate ports; every route needs port_incoming == port_target."
    }
    precondition {
      condition     = var.region != ""
      error_message = "mode=tcp requires region."
    }
  }
}

resource "random_string" "random_suffix" {
  length  = 5
  special = false
  numeric = false
  upper   = false
}

resource "google_compute_global_address" "ingress" {
  count      = local.l7 ? 1 : 0
  name       = "${var.name}-lb-ipv4-${random_string.random_suffix.result}"
  ip_version = "IPV4"
}

resource "google_compute_health_check" "ingress" {
  count              = local.l7 ? 1 : 0
  name               = "${var.name}-https-basic-${random_string.random_suffix.result}"
  check_interval_sec = 5
  healthy_threshold  = 2
  https_health_check {
    port = 443
  }
  timeout_sec         = 5
  unhealthy_threshold = 2
}

resource "google_compute_backend_service" "ingress" {
  count                           = local.l7 ? 1 : 0
  name                            = "${var.name}-lb-${random_string.random_suffix.result}"
  connection_draining_timeout_sec = 0
  health_checks                   = [google_compute_health_check.ingress[0].id]
  load_balancing_scheme           = "EXTERNAL_MANAGED"
  port_name                       = "https"
  protocol                        = "HTTPS"
  session_affinity                = "NONE"
  timeout_sec                     = 30

  dynamic "backend" {
    for_each = var.target_instance_groups
    content {
      group           = backend.value
      balancing_mode  = "UTILIZATION"
      capacity_scaler = 1.0
    }
  }
}

resource "google_compute_url_map" "ingress" {
  count           = local.l7 ? 1 : 0
  name            = "${var.name}-url-map-https-${random_string.random_suffix.result}"
  default_service = google_compute_backend_service.ingress[0].id
}

resource "tls_private_key" "rsa" {
  count     = local.l7 ? 1 : 0
  algorithm = "RSA"
}

resource "local_sensitive_file" "private_key" {
  count                = local.l7 ? 1 : 0
  content              = tls_private_key.rsa[0].private_key_pem
  filename             = "./ssh-keys/${var.name}-tls.pem"
  file_permission      = "0600"
  directory_permission = "0700"
}

resource "tls_self_signed_cert" "ingress" {
  count           = local.l7 ? 1 : 0
  private_key_pem = local_sensitive_file.private_key[0].content

  subject {
    common_name  = google_compute_global_address.ingress[0].address
    organization = "Mirantis, Inc"
  }

  validity_period_hours = 12

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "google_compute_ssl_certificate" "ingress" {
  count       = local.l7 ? 1 : 0
  name_prefix = "${var.name}-ingress-"
  description = "SSL Cert for ${var.name} ingress"
  private_key = tls_self_signed_cert.ingress[0].private_key_pem
  certificate = tls_self_signed_cert.ingress[0].cert_pem

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_target_https_proxy" "ingress" {
  count            = local.l7 ? 1 : 0
  name             = "${var.name}-https-proxy"
  description      = "HTTPs proxy for ${var.name} ingress"
  url_map          = google_compute_url_map.ingress[0].self_link
  ssl_certificates = [google_compute_ssl_certificate.ingress[0].id]
}

resource "google_compute_global_forwarding_rule" "ingress" {
  for_each              = local.l7 ? var.rules : {}
  name                  = "${each.key}-https-rule-${random_string.random_suffix.result}"
  ip_protocol           = upper(each.value.protocol)
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "${each.value.port_incoming}-${each.value.port_incoming}"
  target                = google_compute_target_https_proxy.ingress[0].id
  ip_address            = google_compute_global_address.ingress[0].id
}

# === TCP passthrough (regional external NLB) ===

resource "google_compute_address" "tcp" {
  count  = var.mode == "tcp" ? 1 : 0
  name   = "${var.name}-nlb-ipv4-${random_string.random_suffix.result}"
  region = var.region
}

# Legacy HTTP health check: target-pool based NLBs accept only legacy checks.
resource "google_compute_http_health_check" "tcp" {
  count               = var.mode == "tcp" ? 1 : 0
  name                = "${var.name}-tcp-basic-${random_string.random_suffix.result}"
  port                = 10256 # kube-proxy healthz, present on every node
  request_path        = "/healthz"
  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2
}

resource "google_compute_target_pool" "tcp" {
  count         = var.mode == "tcp" ? 1 : 0
  name          = "${var.name}-tcp-pool-${random_string.random_suffix.result}"
  region        = var.region
  health_checks = [google_compute_http_health_check.tcp[0].name]
}

resource "google_compute_forwarding_rule" "tcp" {
  for_each              = local.tcp_rules
  name                  = "${each.key}-tcp-rule-${random_string.random_suffix.result}"
  region                = var.region
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  port_range            = "${each.value.port_incoming}-${each.value.port_incoming}"
  ip_address            = google_compute_address.tcp[0].address
  target                = google_compute_target_pool.tcp[0].self_link
}
