resource "google_secret_manager_secret" "database_password" {
  secret_id = "database_password"
  
  replication {
      automatic = true
  }
}

resource "google_secret_manager_secret_version" "database_password" {
  secret = google_secret_manager_secret.database_password.id
  secret_data = var.database_password
}