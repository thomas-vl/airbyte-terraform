resource "google_sql_database_instance" "instance" {
  name             = "pg-airbyte"
  region           = var.region
  database_version = "POSTGRES_13"
  settings {
    tier = "db-custom-1-3840"
    ip_configuration {
      ipv4_enabled    = false
      private_network = var.network
    }
  }
}

resource "google_sql_database" "airbyte_db" {
  name     = "airbyte"
  instance = google_sql_database_instance.instance.name
}

resource "google_sql_database" "temporal_db" {
  name     = "temporal"
  instance = google_sql_database_instance.instance.name
}

resource "google_sql_database" "temporal_visibility_id" {
  name     = "temporal_visibility"
  instance = google_sql_database_instance.instance.name
}

resource "google_sql_user" "users" {
  name     = "airbyte"
  instance = google_sql_database_instance.instance.name
  password = var.database_password
}

output "private_ip" {
  value = google_sql_database_instance.instance.private_ip_address
}

output "database_user" {
  value = google_sql_user.users.name
}
