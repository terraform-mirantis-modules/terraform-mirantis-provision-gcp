name    = "mirantis"
project = "test"
region  = "us-east1"

// Set if having widnows nodes
# windows_password = ""

launchpad = {
  drain       = false
  mcr_version = "23.0.12"
  msr_version = "2.9.12"
  mke_version = "3.7.8"

  mke_connect = {
    username = ""
    password = ""
    insecure = true
  }
  skip_create  = false
  skip_destroy = false
}

nodegroups = {
  "AMngr" = {
    platform    = "ubuntu_22.04"
    count       = 2
    type        = "n1-standard-8"
    role        = "manager"
    public      = true
    volume_size = 100
    user_data   = ""
  },
  "AWrkr" = {
    platform    = "ubuntu_22.04"
    count       = 1
    type        = "n1-standard-4"
    role        = "worker"
    public      = true
    volume_size = 100
  },
  "AMsr" = {
    platform    = "ubuntu_22.04"
    count       = 1
    type        = "n1-standard-4"
    role        = "msr"
    public      = true
    volume_size = 100
  },
}

subnets = {
  "asubnet" = {
    cidr       = "172.31.0.0/18"
    nodegroups = ["AMngr", "AWrkr", "AMsr"]
    private    = false
  },
  # "bsubnet" = {
  #   cidr       = "172.31.64.0/18"
  #   nodegroups = ["AWrkr"]
  #   private    = true
  # },
}

common_tags = [
  "dev",
  "mirantis",
  "mirantis"
]

