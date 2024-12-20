data "google_compute_zones" "available" {}

output "zones" {
  value = data.google_compute_zones.available.names
}

resource "random_string" "random_suffix" {
  length  = 5
  special = false
  numeric = false
  upper   = false
}

resource "google_compute_autoscaler" "provision" {
  name   = "${var.name}-${random_string.random_suffix.result}"
  zone   = data.google_compute_zones.available.names[0]
  target = google_compute_instance_group_manager.provision.self_link

  autoscaling_policy {
    max_replicas    = var.vm_count
    min_replicas    = var.vm_count
    cooldown_period = 60
  }
}

resource "google_compute_instance_template" "provision" {
  name           = "${random_string.random_suffix.result}-template"
  machine_type   = var.machine_type
  can_ip_forward = false

  tags = concat(var.extra_tags, [for t in var.tags : lower(t)])

  disk {
    source_image = var.source_image.self_link
    disk_size_gb = var.volume_size
    disk_type    = "pd-balanced"
  }

  dynamic "network_interface" {
    // This can be specified multiple times
    for_each = var.subnet
    content {
      subnetwork = network_interface.value.id
      dynamic "access_config" {
        for_each = network_interface.value.private ? [] : [0]
        content {
          // Ephemeral IP
        }
      }
    }
  }

  metadata = {
    name                       = var.name
    ssh-keys                   = "${var.ssh_user}:${var.pub_key}"
    windows-startup-script-ps1 = var.user_data
  }

  metadata_startup_script = var.user_data

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }
}

resource "google_compute_target_pool" "provision" {
  name = "${random_string.random_suffix.result}-target-pool"
}

resource "google_compute_instance_group_manager" "provision" {
  name = "${random_string.random_suffix.result}-igm"
  zone = data.google_compute_zones.available.names[0]

  named_port {
    name = "http"
    port = 80
  }

  named_port {
    name = "https"
    port = 443
  }

  version {
    instance_template = google_compute_instance_template.provision.self_link
    name              = "primary"
  }

  target_pools       = [google_compute_target_pool.provision.self_link]
  base_instance_name = var.name
}
