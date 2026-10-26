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


variable "mode" {
  description = "Ingress implementation: \"l7_https\" (global external HTTPS proxy, terminates TLS) or \"tcp\" (regional external passthrough NLB; required for client-certificate/mTLS endpoints such as the Kubernetes API, which cannot traverse an HTTPS proxy)."
  type        = string
  default     = "l7_https"

  validation {
    condition     = contains(["l7_https", "tcp"], var.mode)
    error_message = "mode must be \"l7_https\" or \"tcp\"."
  }
}

variable "region" {
  description = "Region for the regional resources created when mode = \"tcp\"."
  type        = string
  default     = ""
}

variable "target_pools" {
  description = "Target pools to forward to when mode = \"tcp\"."
  type        = list(string)
  default     = []
}
