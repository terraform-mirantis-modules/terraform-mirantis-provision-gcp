# Terraform Mirantis Provision GCP

This repository contains Terraform configuration files for provisioning resources on Google Cloud Platform (GCP) dedicated to support Mirantis products.

## Prerequisites

Before you begin, ensure that you have the following:

- Terraform installed on your local machine
- Google Cloud Platform account and project set up


## Usage
```hcl
module "provision" {
  source = "terraform-mirantis-modules/provision-gcp/mirantis"

  region  = var.region
  name    = var.name
  project = var.project
  nodegroups = { for k, ngd in local.nodegroups_wplatform : k => {
    project : ngd.project
    family : ngd.family
    self_link : ngd.self_link
    type : ngd.type
    count : ngd.count
    volume_size : ngd.volume_size
    role : ngd.role
    public : ngd.public
    user_data : ngd.user_data
    ssh_user : ngd.ssh_user
  } }
  subnets    = var.subnets
  firewalls  = local.mke_firewalls
  ingresses  = local.mke_ingresses
  extra_tags = var.common_tags
}
```

## Concepts

The model these modules share with the sibling aws, azure and gcp provision
modules - nodegroups, subnets, security groups, ingresses, and the node
output shape consumers template against - is described in
[CONCEPTS.md](./CONCEPTS.md).

## Examples

The [examples folder](./examples) holds one directory per example:

- [`examples/mke3`](./examples/mke3) - a full MKE 3 stack with the default
  `l7_https` ingress, producing a `launchpad.yaml`.
- [`examples/tcp-ingress`](./examples/tcp-ingress) - `ingresses[].mode = "tcp"`,
  the regional external passthrough NLB needed for client-certificate
  endpoints such as the Kubernetes API; also covers firewall port ranges, UDP
  rules and the Google health-check source ranges.

## Upgrading
Moving an existing stack from v0.1.x to v0.2.x replaces subnets and instance
templates and rolls every node. See [UPGRADING.md](./UPGRADING.md) before
changing the module version on a live stack.

## License

This project is licensed under the [MIT License].
