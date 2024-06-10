output "private_key" {
  value = module.key.private_key
}

output "public_key" {
  value = module.key.public_key
}

output "ingresses" {
  description = "Created ingress data including urls"
  value       = local.ingresses_withlb
}

output "nodegroups" {
  value = local.nodegroups_safer
}
