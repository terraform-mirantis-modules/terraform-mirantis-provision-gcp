// The Windows/WinRM administrator password is generated unless the caller
// supplies one.
//
// An example that requires a password as an input invites a literal in a
// tfvars file or a committed default; that shape produced a real leak in
// the sibling azure repo, where a literal sat in public history for a
// year. Generating by default removes the opportunity - nothing has to be
// typed, pasted or stored - while an explicit value is still honoured, so
// existing callers that pass windows_password keep working unchanged.

variable "windows_password" {
  description = "Password to use with windows & winrm. Leave empty (the default) to have one generated; read it back with `terraform output -raw windows_password`."
  type        = string
  default     = ""
  sensitive   = true
}

resource "random_password" "windows" {
  count = var.windows_password == "" ? 1 : 0

  length  = 24
  special = true

  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
  min_special = 1

  override_special = "!#$%&*()-_=+[]<>:?"
}

locals {
  windows_password = var.windows_password != "" ? var.windows_password : random_password.windows[0].result
}

output "windows_password" {
  description = "Windows/WinRM administrator password, supplied or generated. Read with: terraform output -raw windows_password"
  value       = local.windows_password
  sensitive   = true
}
