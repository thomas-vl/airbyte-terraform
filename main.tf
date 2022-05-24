locals {
  #change the these 4 values
  project       = "airbyte-test-1"
  support_email = "thomas@example.com"
  domain_name   = "airbyte.example.com"
  airbyte_users = ["thomas@example.com"]

  region   = "europe-west4"
  location = "EU"
}

terraform {
  backend "gcs" {
    #change this to the correct backend
    bucket = "airbyte-test-332519-state"
  }
}

provider "google" {
  project = local.project
  region  = local.region
}

data "google_client_config" "default" {}

provider "helm" {
  kubernetes {
    host                   = "https://${google_container_cluster.airbyte_cluster.endpoint}"
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(google_container_cluster.airbyte_cluster.master_auth[0].cluster_ca_certificate)
  }
}


resource "helm_release" "airbyte" {
  name  = "aibyte-chart"
  chart = "charts/airbyte"

  dependency_update = true
  values = [
    "${file("values.yaml")}",
    <<EOT
serviceAccount:
  annotations:
    {
      iam.gke.io/gcp-service-account: ${google_service_account.airbyte-admin.email}
    }
    EOT
  ]

  set {
    name  = "externalDatabase.host"
    value = module.cloud_sql.private_ip
  }

  set {
    name  = "externalDatabase.user"
    value = module.cloud_sql.database_user
  }

  set {
    name  = "externalDatabase.password"
    value = random_password.database_password.result
  }

  set {
    name  = "logs.gcs.bucket"
    value = module.storage.log_bucket_name
  }

  set {
    name  = "logs.gcs.credentials"
    value = "/secrets/gcs-log-creds/gcp.json"
  }

  set {
    name  = "logs.gcs.credentialsJson"
    value = module.storage.log_writer_key.private_key
  }

}


resource "google_project_iam_member" "secured_webapp_users" {
  for_each = toset(local.airbyte_users)
  project  = local.project
  role     = "roles/iap.httpsResourceAccessor"
  member   = "user:${each.key}"
}

resource "google_compute_network" "airbyte" {
  project = local.project
  name    = "airbyte"
}

resource "google_compute_subnetwork" "airbyte-subnet" {
  project       = local.project
  name          = "airbyte-europe-west4"
  network       = google_compute_network.airbyte.id
  ip_cidr_range = "10.0.0.0/16"
  region        = "europe-west4"
}

resource "google_compute_router" "airbyte-router" {
  project = local.project
  name    = "airbyte-router"
  region  = google_compute_subnetwork.airbyte-subnet.region
  network = google_compute_network.airbyte.id

  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "nat" {
  project                            = local.project
  name                               = "airbyte-router-nat"
  router                             = google_compute_router.airbyte-router.name
  region                             = google_compute_router.airbyte-router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

resource "google_container_cluster" "airbyte_cluster" {
  name     = "airbyte-cluster"
  location = "europe-west4"
  network  = google_compute_network.airbyte.id

  workload_identity_config {
    workload_pool = "${local.project}.svc.id.goog"
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

module "services" {
  source  = "./services"
  project = local.project
}

resource "random_password" "database_password" {
  length  = 16
  special = false
}

resource "google_service_account" "airbyte-admin" {
  depends_on = [
    module.services
  ]
  account_id   = "airbyte-admin"
  display_name = "Airbyte Cluster Service Account"
}

resource "google_project_iam_member" "airbyte-admin-binding" {
  depends_on = [
    helm_release.airbyte
  ]
  for_each = toset(["roles/container.admin", "roles/iam.serviceAccountUser"])
  role     = each.key
  member   = "serviceAccount:${google_service_account.airbyte-admin.email}"
}

resource "google_service_account_iam_binding" "admin-account-iam" {
  service_account_id = google_service_account.airbyte-admin.id
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "serviceAccount:${local.project}.svc.id.goog[default/airbyte-admin]"
  ]
}

module "cloud_iap" {
  depends_on = [
    module.services
  ]
  source        = "./cloud_iap"
  project       = local.project
  support_email = local.support_email
}

resource "google_compute_global_address" "private_ip_alloc" {
  depends_on = [
    module.services
  ]
  name          = "private-ip-alloc"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 24
  network       = google_compute_network.airbyte.id
}

resource "google_service_networking_connection" "service_connection" {
  depends_on = [
    module.services
  ]
  network                 = google_compute_network.airbyte.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_alloc.name]
}

module "cloud_sql" {
  depends_on = [
    google_service_networking_connection.service_connection
  ]
  source            = "./cloud_sql"
  project           = local.project
  region            = local.region
  database_password = random_password.database_password.result
  network           = google_compute_network.airbyte.id
}

module "storage" {
  depends_on = [
    module.services
  ]
  source   = "./storage"
  project  = local.project
  location = local.location
}

module "kubernetes_cluster" {
  depends_on = [
    module.services
  ]
  source = "./kubernetes/cluster"

  project_id   = local.project
  cluster_name = google_container_cluster.airbyte_cluster.name
}


module "load_balancer" {
  depends_on = [
    helm_release.airbyte,
    module.cloud_iap
  ]
  source = "./load_balancer"

  project       = local.project
  region        = local.region
  iap_client_id = module.cloud_iap.iap_client_id
  iap_secret    = module.cloud_iap.iap_secret
  network       = google_compute_network.airbyte.id
  domain_name   = local.domain_name
}
