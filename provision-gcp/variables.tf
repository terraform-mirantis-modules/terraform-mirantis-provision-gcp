variable "project" {
  description = "The project ID to deploy to."
  type        = string
}

variable "region" {
  description = "The region to deploy to."
  type        = string
}

variable "name" {
  description = "The name of the service account."
  type        = string
}

# === Firewalls ===
variable "firewalls" {
  description = "Network Security group configuration per nodegroup"
  type = map(object({
    description = string
    nodegroups  = list(string) # which nodegroups should get attached to the sg?

    ingress_ipv4 = optional(list(object({
      description                = string
      from_port                  = string
      to_port                    = string
      protocol                   = string
      destination_address_prefix = list(string)
      source_address_prefix      = list(string)
      priority                   = number
    })), [])
    egress_ipv4 = optional(list(object({
      description                = string
      from_port                  = string
      to_port                    = string
      protocol                   = string
      destination_address_prefix = list(string)
      source_address_prefix      = list(string)
      priority                   = number
    })), [])
    tags = optional(map(string), {})
  }))
  default = {}
}

# === Machines ===
variable "nodegroups" {
  description = "A map of machine group definitions"
  type = map(object({
    project               = string
    family                = string
    self_link             = string
    type                  = string
    count                 = number
    volume_size           = number
    role                  = string
    public                = bool
    ssh_user              = string
    user_data             = optional(string)
    instance_profile_name = optional(string)
    tags                  = optional(map(string), {})
  }))
  default = {}
}

# === Subnets ===
variable "subnets" {
  description = "Public subnets configuration"
  type = map(object({
    cidr       = string
    nodegroups = list(string)
    private    = bool
  }))
  default = {}
}

# === Ingresses ===
variable "ingresses" {
  description = "Configure ingress Load Balancer for specific nodegroup roles"
  type = map(object({
    description = string
    nodegroups  = list(string) # which nodegroups should get attached to the ingress

    routes = map(object({
      port_incoming = number
      port_target   = number
      protocol      = string
    }))
    tags = optional(map(string), {})
  }))
  default = {}
}


variable "extra_tags" {
  description = "Extra tags that will be added to all provisioned resources, where possible."
  type        = list(string)
  default     = []
}
