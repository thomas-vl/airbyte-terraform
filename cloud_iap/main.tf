resource "google_iap_brand" "project_brand" {
  support_email     = var.support_email
  application_title = "Cloud IAP protected Application"
  project           = var.project
  lifecycle {
    ignore_changes = [application_title, support_email, project]
  }
}

resource "google_iap_client" "project_client" {
  display_name = "Airbyte IAP Client"
  brand        =  google_iap_brand.project_brand.name
}

output "iap_client_id" {
  value = google_iap_client.project_client.client_id
}

output "iap_secret" {
  value = google_iap_client.project_client.secret
}