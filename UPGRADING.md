# Upgrading

## v0.1.x -> v0.2.x

Applying v0.2.x to a stack that was created with v0.1.x replaces network and
compute resources and rolls every node. Read this before changing the module
version on a live stack.

### What changes

1. **Subnets are renamed.** `google_compute_subnetwork.public` changed from
   `name = "${each.key}-subnet"` to `name = "${var.name}-${each.key}-subnet"`
   (`vpc.tf`). The change was made because two stacks in the same project
   collided: `Error 409 ... subnetworks/public-subnet already exists`.
   `name` is immutable on `google_compute_subnetwork`, so the subnet is
   destroyed and recreated.

2. **Instance templates are replaced.** `nodes.tf` passes the subnet *name* to
   the nodegroup module, which uses it as
   `network_interface.subnetwork` in `google_compute_instance_template.provision`
   (`modules/nodegroup/autoscaler.tf`). Instance templates are immutable, so
   the subnet rename forces a new template. The `metadata` map also gained
   `windows-startup-script-ps1` in v0.2.x, which forces the same replacement
   independently.

3. **All nodes are rolled.** `google_compute_instance_group_manager.provision`
   points at the template, so a new template means every instance in every
   nodegroup is recreated, with new private and ephemeral public addresses.
   Any cluster state on those nodes is lost; the cluster has to be
   re-provisioned (launchpad re-run) afterwards.

4. **The VPC-wide firewall rules are gone.** `google_compute_firewall.vpc_ingress`
   and `google_compute_firewall.vpc_egress` (`ingress-vpc` / `egress-vpc`,
   allow-all TCP) were removed in v0.2.1 and are destroyed on upgrade. Traffic
   that relied on them must be covered by an explicit entry in `var.firewalls`.

### What `moved` does and does not cover

`modules/ingress/moved.tf` carries the l7_https ingress resources over the
`count` addition made in v0.2.0 (`google_compute_global_address.ingress` ->
`google_compute_global_address.ingress[0]`, and the health check, backend
service, URL map, TLS key/cert and HTTPS proxy alongside it). Without those
blocks the ingress address and certificate are destroyed and recreated, which
changes the published load balancer IP. With them, the existing objects are
kept.

`moved` cannot help with items 1-4 above. It relocates a resource's *address*
in state; the replacement here is forced by a changed *immutable attribute*
(`name`, and the instance template contents). After a `moved` block the plan
still shows a destroy/create, because the remote object cannot be renamed in
place.

### Upgrade paths

Options, in order of decreasing safety:

- **Deploy a new stack.** Stand up a v0.2.x stack with a different `name`,
  migrate the workload, destroy the v0.1.x stack. The v0.2.0 prefixing exists
  precisely so two stacks can share a project.
- **Pin the old stack.** Keep existing stacks on v0.1.x and use v0.2.x only
  for new deployments.
- **Accept the roll.** Run `terraform plan` first and confirm the scope
  (expect subnet, instance template, instance group manager and the two VPC
  firewall rules). Apply in a maintenance window and re-provision the cluster.
  The subnet cannot be deleted while instances are attached, so the apply
  tears the nodegroups down before recreating them; an interrupted apply can
  leave the stack partially destroyed.
- **State surgery.** There is no in-place path for the subnet rename: GCP
  subnet names cannot be changed, so `terraform state mv` / `import` only ever
  reattaches state to the *old* object, and the next plan renames it again.
  The only variant that works is keeping the old names, which means forking
  the module rather than upgrading it.

These effects were derived from the module source and the v0.1.0..v0.2.1 diff.
They have not been measured by applying an upgrade against a live GCP project.
