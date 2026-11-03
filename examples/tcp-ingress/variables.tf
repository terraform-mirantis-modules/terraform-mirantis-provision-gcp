variable "name" {
  description = "Stack name used in the name of every provisioned resource. Lowercase letters, digits and hyphens only: it is used in GCP resource names and network tags."
  type        = string
}

variable "project" {
  description = "GCP project id to deploy into. No default: this module is published, so it carries nobody's project id."
  type        = string
}

variable "region" {
  description = "GCP region. mode = \"tcp\" creates regional resources (a regional address and forwarding rule), so this region is where the NLB lives."
  type        = string
}

# === Machines ===
variable "nodegroups" {
  description = "Machine group definitions. Exactly one group must carry role = \"manager\": mode = \"tcp\" forwards to a single nodegroup target pool."
  type = map(object({
    platform    = string
    type        = string
    count       = number
    volume_size = number
    role        = string
    public      = bool
    user_data   = optional(string, "")
  }))

  validation {
    condition     = length([for k, ng in var.nodegroups : k if ng.role == "manager"]) == 1
    error_message = "mode = \"tcp\" forwards to exactly one nodegroup target pool (modules/ingress/lb.tf precondition), so exactly one nodegroup must have role = \"manager\"."
  }
}

# === Subnets ===
variable "subnets" {
  description = "Subnet configuration."
  type = map(object({
    cidr       = string
    nodegroups = list(string)
    private    = bool
  }))
}

variable "ssh_pk_location" {
  description = "Directory to write the generated SSH private key into. Defaults to ./ssh-keys."
  type        = string
  default     = ""
}

variable "api_source_ranges" {
  description = "CIDRs allowed to reach the Kubernetes API through the passthrough NLB. The passthrough LB preserves the client address, so this filter applies to the real client."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "extra_tags" {
  description = "Extra GCP network tags applied to every instance. Network tags, not labels: lowercase letters, digits and hyphens only."
  type        = list(string)
  default     = []
}
