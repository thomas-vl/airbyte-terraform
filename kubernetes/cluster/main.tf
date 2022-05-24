
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

# resource "google_container_node_pool" "airbyte-node-pool-4b" {
#   name       = "airbyte-4b"
#   location   = "europe-west4"
#   cluster    = var.cluster_name
#   node_locations = ["europe-west4-b"]

#   autoscaling {
#     min_node_count = 1
#     max_node_count = 3
#   }

#   node_config {
#     machine_type = "e2-medium"
#   }
# }

# resource "google_container_node_pool" "airbyte-node-pool-4c" {
#   name       = "airbyte-4c"
#   location   = "europe-west4"
#   cluster    = var.cluster_name
#   node_locations = ["europe-west4-c"]

#   autoscaling {
#     min_node_count = 1
#     max_node_count = 3
#   }

#   node_config {
#     machine_type = "e2-medium"
#   }
# }
