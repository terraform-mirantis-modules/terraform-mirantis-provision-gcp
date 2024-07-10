output "private_key" {
  description = "Private key for the keypair"
  value       = module.key.private_key
  sensitive   = true
}

output "public_key" {
  description = "Public key for the keypair"
  value       = module.key.public_key
}

output "ingresses" {
  description = "Created ingress data including urls"
  value       = local.ingresses_withlb
}

output "nodegroups" {
  value = local.nodegroups_safer
}
