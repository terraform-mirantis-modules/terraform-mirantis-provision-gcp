locals {
  pk_path = var.ssh_pk_location != "" ? join("/", [var.ssh_pk_location, "${var.name}-common.pem"]) : "./ssh-keys/${var.name}-common.pem"
}

resource "local_sensitive_file" "ssh_private_key" {
  content              = module.provision.private_key
  filename             = local.pk_path
  file_permission      = "0600"
  directory_permission = "0700"
}

output "public_key" {
  value = module.provision.public_key
}
