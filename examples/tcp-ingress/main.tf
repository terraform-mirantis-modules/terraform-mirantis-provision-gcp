locals {
  // GCP network tags, not labels: the root module feeds extra_tags straight
  // into google_compute_instance_template.tags, which only accepts
  // lowercase RFC1035 labels. No timestamp is added for that reason.
  tags = distinct(concat([lower(var.name)], var.extra_tags))
}
