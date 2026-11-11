# TCP passthrough ingress example

Provisions a two-nodegroup stack whose ingress uses `mode = "tcp"` instead of
the default `l7_https`, to exercise the parts of the module no other example
reaches:

- **`ingresses[].mode = "tcp"`** - a regional external passthrough NLB
  (`google_compute_address` + `google_compute_forwarding_rule`,
  `load_balancing_scheme = "EXTERNAL"`) instead of the global external HTTPS
  proxy. The default mode terminates TLS, so it cannot carry client
  certificates; the Kubernetes API authenticates clients with certificates
  and therefore needs a passthrough load balancer.
- **a port range in a firewall rule** - the NodePort range 30000-32767, where
  `from_port != to_port`, so `modules/firewall` emits
  `ports = ["30000-32767"]` rather than a single port.
- **a UDP rule** - VXLAN on 4789, restricted to the subnet CIDRs.
- **the Google load balancer health-check source ranges** - 35.191.0.0/16 and
  130.211.0.0/22 admitted on 6443. A passthrough LB delivers the health probe
  to the node itself, so without this rule every backend is marked unhealthy.
- **`egress_ipv4 = []`** on both firewalls, relying on GCP's implied
  allow-egress rule. An empty list produces no `google_compute_firewall`.

For a full MKE 3 stack on the default `l7_https` ingress use
[`../mke3`](../mke3).

## Constraints that `mode = "tcp"` imposes

`modules/ingress/lb.tf` enforces three preconditions, and this example is
shaped around them:

| Precondition | Why | Here |
|---|---|---|
| every route has `port_incoming == port_target` | a passthrough rule cannot translate ports | the single route is 6443 -> 6443 |
| `region` must be set | the address and forwarding rule are regional | `region` is a required input |
| exactly one nodegroup | a forwarding rule targets one target pool | a `nodegroups` validation requires exactly one `role = "manager"` group |

The forwarding rule targets the nodegroup's own target pool, which the
instance group manager keeps populated, so scaling the nodegroup needs no
load balancer change.

## Prerequisites

- Terraform >= 1.0
- Google Application Default Credentials for a project you can create compute
  resources in (`gcloud auth application-default login`)

## Running it

```bash
cp terraform.tfvars.example terraform.tfvars
# edit: name, project (your own GCP project id), region, nodegroups, subnets

terraform init
terraform apply
```

Read the endpoint out:

```bash
terraform output -raw  kube_api_endpoint
terraform output -json ingresses
terraform output -json ssh_connections
```

Nothing listens on 6443 unless a Kubernetes control plane is installed on the
manager node; the ingress is provisioned regardless, so the forwarding rule
and firewall shape can be checked without one:

```bash
gcloud compute forwarding-rules list --filter="name~tcp-rule"
```

Tear it down when finished:

```bash
terraform destroy
```

## Inputs

| Variable | Description | Default |
|---|---|---|
| `name` | Stack name, used in resource names and as a network tag | - |
| `project` | GCP project id. No default: this module is published, so it carries nobody's project id | - |
| `region` | GCP region; `mode = "tcp"` creates regional resources there | - |
| `nodegroups` | Machine group definitions; exactly one must have `role = "manager"` | - |
| `subnets` | Subnet CIDRs mapped to nodegroups | - |
| `api_source_ranges` | CIDRs allowed to reach 6443 | `["0.0.0.0/0"]` |
| `ssh_pk_location` | Directory to write the generated SSH private key into | `./ssh-keys` |
| `extra_tags` | Extra GCP network tags applied to every instance | `[]` |
| `labels` | GCP labels applied to every resource that supports them, merged over `environment` and `managed_by` | `{}` |

## Outputs

| Output | Description |
|---|---|
| `kube_api_endpoint` | `https://<nlb address>:6443` |
| `ingresses` | Ingresses with their addresses and target pool |
| `target_pool` | Target pool the forwarding rule delivers to |
| `nodegroups` | Nodegroups merged with their provisioned nodes (sensitive) |
| `ssh_connections` | Address, user, port and key path per node (sensitive) |
| `public_key` | Public half of the generated keypair |

## Notes

A passthrough NLB preserves the client source address: `api_source_ranges`
filters the real client, not the load balancer. The default
`["0.0.0.0/0"]` exposes 6443 to the internet; narrow it before using this
anywhere that matters.

`nodegroups` and `ssh_connections` are sensitive because they are derived
from `modules/platform`, whose output is sensitive as a whole. Outputs that
read from it without that marking fail with "Output refers to sensitive
values".
