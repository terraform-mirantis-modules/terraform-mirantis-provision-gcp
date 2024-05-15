module "provision" {
  source  = "./provision-gcp"
  region  = var.region
  name    = var.name
  project = var.project
}
