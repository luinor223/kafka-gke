# [START gke_streaming_kafka_vpc_multi_region_network]
module "gcp-network" {
  source  = "terraform-google-modules/network/google"
  version = "~> 11.1"

  project_id   = var.project_id
  network_name = "${var.cluster_prefix}-vpc"

  subnets = [
    {
      subnet_name           = "${var.cluster_prefix}-source-private-subnet"
      subnet_ip             = "10.10.0.0/24"
      subnet_region         = var.source_region
      subnet_private_access = true
      subnet_flow_logs      = "true"
    },
    {
      subnet_name           = "${var.cluster_prefix}-target-private-subnet"
      subnet_ip             = "10.11.0.0/24"
      subnet_region         = var.target_region
      subnet_private_access = true
      subnet_flow_logs      = "true"
    }
  ]

  secondary_ranges = {
    ("${var.cluster_prefix}-source-private-subnet") = [
      {
        range_name    = "k8s-pod-range"
        ip_cidr_range = "10.48.0.0/20"
      },
      {
        range_name    = "k8s-service-range"
        ip_cidr_range = "10.52.0.0/20"
      },
    ],
    ("${var.cluster_prefix}-target-private-subnet") = [
      {
        range_name    = "k8s-pod-range"
        ip_cidr_range = "10.54.0.0/20"
      },
      {
        range_name    = "k8s-service-range"
        ip_cidr_range = "10.56.0.0/20"
      },
    ]
  }
}

module "firewall_rules" {
  source       = "terraform-google-modules/network/google//modules/firewall-rules"
  project_id   = var.project_id
  network_name = module.gcp-network.network_name

  ingress_rules = [{
    name                    = "allow-kafka-ingress"
    description             = "connection between Kafka clusters with TLS auth"
    source_ranges           = ["10.48.0.0/20","10.54.0.0/20"]
    allow = [{
      protocol = "tcp"
      ports    = ["9093","9094"]
    }]
    deny = []
  }]
}

output "network_name" {
  value = module.gcp-network.network_name
}

output "source_subnet_name" {
  value = module.gcp-network.subnets_names[0]
}

output "target_subnet_name" {
  value = module.gcp-network.subnets_names[1]
}

# [END gke_streaming_kafka_vpc_multi_region_network]

# [START gke_streaming_kafka_cloudnat_simple_create]
module "source_cloud_router" {
  source  = "terraform-google-modules/cloud-router/google"
  version = "~> 7.1"
  project = var.project_id 
  name    = "${var.cluster_prefix}-source-nat-router"
  network = module.gcp-network.network_name
  region  = var.source_region
  nats = [{
    name = "${var.cluster_prefix}-source-nat"
  }]
}

module "target_cloud_router" {
  source  = "terraform-google-modules/cloud-router/google"
  version = "~> 7.1"
  project = var.project_id 
  name    = "${var.cluster_prefix}-target-nat-router"
  network = module.gcp-network.network_name
  region  = var.target_region
  nats = [{
    name = "${var.cluster_prefix}-target-nat"
  }]
}

# [END gke_streaming_kafka_cloudnat_simple_create]
