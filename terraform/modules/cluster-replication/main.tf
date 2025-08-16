# [START gke_streaming_kafka_standard_private_regional_cluster]
module "kafka_cluster" {
  source                   = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  version                  = "~> 38.0"
  project_id               = var.project_id
  name                     = "${var.cluster_prefix}-cluster"
  regional                 = true
  region                   = var.region
  network                  = var.network
  subnetwork               = var.subnetwork
  ip_range_pods            = "k8s-pod-range"
  ip_range_services        = "k8s-service-range"
  create_service_account   = true
  enable_private_endpoint  = false
  enable_private_nodes     = true
  master_ipv4_cidr_block   = var.master_ipv4_cidr_block
  network_policy           = true
  logging_enabled_components = ["SYSTEM_COMPONENTS","WORKLOADS"]
  monitoring_enabled_components = ["SYSTEM_COMPONENTS"]
  enable_cost_allocation = true
  deletion_protection = false
  initial_node_count = 1

  cluster_dns_domain   = "${var.cluster_prefix}.local"
  cluster_dns_provider = "CLOUD_DNS"
  cluster_dns_scope    = "VPC_SCOPE"

  cluster_resource_labels = {
    name      = "${var.cluster_prefix}-cluster"
    component = "${var.cluster_prefix}-operator"
  }

  monitoring_enable_managed_prometheus = true
  gke_backup_agent_config = true
 
  node_pools = [
    {
      name            = "pool-zookeeper"
      disk_size_gb    = 20
      disk_type       = "pd-standard"
      autoscaling     = true
      min_count       = 1
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
      min_count       = 1
      max_count       = 2
      max_surge       = 1
      max_unavailable = 0
      machine_type    = "e2-standard-2"
      auto_repair     = true
    }
  ]
  node_pools_labels = {
    all = {}
    pool-kafka = {
      "app.stateful/component" = "kafka-broker"
    } 
    pool-zookeeper = {
      "app.stateful/component" = "zookeeper"
    }
  }
  node_pools_taints = {
    all = []
    pool-kafka = [
      {
        key    = "app.stateful/component"
        value  = "kafka-broker"
        effect = "NO_SCHEDULE"
      }
    ]
  }
  gce_pd_csi_driver = true
}
# [END gke_streaming_kafka_standard_private_regional_cluster]

