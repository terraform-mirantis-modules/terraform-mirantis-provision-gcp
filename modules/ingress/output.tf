output "lb_dns" {
  description = "Public address of the ingress."
  value       = var.mode == "tcp" ? google_compute_address.tcp[0].address : google_compute_global_address.ingress[0].address
}

output "target_pool" {
  description = "Target pool the tcp-mode NLB forwards to (the nodegroup's own pool)."
  value       = var.mode == "tcp" ? var.target_pools[0] : null
}

output "google_compute_global_address" {
  description = "Global address (l7_https mode only)."
  value       = var.mode == "tcp" ? null : google_compute_global_address.ingress[0]
}

output "google_compute_backend_service" {
  description = "Backend service (l7_https mode only)."
  value       = var.mode == "tcp" ? null : google_compute_backend_service.ingress[0]
}
