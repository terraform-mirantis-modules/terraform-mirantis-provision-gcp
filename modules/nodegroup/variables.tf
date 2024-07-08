variable "name" {
  description = "The name of the node group."
  type        = string
}

variable "ssh_user" {
  description = "The ssh user to use for the machine."
  type        = string
}

variable "volume_size" {
  description = "The volume size to use for the machine."
  type        = number
}

variable "project" {
  description = "The project to create the node group in."
  type        = string
}

variable "source_image" {
  description = "The source image to use for the machine"
  type = object({
    family    = string
    project   = string
    self_link = string
  })
}

variable "pub_key" {
  description = "GCP public key for the name for nodes"
  type        = string
}

variable "user_data" {
  description = "The user data to apply to the instances"
  type        = string
}

variable "machine_type" {
  description = "The machine type to use for the machine"
  type        = string
}

variable "vm_count" {
  description = "The number of instances to create"
  type        = number
}

variable "subnet" {
  description = "Subnet object to create VMs in"
  type = list(object({
    id      = string
    private = bool
  }))
}

variable "tags" {
  description = "The tags to apply to the instances"
  type        = list(string)
}

variable "extra_tags" {
  description = "The extra tags to apply to the instances"
  type        = list(string)
}
