
variable "name" {
  description = "cluster/stack name used for identification"
  type        = string
}

variable "project" {
  description = "The project ID to deploy to."
  type        = string

}

variable "region" {
  description = "GCP region for the resources"
  type        = string
}

variable "ssh_pk_location" {
  description = "The location of the SSH private key"
  type        = string
  default     = ""
}

variable "windows_password" {
  description = "Password to use with windows & winrm"
  type        = string
}

# === Machines ===
variable "nodegroups" {
  description = "A map of machine group definitions"
  type = map(object({
    platform              = string
    type                  = string
    count                 = number
    volume_size           = number
    role                  = string
    public                = bool
    user                  = optional(string)
    user_data             = optional(string)
    instance_profile_name = optional(string)
    tags                  = optional(map(string), {})
  }))
  default = {}
}

# ===  Subnets ===
variable "subnets" {
  description = "Public subnets configuration"
  type = map(object({
    cidr       = string
    nodegroups = list(string)
    private    = bool
  }))
  default = {}
}

variable "common_tags" {
  description = "Tags that should be applied to all resources created"
  type        = list(string)
  default     = []
}
