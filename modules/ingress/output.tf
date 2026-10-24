output "lb_dns" {
  description = "Public address of the ingress."
  value       = var.mode == "tcp" ? google_compute_address.tcp[0].address : google_compute_global_address.ingress[0].address
}

output "target_pool" {
  description = "Target pool backing the tcp-mode NLB; instances are attached by the root module."
  value       = var.mode == "tcp" ? google_compute_target_pool.tcp[0].self_link : null
}

output "google_compute_global_address" {
  description = "Global address (l7_https mode only)."
  value       = var.mode == "tcp" ? null : google_compute_global_address.ingress[0]
}

output "google_compute_backend_service" {
  description = "Backend service (l7_https mode only)."
  value       = var.mode == "tcp" ? null : google_compute_backend_service.ingress[0]
}
