
output "platform" {
  description = "Image data for the platform"
  value       = local.platform_with_image
  sensitive   = true // may have windows password in it
}
