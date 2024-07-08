output "instance_group" {
  value = google_compute_instance_group_manager.provision.instance_group
}

output "managed_tags" {
  value = google_compute_instance_template.provision.resource_manager_tags
}
