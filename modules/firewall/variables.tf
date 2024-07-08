variable "name" {
  description = "The name of the firewall"
  type        = string
}

variable "project" {
  description = "The project ID"
  type        = string

}

variable "network_link" {
  description = "The network link"
  type        = string
}

variable "nodegroups" {
  description = "The nodegroups to attach to the firewall"
  type        = list(string)
}

variable "direction" {
  description = "The direction of the firewall"
  type        = string
}


variable "rules" {
  description = "Firewall rules"
  type = list(object({
    description                = string
    from_port                  = string
    to_port                    = string
    protocol                   = string
    destination_address_prefix = list(string)
    source_address_prefix      = list(string)
    priority                   = number
  }))
  default = []
}
