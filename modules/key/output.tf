output "private_key" {
  description = "Private key contents"
  value       = tls_private_key.rsa.private_key_openssh
}

output "public_key" {
  description = "Public key contents"
  value       = tls_private_key.rsa.public_key_openssh
}
