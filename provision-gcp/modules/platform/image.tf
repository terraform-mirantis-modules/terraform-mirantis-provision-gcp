locals {
  platform = local.lib_platform_definitions[var.platform_key]
  user_data_windows = templatefile("${path.module}/userdata_windows.tpl", {
    windows_administrator_password = var.windows_password
  })
}

output "user_data_windows" {
  value = local.user_data_windows
}

data "google_compute_image" "upstream" {
  project     = local.lib_platform_definitions[var.platform_key].project
  filter      = local.lib_platform_definitions[var.platform_key].filter
  most_recent = true
}

locals {
  // combine ami/plaftorm data (and windows user data)
  platform_with_image = merge(local.platform,
    data.google_compute_image.upstream,
    { key : var.platform_key, name : data.google_compute_image.upstream.name, user_data : startswith(var.platform_key, "windows") ? local.user_data_windows : "" } // TODO: Need to add user_data
  )
}

output "platform_with_image" {
  value     = local.platform_with_image
  sensitive = true
}
