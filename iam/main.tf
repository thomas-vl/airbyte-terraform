resource "google_service_account" "airbyte_admin" {
  account_id   = "airbyte-admin"
  display_name = "Airbyte Cluster Service Account"
}

resource "google_project_iam_member" "secured_webapp_users" {
  for_each = toset(var.airbyte_users)
  project  = var.project
  role     = "roles/iap.httpsResourceAccessor"
  member   = "user:${each.key}"
}

resource "google_service_account_iam_binding" "workload_identity_users" {
  service_account_id = google_service_account.airbyte-admin.id
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "serviceAccount:${google_service_account.airbyte-admin.email}"
  ]
}

resource "google_service_account_iam_binding" "container_admins" {
  service_account_id = google_service_account.airbyte-admin.id
  role               = "roles/container.admin"

  members = [
    "serviceAccount:${google_service_account.airbyte-admin.email}"
  ]
}