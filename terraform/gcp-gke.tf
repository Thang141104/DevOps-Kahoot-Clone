# ============================================
# Google Kubernetes Engine (GKE) Configuration
# Alternative to self-managed Kubernetes
# ============================================

# Enable GKE API
resource "google_project_service" "container" {
  count   = var.enable_gke ? 1 : 0
  project = var.gcp_project_id
  service = "container.googleapis.com"
  
  disable_on_destroy = false
}

# ============================================
# GKE Cluster
# ============================================

resource "google_container_cluster" "primary" {
  count    = var.enable_gke ? 1 : 0
  name     = "${var.project_name}-gke-cluster"
  project  = var.gcp_project_id
  location = var.gcp_region

  # Remove default node pool (we'll create custom one)
  remove_default_node_pool = true
  initial_node_count       = 1

  # Network configuration
  network    = google_compute_network.vpc.id
  subnetwork = google_compute_subnetwork.subnet.id

  # IP allocation policy for pods and services
  ip_allocation_policy {
    cluster_secondary_range_name  = "${var.project_name}-pods"
    services_secondary_range_name = "${var.project_name}-services"
  }

  # Workload Identity
  workload_identity_config {
    workload_pool = "${var.gcp_project_id}.svc.id.goog"
  }

  # Release channel (stable, regular, rapid)
  release_channel {
    channel = "REGULAR"
  }

  # Addons configuration
  addons_config {
    http_load_balancing {
      disabled = false
    }

    horizontal_pod_autoscaling {
      disabled = false
    }

    network_policy_config {
      disabled = false
    }

    gcp_filestore_csi_driver_config {
      enabled = false
    }

    gcs_fuse_csi_driver_config {
      enabled = true  # For Cloud Storage mounting
    }
  }

  # Network policy
  network_policy {
    enabled  = true
    provider = "CALICO"
  }

  # Logging and monitoring
  logging_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  }

  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS"]
    
    managed_prometheus {
      enabled = true
    }
  }

  # Maintenance policy
  maintenance_policy {
    daily_maintenance_window {
      start_time = "03:00"  # 3 AM
    }
  }

  # Resource labels
  resource_labels = {
    environment = var.environment
    managed_by  = "terraform"
  }

  # Private cluster config
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  # Master authorized networks (allow access from specific IPs)
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "0.0.0.0/0"  # CHANGE THIS to your IP for security
      display_name = "All networks"
    }
  }

  # Binary authorization
  binary_authorization {
    evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
  }

  # Cluster autoscaling
  cluster_autoscaling {
    enabled = true
    
    resource_limits {
      resource_type = "cpu"
      minimum       = 1
      maximum       = 100
    }
    
    resource_limits {
      resource_type = "memory"
      minimum       = 2
      maximum       = 200
    }

    auto_provisioning_defaults {
      service_account = google_service_account.gke_sa[0].email
      oauth_scopes = [
        "https://www.googleapis.com/auth/cloud-platform"
      ]
    }
  }
}

# ============================================
# GKE Node Pool
# ============================================

resource "google_container_node_pool" "primary_nodes" {
  count      = var.enable_gke ? 1 : 0
  name       = "${var.project_name}-node-pool"
  project    = var.gcp_project_id
  location   = var.gcp_region
  cluster    = google_container_cluster.primary[0].name
  node_count = var.gke_node_count

  # Autoscaling configuration
  autoscaling {
    min_node_count = 1
    max_node_count = 10
  }

  # Node management
  management {
    auto_repair  = true
    auto_upgrade = true
  }

  # Node configuration
  node_config {
    machine_type = var.gke_machine_type
    disk_size_gb = 50
    disk_type    = "pd-standard"

    # Service account
    service_account = google_service_account.gke_sa[0].email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    # Workload Identity
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    # Shielded instance config
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    # Metadata
    metadata = {
      disable-legacy-endpoints = "true"
    }

    # Labels
    labels = {
      environment = var.environment
      managed_by  = "terraform"
    }

    # Tags for firewall
    tags = ["gke-node", "allow-health-checks"]

    # Preemptible nodes for cost savings (optional)
    preemptible  = false
    spot         = false
  }

  # Upgrade settings
  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }
}

# ============================================
# GKE Service Account Bindings
# ============================================

resource "google_service_account_iam_binding" "gke_workload_identity" {
  count              = var.enable_gke ? 1 : 0
  service_account_id = google_service_account.cloud_run_sa.name
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "serviceAccount:${var.gcp_project_id}.svc.id.goog[${var.project_name}/default]",
    "serviceAccount:${var.gcp_project_id}.svc.id.goog[default/default]",
  ]
}

# ============================================
# Kubernetes Namespace
# ============================================

resource "kubernetes_namespace" "app_namespace" {
  count = var.enable_gke ? 1 : 0
  
  metadata {
    name = var.project_name

    labels = {
      environment = var.environment
      managed_by  = "terraform"
    }
  }

  depends_on = [google_container_node_pool.primary_nodes]
}

# ============================================
# Kubernetes Service Account (with Workload Identity)
# ============================================

resource "kubernetes_service_account" "app_sa" {
  count = var.enable_gke ? 1 : 0

  metadata {
    name      = "app-service-account"
    namespace = kubernetes_namespace.app_namespace[0].metadata[0].name

    annotations = {
      "iam.gke.io/gcp-service-account" = google_service_account.cloud_run_sa.email
    }
  }

  depends_on = [google_container_node_pool.primary_nodes]
}

# ============================================
# ConfigMap for Application Configuration
# ============================================

resource "kubernetes_config_map" "app_config" {
  count = var.enable_gke ? 1 : 0

  metadata {
    name      = "app-config"
    namespace = kubernetes_namespace.app_namespace[0].metadata[0].name
  }

  data = {
    GATEWAY_PORT           = "3000"
    AUTH_SERVICE_URL       = "http://auth-service:3001"
    QUIZ_SERVICE_URL       = "http://quiz-service:3002"
    GAME_SERVICE_URL       = "http://game-service:3003"
    USER_SERVICE_URL       = "http://user-service:3004"
    ANALYTICS_SERVICE_URL  = "http://analytics-service:3005"
    NODE_ENV               = var.environment
    GCS_QUIZ_BUCKET        = google_storage_bucket.quiz_media.name
    GCS_AVATAR_BUCKET      = google_storage_bucket.user_avatars.name
    BIGQUERY_DATASET       = var.enable_bigquery ? google_bigquery_dataset.analytics[0].dataset_id : ""
    GCP_PROJECT_ID         = var.gcp_project_id
  }
}

# ============================================
# Kubernetes Secrets (from Secret Manager)
# ============================================

resource "kubernetes_secret" "app_secrets" {
  count = var.enable_gke ? 1 : 0

  metadata {
    name      = "app-secrets"
    namespace = kubernetes_namespace.app_namespace[0].metadata[0].name
  }

  data = {
    MONGODB_URI     = var.mongodb_uri
    JWT_SECRET      = var.jwt_secret
    EMAIL_USER      = var.email_user
    EMAIL_PASSWORD  = var.email_password
  }

  type = "Opaque"
}

# ============================================
# Outputs
# ============================================

output "gke_cluster_name" {
  description = "GKE Cluster Name"
  value       = var.enable_gke ? google_container_cluster.primary[0].name : "GKE not enabled"
}

output "gke_cluster_endpoint" {
  description = "GKE Cluster Endpoint"
  value       = var.enable_gke ? google_container_cluster.primary[0].endpoint : "GKE not enabled"
  sensitive   = true
}

output "gke_cluster_ca_certificate" {
  description = "GKE Cluster CA Certificate"
  value       = var.enable_gke ? google_container_cluster.primary[0].master_auth[0].cluster_ca_certificate : "GKE not enabled"
  sensitive   = true
}

output "gke_kubectl_config" {
  description = "kubectl configuration command"
  value       = var.enable_gke ? "gcloud container clusters get-credentials ${google_container_cluster.primary[0].name} --region ${var.gcp_region} --project ${var.gcp_project_id}" : "GKE not enabled"
}
