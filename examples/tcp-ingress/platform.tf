// variables calculated before image data is retrieved
locals {
  // collect distinct platform keys from the nodegroups, so each image is
  // looked up once
  unique_used_platforms = distinct([for k, ngd in var.nodegroups : ngd.platform])
}

// The platform module turns a platform key into a google_compute_image and
// the connection metadata (ssh_user, ssh_port) for it.
module "platform" {
  count  = length(local.unique_used_platforms)
  source = "../../modules/platform"

  platform_key = local.unique_used_platforms[count.index]
}

// variables calculated after image data is pulled
locals {
  // convert the platform list to a map keyed by platform name
  platforms_with_image = { for k, p in local.unique_used_platforms : p => module.platform[k].platform }
}
