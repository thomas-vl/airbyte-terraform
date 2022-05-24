module "gce-lb-http" {
  source  = "registry.terraform.io/GoogleCloudPlatform/lb-http/google"
  version = "~> 5.1"

  project = var.project
  name    = "airbyte-lb"

  firewall_networks = [var.network]

  ssl                             = true
  https_redirect                  = true
  managed_ssl_certificate_domains = [var.domain_name]
  backends = {
    default = {
      description                     = null
      protocol                        = "HTTP"
      port                            = 80
      port_name                       = "http"
      timeout_sec                     = 600
      connection_draining_timeout_sec = null
      enable_cdn                      = false
      security_policy                 = null
      session_affinity                = null
      affinity_cookie_ttl_sec         = null
      custom_request_headers          = null
      custom_response_headers         = null

      log_config = {
        enable      = true
        sample_rate = 1.0
      }

      health_check = {
        check_interval_sec  = null
        timeout_sec         = null
        healthy_threshold   = null
        unhealthy_threshold = null
        request_path        = "/"
        port                = 80
        host                = null
        logging             = null
      }

      groups = [
        {
          group                        = "projects/${var.project}/zones/${var.region}-a/networkEndpointGroups/neg-airbyte-webapp"
          balancing_mode               = "RATE"
          capacity_scaler              = null
          description                  = null
          max_connections              = null
          max_connections_per_instance = null
          max_connections_per_endpoint = null
          max_rate                     = null
          max_rate_per_instance        = null
          max_rate_per_endpoint        = "1"
          max_utilization              = null
        },
      ]

      iap_config = {
        enable               = true
        oauth2_client_id     = var.iap_client_id
        oauth2_client_secret = var.iap_secret
      }
    }
  }
}
