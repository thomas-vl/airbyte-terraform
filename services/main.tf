resource "google_project_service" "container" {
  project = var.project
  service = "container.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "secretmanager" {
  project = var.project
  service = "secretmanager.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "networking" {
  project = var.project
  service = "servicenetworking.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "iap" {
  project = var.project
  service = "iap.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "dns" {
  project = var.project
  service = "dns.googleapis.com"
  disable_on_destroy = false
}
