// Resolve each nodegroup against its platform entry. The platform supplies
// the image (project/family/self_link) and the connection metadata
// (ssh_user, ssh_port).
locals {
  nodegroups_wplatform = { for k, ngd in var.nodegroups : k => merge(ngd, local.platforms_with_image[ngd.platform]) }

  // The single nodegroup the passthrough NLB forwards to. modules/ingress
  // rejects mode = "tcp" with anything other than exactly one nodegroup,
  // because a forwarding rule targets exactly one target pool.
  manager_nodegroups = [for k, ng in var.nodegroups : k if ng.role == "manager"]

  // Source ranges for traffic that must stay inside the stack.
  subnet_cidrs = [for k, s in var.subnets : s.cidr]

  // Google's load balancer health checkers probe from these two ranges, and
  // from nowhere else. A passthrough NLB delivers the probe to the node
  // itself, so the VPC firewall has to admit them explicitly or every
  // backend is marked unhealthy.
  healthcheck_source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
}

locals {
  cluster_firewalls = {
    // Rules every node needs. Each generated google_compute_firewall is
    // named "<firewall key>-<rule description>-<direction>" (observed:
    // "node-vxlan-ingress"), so rule descriptions are lowercase, free of
    // spaces, and unique within a key and direction.
    "node" = {
      description = "Traffic every cluster node accepts"
      nodegroups  = keys(var.nodegroups)
      ingress_ipv4 = [
        {
          description                = "ssh"
          from_port                  = "22"
          to_port                    = "22"
          protocol                   = "tcp"
          source_address_prefix      = ["0.0.0.0/0"]
          destination_address_prefix = ["0.0.0.0/0"]
          priority                   = 1001
        },
        {
          // VXLAN overlay traffic between nodes. UDP, which no other example
          // covers: the firewall module passes the protocol straight through
          // to google_compute_firewall.allow.protocol.
          description                = "vxlan"
          from_port                  = "4789"
          to_port                    = "4789"
          protocol                   = "udp"
          source_address_prefix      = local.subnet_cidrs
          destination_address_prefix = ["0.0.0.0/0"]
          priority                   = 1002
        },
        {
          // A port range rather than a single port: from_port != to_port
          // makes the firewall module emit ports = ["30000-32767"]. The
          // Kubernetes NodePort range.
          description                = "nodeports"
          from_port                  = "30000"
          to_port                    = "32767"
          protocol                   = "tcp"
          source_address_prefix      = ["0.0.0.0/0"]
          destination_address_prefix = ["0.0.0.0/0"]
          priority                   = 1003
        },
      ]
      // No egress rules: GCP's implied allow-egress rule already permits all
      // outbound traffic, so an explicit egress firewall would only restate
      // it. An empty list produces no google_compute_firewall at all.
      egress_ipv4 = []
    }

    // Rules only the manager nodegroup needs, attached by nodegroup rather
    // than to the whole stack.
    "api" = {
      description = "Kubernetes API reachable through the passthrough NLB"
      nodegroups  = local.manager_nodegroups
      ingress_ipv4 = [
        {
          description                = "kube-api"
          from_port                  = "6443"
          to_port                    = "6443"
          protocol                   = "tcp"
          source_address_prefix      = var.api_source_ranges
          destination_address_prefix = ["0.0.0.0/0"]
          priority                   = 1004
        },
        {
          description                = "healthcheck"
          from_port                  = "6443"
          to_port                    = "6443"
          protocol                   = "tcp"
          source_address_prefix      = local.healthcheck_source_ranges
          destination_address_prefix = ["0.0.0.0/0"]
          priority                   = 1005
        },
      ]
      egress_ipv4 = []
    }
  }

  // The point of this example: mode = "tcp". The default l7_https mode puts
  // a global external HTTPS proxy in front of the nodes, which terminates
  // TLS and so cannot carry client certificates. The Kubernetes API
  // authenticates clients with certificates, so it needs a passthrough LB:
  // mode = "tcp" creates a regional external forwarding rule onto the
  // nodegroup's target pool instead.
  //
  // Passthrough forwarding cannot translate ports, so the route maps
  // 6443 -> 6443. modules/ingress enforces that, that region is set, and
  // that exactly one nodegroup is listed.
  cluster_ingresses = {
    "kubeapi" = {
      description = "Kubernetes API endpoint"
      nodegroups  = local.manager_nodegroups
      mode        = "tcp"

      routes = {
        "kube" = {
          port_incoming = 6443
          port_target   = 6443
          protocol      = "TCP"
        }
      }
    }
  }
}

module "provision" {
  source = "../../"

  name    = var.name
  project = var.project
  region  = var.region

  nodegroups = { for k, ngd in local.nodegroups_wplatform : k => {
    source_image : {
      project : ngd.project
      family : ngd.family
      self_link : ngd.self_link
    }
    type : ngd.type
    count : ngd.count
    volume_size : ngd.volume_size
    role : ngd.role
    public : ngd.public
    user_data : ngd.user_data
    ssh_user : ngd.ssh_user
  } }

  subnets    = var.subnets
  firewalls  = local.cluster_firewalls
  ingresses  = local.cluster_ingresses
  extra_tags = local.tags
}

// locals calculated after the provision run
locals {
  // combine each nodegroup & platform definition with the provisioned nodes
  nodegroups = { for k, ngp in local.nodegroups_wplatform : k => merge({ "name" : k }, ngp, module.provision.nodegroups[k]) }
  ingresses  = { for k, i in local.cluster_ingresses : k => merge({ "name" : k }, i, module.provision.ingresses[k]) }
}
