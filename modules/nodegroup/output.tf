output "instance_group" {
  value = google_compute_instance_group_manager.provision.instance_group
}

output "target_pool" {
  description = "Target pool containing this nodegroup's instances (L4 passthrough ingress)."
  value       = google_compute_target_pool.provision.self_link
}
