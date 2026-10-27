// v0.1.x -> v0.2.x state moves.
//
// The l7_https resources below gained `count = local.l7 ? 1 : 0` when the tcp
// passthrough mode was added, which changes their state addresses from
// `<resource>` to `<resource>[0]`. Without these blocks terraform plans a
// destroy/create of the global address, certificate, proxy and backend
// service, which changes the ingress IP. These are address-only moves, so
// terraform can carry the existing objects over unchanged.
//
// These blocks do not help with the v0.2.0 resource renames (subnets,
// VPC firewall rules): those change an immutable `name` attribute rather than
// a state address, and `moved` cannot prevent the resulting replacement. See
// UPGRADING.md.

moved {
  from = google_compute_global_address.ingress
  to   = google_compute_global_address.ingress[0]
}

moved {
  from = google_compute_health_check.ingress
  to   = google_compute_health_check.ingress[0]
}

moved {
  from = google_compute_backend_service.ingress
  to   = google_compute_backend_service.ingress[0]
}

moved {
  from = google_compute_url_map.ingress
  to   = google_compute_url_map.ingress[0]
}

moved {
  from = tls_private_key.rsa
  to   = tls_private_key.rsa[0]
}

moved {
  from = local_sensitive_file.private_key
  to   = local_sensitive_file.private_key[0]
}

moved {
  from = tls_self_signed_cert.ingress
  to   = tls_self_signed_cert.ingress[0]
}

moved {
  from = google_compute_ssl_certificate.ingress
  to   = google_compute_ssl_certificate.ingress[0]
}

moved {
  from = google_compute_target_https_proxy.ingress
  to   = google_compute_target_https_proxy.ingress[0]
}
