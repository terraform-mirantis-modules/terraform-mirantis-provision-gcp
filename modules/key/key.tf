resource "tls_private_key" "rsa" {
  algorithm = "RSA"
}

resource "local_sensitive_file" "ssh_pub_key" {
  content              = tls_private_key.rsa.public_key_openssh
  filename             = "./ssh-keys/${var.name}-common.pub"
  file_permission      = "0600"
  directory_permission = "0700"
}

data "google_client_openid_userinfo" "sa" {
}

resource "google_os_login_ssh_public_key" "rsa" {
  user = data.google_client_openid_userinfo.sa.email
  key  = local_sensitive_file.ssh_pub_key.content
}
