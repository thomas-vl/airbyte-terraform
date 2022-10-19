
resource "google_container_cluster" "airbyte_cluster" {
  name     = "airbyte-cluster"
  location = "europe-west4"
  network  = var.airbyte_network_id

  workload_identity_config {
    workload_pool = "${var.project}.svc.id.goog"
  }
  vertical_pod_autoscaling {
    enabled = true
  }

  remove_default_node_pool = true
  initial_node_count       = 1
  private_cluster_config {
    enable_private_endpoint = false
    enable_private_nodes    = true
    master_ipv4_cidr_block  = "172.16.0.0/28"
    master_global_access_config {
      enabled = true
    }
  }
}

resource "google_container_node_pool" "airbyte-node-pool-4a" {
  name           = "airbyte-4a"
  location       = "europe-west4"
  cluster        = var.cluster_name
  node_locations = ["europe-west4-a"]

  initial_node_count = 1

  autoscaling {
    min_node_count = 1
    max_node_count = 3
  }

  node_config {
    machine_type = "e2-standard-2"
  }
}
