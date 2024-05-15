
variable "name" {
  description = "cluster/stack name used for identification"
  type        = string
}

variable "project" {
  description = "The project ID to deploy to."
  type        = string

}

variable "region" {
  description = "Azure region for the resources"
  type        = string
}

variable "ssh_pk_location" {
  description = "The location of the SSH private key"
  type        = string
  default     = ""
}

# variable "windows_password" {
#   description = "Password to use with windows & winrm"
#   type        = string
# }
