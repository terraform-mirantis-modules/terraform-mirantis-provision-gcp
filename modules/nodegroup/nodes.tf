// We have to wait for the instances to come up otherwise we can't get them as data source
resource "time_sleep" "wait_for_machines" {
  depends_on = [google_compute_autoscaler.provision]

  create_duration = "60s"
}

data "google_compute_instance_group" "autoscaler" {
  depends_on = [time_sleep.wait_for_machines]
  name       = google_compute_instance_group_manager.provision.name
  zone       = google_compute_instance_group_manager.provision.zone
}

data "google_compute_instance" "node" {
  count     = var.vm_count
  self_link = tolist(flatten(data.google_compute_instance_group.autoscaler.instances))[count.index]
}

output "nodes" {
  value = { for nk, nv in data.google_compute_instance.node : nk => nv }
}
