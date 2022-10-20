resource "google_compute_network" "airbyte" {
  project = var.project
  name    = "airbyte"
}

resource "google_compute_subnetwork" "airbyte-subnet" {
  project       = var.project
  name          = "airbyte-europe-west4"
  network       = google_compute_network.airbyte.id
  ip_cidr_range = "10.0.0.0/16"
  region        = "europe-west4"
}

resource "google_compute_router" "airbyte-router" {
  project = var.project
  name    = "airbyte-router"
  region  = google_compute_subnetwork.airbyte-subnet.region
  network = google_compute_network.airbyte.id

  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "nat" {
  project                            = var.project
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

resource "google_compute_global_address" "private_ip_alloc" {
  name          = "private-ip-alloc"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 24
  network       = google_compute_network.airbyte.id
}

resource "google_service_networking_connection" "service_connection" {
  network                 = google_compute_network.airbyte.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_alloc.name]
}
