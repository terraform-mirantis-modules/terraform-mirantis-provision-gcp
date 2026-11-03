# Provision module concepts

This document describes the model shared by the Mirantis Terraform provision
modules for AWS, Azure and GCP. It is mirrored identically in all three
repositories; PRODENG-2907 will decide whether the documentation moves to a
single published home, at which point these copies are replaced by a link.

The point of the shared model is that a cluster definition moves between
clouds by changing only the cloud-specific fields. The same four inputs
describe a stack everywhere, and the same output shape describes the
machines that come back.

## The four inputs

| Input | Describes | Keyed by |
|---|---|---|
| `subnets` | address ranges the machines live in | your name for the subnet |
| `nodegroups` | sets of identical machines | your name for the group |
| `securitygroups` (`firewalls` on GCP) | which traffic reaches which machines | your name for the rule set |
| `ingresses` | load balancers in front of machines | your name for the ingress |

They are maps, not lists, and the keys are yours. Resources are labelled with
them, so a key is worth choosing deliberately: `mgr` and `wrk` read better in
the console than `group1` and `group2`.

The three later inputs refer to nodegroups by key. A subnet lists the
nodegroups placed in it, a security group lists the nodegroups it protects,
an ingress lists the nodegroups it sends traffic to. Nothing refers to an
individual machine, because individual machines do not exist until apply.

```hcl
subnets = {
  "main" = { cidr = "172.31.0.0/17", nodegroups = ["mgr", "wrk"], private = false }
}

nodegroups = {
  "mgr" = { count = 3, role = "manager", ... }
  "wrk" = { count = 2, role = "worker",  ... }
}

ingresses = {
  "mke" = {
    description = "MKE API and UI"
    nodegroups  = ["mgr"]          # not instances
    routes = {
      "api" = { port_incoming = 443, port_target = 443, protocol = "TCP" }
    }
  }
}
```

### Nodegroups

A nodegroup is a set of machines that are identical in every respect the
module cares about: image, size, disk, role, and whether they are publicly
addressable. Three managers are one nodegroup with `count = 3`, not three
nodegroups.

Each cloud implements a nodegroup with its native scaling primitive — an AWS
autoscaling group, an Azure virtual machine scale set, a GCP instance group
manager. Changing `count` resizes the group; the module does not address
machines individually.

`role` is a label the module applies and otherwise ignores. It exists so that
callers can select nodegroups by purpose when building an ingress or
rendering a cluster configuration file, as the examples do with
`role == "manager"`.

### Common and cloud-specific fields

Fields with the same name mean the same thing in all three modules:

| Field | Meaning |
|---|---|
| `type` | machine size, in the cloud's own vocabulary |
| `count` | how many machines |
| `volume_size` | root disk size in GB |
| `role` | caller-defined purpose label |
| `public` | whether machines get a public address |
| `user_data` | cloud-init or equivalent, run at first boot |
| `tags` | tags applied to the group's resources |

The image reference is necessarily cloud-specific, because the clouds do not
describe images the same way:

| Cloud | `source_image` |
|---|---|
| AWS | `{ ami }` |
| Azure | `{ publisher, offer, sku, version, plan }` |
| GCP | `{ project, family, self_link }` |

Other cloud-specific fields exist where a cloud has no equivalent elsewhere:
AWS takes `keypair_id`, `root_device_name`, `metadata_options`,
`instance_profile_name` and `volume_encrypted`; Azure takes `vm_size` and
`user`; GCP takes `ssh_user`.

### Subnets

A subnet carries a CIDR, the nodegroups placed in it, and whether it is
private. `private = true` means machines in it have no public address,
whatever a nodegroup asks for; the two settings are combined, and the more
restrictive one wins.

Striping a nodegroup across several subnets is how you spread it across
availability zones: list the same nodegroup key in more than one subnet.

### Security groups and firewalls

AWS and Azure call this input `securitygroups`; GCP calls it `firewalls`,
because that is what the resources are called there. The shape is otherwise
the same: a description, the nodegroups it applies to, and lists of ingress
and egress rules.

Rule fields differ by cloud, and the differences are not cosmetic:

| | AWS | Azure | GCP |
|---|---|---|---|
| source/destination | `cidr_blocks` (list) | `source_address_prefix`, `destination_address_prefix` (string) | `source_address_prefix`, `destination_address_prefix` (list) |
| ports | `from_port`, `to_port` (number) | `from_port`, `to_port` (string) | `from_port`, `to_port` (string) |
| rule ordering | implicit | `priority` (required) | `priority` |
| self-reference | `self = true` | application security groups | target tags |

An empty `egress_ipv4 = []` does not mean "deny all outbound". It means the
module creates no egress rule, leaving the cloud's default in place, which on
all three clouds is to allow outbound traffic.

### Ingresses

An ingress is a load balancer in front of one or more nodegroups. Each
`routes` entry is a listener: traffic arriving on `port_incoming` is sent to
`port_target` on the machines.

The ingress attaches the **group**, not its machines. This matters because a
group handle exists in your configuration while a machine id does not exist
until after apply:

| Cloud | How the group is attached |
|---|---|
| AWS | `aws_autoscaling_attachment` per route and nodegroup |
| Azure | `lb_pool_ids` set on the scale set's network interface |
| GCP | `target_instance_groups` / `target_pools` handed to the ingress |

The practical consequence is that membership follows the group with no
terraform run: scaling a nodegroup adds and removes load balancer targets by
itself, and produces no diff in a subsequent plan.

GCP additionally takes `mode` on each ingress. The default `l7_https` is a
global HTTPS proxy that terminates TLS. `tcp` is a regional passthrough
network load balancer and is required for endpoints that need the client's
TLS session to reach the machine unbroken, such as a Kubernetes API server
doing client-certificate authentication. Passthrough load balancers cannot
translate ports, so in `tcp` mode every route must have
`port_incoming == port_target`.

## The output shape

Every module returns `nodegroups`, a map keyed exactly as the input was, with
each entry carrying the input definition plus a `nodes` list. Every node has
the same fields on every cloud:

| Field | Meaning |
|---|---|
| `nodegroup` | the nodegroup key |
| `index` | position within the group |
| `id` | `<nodegroup>-<index>` |
| `label` | `<stack>-<nodegroup>-<index>` |
| `instance_id` | the cloud's own identifier |
| `private_ip`, `private_dns`, `private_address` | internal addressing |
| `public_ip`, `public_dns`, `public_address` | external addressing, empty when the node is private |

`private_address` and `public_address` are the ones to template against: each
resolves to the DNS name where the cloud provides one and the IP address
otherwise, so a consumer does not have to care which exists.

`ingresses` is returned the same way — the input map plus `lb_dns`, the
address the load balancer answers on. On AWS it is a DNS name; on Azure and
GCP it is an IP address. Treat it as an opaque address.

This shape is what makes the modules interchangeable in practice. A consumer
that renders an inventory, a `launchpad.yaml` or a `k0sctl.yaml` reads the
same fields regardless of which cloud produced them.

```hcl
output "inventory" {
  value = {
    for k, ng in module.provision.nodegroups : k => [
      for n in ng.nodes : { host = n.public_address, role = ng.role }
    ]
  }
}
```

## Things that surprise people

**Machine identifiers do not exist at plan time.** Anything derived from them
is unknown until apply, which is why the modules address load balancer
membership by group. A configuration that uses a machine id as a map key
cannot be planned on a fresh stack.

**`public = false` is not a firewall.** It controls whether a public address
is assigned. Reachability is decided by the security group or firewall rules.

**Images resolve newest-match by default.** The platform submodules look up
the most recent image matching a pattern, so an apply months later can select
a newer image and replace machines. Where determinism matters, pin the image:
AWS's platform submodule takes an `ami` input that skips the lookup entirely.

**Role names are not special.** `manager`, `worker` and `msr` carry no meaning
inside the modules. They matter only to the caller selecting nodegroups.

## Per-module documentation

Each repository's `README.md` documents its own inputs, outputs and
cloud-specific behaviour, and `examples/` holds runnable configurations with
their own READMEs:

- [terraform-mirantis-provision-aws](https://github.com/terraform-mirantis-modules/terraform-mirantis-provision-aws)
- [terraform-mirantis-provision-azure](https://github.com/terraform-mirantis-modules/terraform-mirantis-provision-azure)
- [terraform-mirantis-provision-gcp](https://github.com/terraform-mirantis-modules/terraform-mirantis-provision-gcp)
