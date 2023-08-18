locals {
  #change the these 4 values
  project       = "personal-project"
  support_email = "thomas@example.com"
  domain_name   = "airbyte.example.com"
  airbyte_users = ["thomas@example.com"]

  region   = "europe-west4"
  location = "EU"
}

terraform {
  backend "gcs" {
    #change this to the correct backend
    bucket = "personal-project-state"
  }
}

provider "google" {
  project = local.project
  region  = local.region
}

data "google_client_config" "default" {}

provider "helm" {
  kubernetes {
    host                   = "https://${module.kubernetes_cluster.airbyte_cluster.endpoint}"
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(module.kubernetes_cluster.airbyte_cluster.master_auth[0].cluster_ca_certificate)
  }
}

resource "helm_release" "airbyte" {
  name       = "aibyte-chart"
  repository = "https://airbytehq.github.io/helm-charts"
  chart      = "airbyte"
  version    = "0.40.27"

  dependency_update = true
  values            = [
    "${templatefile("values.yaml", { airbyte_sa = module.iam.airbyte_sa.email })}",
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
    name  = "global.logs.gcs.bucket"
    value = module.storage.log_bucket_name
  }

  set {
    name  = "global.logs.gcs.credentials"
    value = "/secrets/gcs-log-creds/gcp.json"
  }

  set {
    name  = "global.logs.gcs.credentialsJson"
    value = module.storage.log_writer_key.private_key
  }
}

resource "random_password" "database_password" {
  length  = 16
  special = false
}

module "services" {
  source  = "./services"
  project = local.project
}

module "networking" {
  depends_on = [module.services]

  source  = "./networking"
  project = local.project
}

module "iam" {
  depends_on = [module.services]

  source           = "./iam"
  project          = local.project
  airbyte_users    = local.airbyte_users
  airbyte_sa_email = module.iam.airbyte_sa.email
}

module "cloud_iap" {
  depends_on    = [module.services]
  source        = "./cloud_iap"
  project       = local.project
  support_email = local.support_email
}

module "cloud_sql" {
  depends_on        = [module.services]
  source            = "./cloud_sql"
  project           = local.project
  region            = local.region
  database_password = random_password.database_password.result
  network           = module.networking.airbyte_network_id
}

module "storage" {
  depends_on = [module.services]
  source     = "./storage"
  project    = local.project
  location   = local.location
}

module "kubernetes_cluster" {
  depends_on = [module.services]
  source     = "./kubernetes/cluster"

  project            = local.project
  airbyte_network_id = module.networking.airbyte_network_id
  cluster_name       = "airbyte-cluster"
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
  network       = module.networking.airbyte_network_id
  domain_name   = local.domain_name
}
