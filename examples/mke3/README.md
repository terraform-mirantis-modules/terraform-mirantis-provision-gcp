# Example: MKE 3 cluster on GCP

Provisions a complete Mirantis Kubernetes Engine 3.x stack with this module
and assembles a ready-to-use `launchpad.yaml` for MCR + MKE (+ optional MSR).

This example lived directly in `examples/` until the directory was split per
example; the files are unchanged apart from the module source paths.

## What it does

1. **Resolves images** - the `platform` sub-module turns a platform key
   (`ubuntu_22.04`, `rocky_9`, `windows_2022`, ...) into a
   `google_compute_image`, so no image self-link is hard-coded.
2. **Provisions infrastructure** - VPC, subnets, VPC firewall rules, an SSH
   key, one managed instance group per nodegroup, and an MKE ingress
   (`mode = "l7_https"`, the default: a global external HTTPS proxy).
3. **Produces a launchpad config** - renders `launchpad.yaml` from the live
   node addresses and the ingress address.

For an ingress that carries client-certificate traffic (the Kubernetes API)
use [`../tcp-ingress`](../tcp-ingress), which exercises `mode = "tcp"`.

## Prerequisites

- Terraform >= 1.0
- Google Application Default Credentials for a project you can create compute
  resources in (`gcloud auth application-default login`)
- `launchpad` CLI for the install step

## Running it

```bash
cp terraform.tfvars.example terraform.tfvars
# edit: name, project (your own GCP project id), region, nodegroups, subnets

terraform init
terraform apply

terraform output -raw launchpad_yaml > launchpad.yaml
launchpad apply -c launchpad.yaml
```

Tear it down when finished:

```bash
terraform destroy
```

## Inputs

| Variable | Description | Default |
|---|---|---|
| `name` | Stack name used in all resource names | - |
| `project` | GCP project id. No default: this module is published, so it carries nobody's project id | - |
| `region` | GCP region | - |
| `nodegroups` | Machine group definitions (platform, type, count, role) | `{}` |
| `subnets` | Subnet CIDRs mapped to nodegroups | `{}` |
| `ssh_pk_location` | Directory to write the generated SSH private key into | `./ssh-keys` |
| `launchpad` | MCR/MKE/MSR versions and MKE admin credentials | - |
| `windows_password` | Windows/WinRM password; generated when empty | `""` |
| `common_tags` | GCP network tags applied to every instance (firewall targets, no values) | `[]` |
| `labels` | GCP labels applied to every resource that supports them, merged over `environment` and `managed_by` | `{}` |

## Outputs

| Output | Description |
|---|---|
| `launchpad_yaml` | Rendered `launchpad.yaml` (sensitive) |
| `MKE_URL` | Address of the MKE ingress |
| `nodegroups` | Nodegroups merged with their provisioned nodes |
| `ingresses` | Ingresses with their addresses |
| `windows_password` | Supplied or generated Windows password (sensitive) |
| `platform` | Resolved image data per platform (sensitive) |

## Notes

The Windows password is generated unless `windows_password` is set. It reaches
Windows instances through instance metadata (`windows-startup-script-ps1`), so
anything able to read the metadata server on those hosts can read it; treat
such instances as disposable. This is also why `modules/platform` marks its
whole output sensitive and why outputs derived from it are sensitive here.
