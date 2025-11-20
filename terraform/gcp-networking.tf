# ============================================
# BENCHMARK 3: Networking
# ============================================

# Enable required APIs
resource "google_project_service" "compute" {
  project = var.gcp_project_id
  service = "compute.googleapis.com"
  
  disable_on_destroy = false
}

resource "google_project_service" "servicenetworking" {
  project = var.gcp_project_id
  service = "servicenetworking.googleapis.com"
  
  disable_on_destroy = false
}

# ============================================
# VPC Network
# ============================================

resource "google_compute_network" "vpc" {
  name                    = "${var.project_name}-vpc"
  project                 = var.gcp_project_id
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
  description             = "VPC network for ${var.project_name}"
}

# Subnet for services
resource "google_compute_subnetwork" "subnet" {
  name          = "${var.project_name}-subnet"
  project       = var.gcp_project_id
  region        = var.gcp_region
  network       = google_compute_network.vpc.id
  ip_cidr_range = var.subnet_cidr

  # Enable Private Google Access for services without external IPs
  private_ip_google_access = true

  # Secondary IP ranges for GKE (if enabled)
  dynamic "secondary_ip_range" {
    for_each = var.enable_gke ? [1] : []
    content {
      range_name    = "${var.project_name}-pods"
      ip_cidr_range = "10.1.0.0/16"
    }
  }

  dynamic "secondary_ip_range" {
    for_each = var.enable_gke ? [1] : []
    content {
      range_name    = "${var.project_name}-services"
      ip_cidr_range = "10.2.0.0/16"
    }
  }

  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# ============================================
# Cloud NAT and Router
# ============================================

# Cloud Router for NAT
resource "google_compute_router" "router" {
  name    = "${var.project_name}-router"
  project = var.gcp_project_id
  region  = var.gcp_region
  network = google_compute_network.vpc.id

  bgp {
    asn = 64514
  }
}

# Cloud NAT for outbound internet access
resource "google_compute_router_nat" "nat" {
  name                               = "${var.project_name}-nat"
  project                            = var.gcp_project_id
  router                             = google_compute_router.router.name
  region                             = var.gcp_region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# ============================================
# Firewall Rules
# ============================================

# Allow internal communication
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.project_name}-allow-internal"
  project = var.gcp_project_id
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [var.vpc_cidr]
  description   = "Allow internal communication within VPC"
}

# Allow SSH for debugging
resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.project_name}-allow-ssh"
  project = var.gcp_project_id
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]  # GCP IAP range
  target_tags   = ["allow-ssh"]
  description   = "Allow SSH via Identity-Aware Proxy"
}

# Allow health checks
resource "google_compute_firewall" "allow_health_checks" {
  name    = "${var.project_name}-allow-health-checks"
  project = var.gcp_project_id
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
  }

  source_ranges = [
    "35.191.0.0/16",    # Google Cloud health check ranges
    "130.211.0.0/22"
  ]
  
  target_tags = ["allow-health-checks"]
  description = "Allow health checks from Google Cloud"
}

# Allow HTTP/HTTPS from Load Balancer
resource "google_compute_firewall" "allow_lb" {
  name    = "${var.project_name}-allow-lb"
  project = var.gcp_project_id
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "3000", "3001", "3002", "3003", "3004", "3005", "3006"]
  }

  source_ranges = [
    "130.211.0.0/22",   # GCP Load Balancer ranges
    "35.191.0.0/16"
  ]
  
  target_tags = ["allow-lb"]
  description = "Allow traffic from Load Balancer"
}

# Deny all other ingress
resource "google_compute_firewall" "deny_all_ingress" {
  name     = "${var.project_name}-deny-all-ingress"
  project  = var.gcp_project_id
  network  = google_compute_network.vpc.name
  priority = 65534

  deny {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]
  description   = "Deny all other ingress traffic"
}

# ============================================
# Cloud Load Balancer (for Cloud Run)
# ============================================

# Reserve static IP for load balancer
resource "google_compute_global_address" "lb_ip" {
  count   = var.deployment_method == "cloud-run" ? 1 : 0
  name    = "${var.project_name}-lb-ip"
  project = var.gcp_project_id
}

# Health check for backend service
resource "google_compute_health_check" "default" {
  count   = var.deployment_method == "cloud-run" ? 1 : 0
  name    = "${var.project_name}-health-check"
  project = var.gcp_project_id

  http_health_check {
    port         = 3000
    request_path = "/health"
  }

  timeout_sec        = 5
  check_interval_sec = 10
  
  log_config {
    enable = true
  }
}

# Backend service for Cloud Run (Gateway)
resource "google_compute_region_network_endpoint_group" "gateway_neg" {
  count                 = var.deployment_method == "cloud-run" ? 1 : 0
  name                  = "${var.project_name}-gateway-neg"
  project               = var.gcp_project_id
  region                = var.gcp_region
  network_endpoint_type = "SERVERLESS"

  cloud_run {
    service = google_cloud_run_service.gateway[0].name
  }
}

resource "google_compute_backend_service" "gateway_backend" {
  count                 = var.deployment_method == "cloud-run" ? 1 : 0
  name                  = "${var.project_name}-gateway-backend"
  project               = var.gcp_project_id
  protocol              = "HTTP"
  port_name             = "http"
  timeout_sec           = 30
  enable_cdn            = false
  load_balancing_scheme = "EXTERNAL_MANAGED"

  backend {
    group = google_compute_region_network_endpoint_group.gateway_neg[0].id
  }

  log_config {
    enable      = true
    sample_rate = 1.0
  }

  # Health check (required, but Cloud Run manages its own internally)
  health_checks = [google_compute_health_check.default[0].id]
}

# URL map
resource "google_compute_url_map" "lb" {
  count           = var.deployment_method == "cloud-run" ? 1 : 0
  name            = "${var.project_name}-lb"
  project         = var.gcp_project_id
  default_service = google_compute_backend_service.gateway_backend[0].id
}

# HTTP target proxy
resource "google_compute_target_http_proxy" "http_proxy" {
  count   = var.deployment_method == "cloud-run" ? 1 : 0
  name    = "${var.project_name}-http-proxy"
  project = var.gcp_project_id
  url_map = google_compute_url_map.lb[0].id
}

# Forwarding rule (HTTP)
resource "google_compute_global_forwarding_rule" "http" {
  count                 = var.deployment_method == "cloud-run" ? 1 : 0
  name                  = "${var.project_name}-http-forwarding"
  project               = var.gcp_project_id
  ip_address            = google_compute_global_address.lb_ip[0].address
  ip_protocol           = "TCP"
  port_range            = "80"
  target                = google_compute_target_http_proxy.http_proxy[0].id
  load_balancing_scheme = "EXTERNAL_MANAGED"
}

# ============================================
# VPC Connector (for Cloud Run to VPC access)
# ============================================
# DISABLED: VPC Connector keeps failing with internal errors
# Cloud Run services will work without it (no private VPC access needed)

# resource "google_vpc_access_connector" "connector" {
#   count         = var.deployment_method == "cloud-run" ? 1 : 0
#   name          = "kahoot-vpc-conn"  # Must match pattern ^[a-z][-a-z0-9]{0,23}[a-z0-9]$
#   project       = var.gcp_project_id
#   region        = var.gcp_region
#   network       = google_compute_network.vpc.name
#   ip_cidr_range = "10.8.0.0/28"
#   
#   min_instances = 2
#   max_instances = 10
# }

# ============================================
# Private Service Connection (for Cloud SQL)
# ============================================

resource "google_compute_global_address" "private_ip_alloc" {
  count         = var.enable_cloud_sql ? 1 : 0
  name          = "${var.project_name}-private-ip"
  project       = var.gcp_project_id
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  count                   = var.enable_cloud_sql ? 1 : 0
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_alloc[0].name]
}

# ============================================
# Outputs
# ============================================

output "vpc_id" {
  description = "VPC Network ID"
  value       = google_compute_network.vpc.id
}

output "vpc_name" {
  description = "VPC Network Name"
  value       = google_compute_network.vpc.name
}

output "subnet_id" {
  description = "Subnet ID"
  value       = google_compute_subnetwork.subnet.id
}

output "load_balancer_ip" {
  description = "Load Balancer Public IP"
  value       = var.deployment_method == "cloud-run" ? google_compute_global_address.lb_ip[0].address : "Not using Load Balancer"
}

output "vpc_connector_id" {
  description = "VPC Connector ID for Cloud Run"
  value       = "VPC Connector DISABLED - Not needed for Cloud Run with public MongoDB"
}
