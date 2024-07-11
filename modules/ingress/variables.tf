variable "name" {
  description = "Names identifier for the ingress"
  type        = string
}

variable "rules" {
  description = "What traffic should the ingress handle"
  type = map(object({
    port_incoming = number
    port_target   = number
    protocol      = string
  }))
}

# variable "tags" {
#   description = "tags to be applied to created resources"
#   type        = map(string)
# }

// GCP variables

variable "target_instance_groups" {
  description = "Instance groups to target with the ingress"
  type        = list(string)
}

