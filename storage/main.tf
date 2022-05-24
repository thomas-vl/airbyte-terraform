resource "google_storage_bucket" "airbyte_logs_bucket" {
  name     = "${var.project}-logs"
  location = var.location

  force_destroy               = true
  uniform_bucket_level_access = true
}

resource "google_service_account" "airbyte_log_writer" {
  account_id   = "airbyte-log-writer"
  display_name = "Airbyte Log Writer"
}

resource "google_service_account_key" "airbyte_log_writer_key" {
  service_account_id = google_service_account.airbyte_log_writer.name
}

resource "google_storage_bucket_iam_binding" "binding" {
  bucket = google_storage_bucket.airbyte_logs_bucket.name
  role   = "roles/storage.admin"
  members = [
    "serviceAccount:${google_service_account.airbyte_log_writer.email}",
  ]
}

output "log_bucket_name" {
  value = google_storage_bucket.airbyte_logs_bucket.name
}

output "log_writer_key" {
  value = google_service_account_key.airbyte_log_writer_key
}
