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

## Examples
If you want to see full example, check the [examples folder](./examples).

## License

This project is licensed under the [MIT License].
