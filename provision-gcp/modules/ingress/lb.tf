resource "random_string" "random_suffix" {
  length  = 5
  special = false
  numeric = false
  upper   = false
}

resource "google_compute_global_address" "ingress" {
  name       = "${var.name}-lb-ipv4-${random_string.random_suffix.result}"
  ip_version = "IPV4"
}

resource "google_compute_health_check" "ingress" {
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
  name                            = "${var.name}-lb-${random_string.random_suffix.result}"
  connection_draining_timeout_sec = 0
  health_checks                   = [google_compute_health_check.ingress.id]
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
  name            = "${var.name}-url-map-https-${random_string.random_suffix.result}"
  default_service = google_compute_backend_service.ingress.id
}

resource "tls_private_key" "rsa" {
  algorithm = "RSA"
}

resource "local_sensitive_file" "private_key" {
  content              = tls_private_key.rsa.private_key_pem
  filename             = "./ssh-keys/${var.name}-tls.pem"
  file_permission      = "0600"
  directory_permission = "0700"
}

resource "tls_self_signed_cert" "ingress" {
  private_key_pem = local_sensitive_file.private_key.content

  subject {
    common_name  = google_compute_global_address.ingress.address
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
  name_prefix = "${var.name}-ingress-"
  description = "SSL Cert for ${var.name} ingress"
  private_key = tls_self_signed_cert.ingress.private_key_pem
  certificate = tls_self_signed_cert.ingress.cert_pem

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_target_https_proxy" "ingress" {
  name             = "${var.name}-https-proxy"
  description      = "HTTPs proxy for ${var.name} ingress"
  url_map          = google_compute_url_map.ingress.self_link
  ssl_certificates = [google_compute_ssl_certificate.ingress.id]
}

resource "google_compute_global_forwarding_rule" "ingress" {
  for_each              = var.rules
  name                  = "${each.key}-https-rule-${random_string.random_suffix.result}"
  ip_protocol           = upper(each.value.protocol)
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "${each.value.port_incoming}-${each.value.port_incoming}"
  target                = google_compute_target_https_proxy.ingress.id
  ip_address            = google_compute_global_address.ingress.id
}
