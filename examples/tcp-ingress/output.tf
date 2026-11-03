// local.nodegroups merges in modules/platform output, which is sensitive as
// a whole, so every output derived from it is sensitive too.
output "nodegroups" {
  description = "Nodegroups merged with their provisioned nodes. Read with: terraform output -json nodegroups"
  value       = local.nodegroups
  sensitive   = true
}

output "ingresses" {
  description = "Ingresses with their addresses. Read with: terraform output -json ingresses"
  value       = local.ingresses
}

// The point of this example: the address the Kubernetes API answers on. In
// tcp mode lb_dns is the regional google_compute_address the forwarding rule
// carries, and the port is the one the nodes listen on, because a
// passthrough LB does not translate ports.
output "kube_api_endpoint" {
  description = "Kubernetes API endpoint behind the passthrough NLB."
  value       = "https://${module.provision.ingresses["kubeapi"].lb_dns}:6443"
}

output "target_pool" {
  description = "Target pool the forwarding rule delivers to. The instance group manager registers its instances there, so scaling needs no LB change."
  value       = module.provision.ingresses["kubeapi"].target_pool
}

output "ssh_connections" {
  description = "SSH connection details per node. Read with: terraform output -json ssh_connections"
  sensitive   = true
  value = merge([for k, ng in local.nodegroups : {
    for n in ng.nodes : n.id => {
      address = n.public_ip
      user    = ng.ssh_user
      port    = ng.ssh_port
      keyPath = abspath(local_sensitive_file.ssh_private_key.filename)
    }
  }]...)
}
