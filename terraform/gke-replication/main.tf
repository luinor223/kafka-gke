data "google_client_config" "default" {}

# create private subnets for two clusters
module "network" {
  source         = "../modules/network-replication"
  project_id     = var.project_id
  cluster_prefix = var.cluster_prefix
  source_region  = var.source_region
  target_region  = var.target_region
}

# [START gke_streaming_kafka_standard_private_regional_cluster]
module "source_kafka_cluster" {
  source                   = "../modules/cluster-replication"
  project_id               = var.project_id
  region                   = var.source_region
  cluster_prefix           = "${var.cluster_prefix}-source"
  network                  = module.network.network_name
  subnetwork               = module.network.source_subnet_name
  master_ipv4_cidr_block   = "172.16.0.0/28"
}

module "target_kafka_cluster" {
  source                   = "../modules/cluster-replication"
  project_id               = var.project_id
  region                   = var.target_region
  cluster_prefix           = "${var.cluster_prefix}-target"
  network                  = module.network.network_name
  subnetwork               = module.network.target_subnet_name
  master_ipv4_cidr_block   = "172.17.0.0/28"
}

output "kubectl_connection_command_source" {
  value       = "gcloud container clusters get-credentials ${var.cluster_prefix}-source-cluster --region ${var.source_region}"
  description = "Connection command for source cluster"
}

output "kubectl_connection_command_target" {
  value       = "gcloud container clusters get-credentials ${var.cluster_prefix}-target-cluster --region ${var.target_region}"
  description = "Connection command for target cluster"
}
# [END gke_streaming_kafka_standard_private_regional_cluster]

