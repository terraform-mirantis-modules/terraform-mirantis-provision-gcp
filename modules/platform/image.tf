locals {
  platform = local.lib_platform_definitions[var.platform_key]
}

data "google_compute_image" "upstream" {
  project     = local.lib_platform_definitions[var.platform_key].project
  filter      = local.lib_platform_definitions[var.platform_key].filter
  most_recent = true
}

locals {
  // combine ami/plaftorm data
  platform_with_image = merge(local.platform,
    data.google_compute_image.upstream,
    { key : var.platform_key, name : data.google_compute_image.upstream.name }
  )
}

output "platform_with_image" {
  value     = local.platform_with_image
  sensitive = true
}
