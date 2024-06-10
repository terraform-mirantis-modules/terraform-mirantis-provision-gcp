output "lb_dns" {
  description = "DNS entry for the ingress"
  value       = google_compute_global_address.ingress.address
}

output "google_compute_global_address" {
  value = google_compute_global_address.ingress
}

output "google_compute_backend_service" {
  value = google_compute_backend_service.ingress
}
