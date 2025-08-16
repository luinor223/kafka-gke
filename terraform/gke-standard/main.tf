data "google_client_config" "default" {}

# create private subnet
module "network" {
  source         = "../modules/network"
  project_id     = var.project_id
  region         = var.region
  cluster_prefix = var.cluster_prefix
}

# [START gke_streaming_kafka_standard_private_regional_cluster]
module "kafka_cluster" {
  source                   = "../modules/cluster"
  project_id               = var.project_id
  region                   = var.region
  cluster_prefix           = var.cluster_prefix
  network                  = module.network.network_name
  subnetwork               = module.network.subnet_name

  node_pools = [
    {
      name            = "pool-system"
      disk_size_gb    = 20
      disk_type       = "pd-standard"    # Cheaper for system pods
      autoscaling     = true
      min_count       = 1                # System pods need space
      max_count       = 2                
      max_surge       = 1
      max_unavailable = 0
      machine_type    = "e2-standard-2"
      auto_repair     = true
    },
    {
      name            = "pool-kafka"
      disk_size_gb    = 20
      disk_type       = "pd-ssd"
      autoscaling     = true
      min_count       = 1                # Start with 1 Kafka node  
      max_count       = 2                
      max_surge       = 1
      max_unavailable = 0
      machine_type    = "e2-standard-2"  # 2 vCPUs each for Kafka
      auto_repair     = true
    }
  ]
  node_pools_labels = {
    all = {}
    pool-system = {
      "node-type" = "system"
    }
    pool-kafka = {
      "app.stateful/component" = "kafka-broker"
    }
  }
  node_pools_taints = {
    all = []
    pool-system = []                   # NO TAINTS - system pods can schedule here
    pool-kafka = [
      {
        key    = "app.stateful/component"
        value  = "kafka-broker"
        effect = "NO_SCHEDULE"         # ONLY Kafka pods can schedule here
      }
    ]
  }
}

output "kubectl_connection_command" {
  value       = "gcloud container clusters get-credentials ${var.cluster_prefix}-cluster --region ${var.region}"
  description = "Connection command"
}
# [END gke_streaming_kafka_standard_private_regional_cluster]

