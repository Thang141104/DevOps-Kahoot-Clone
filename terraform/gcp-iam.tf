# ============================================
# BENCHMARK 1: Identity and Access Management (IAM)
# ============================================

# Service Account for Cloud Run Services
resource "google_service_account" "cloud_run_sa" {
  account_id   = "${var.project_name}-cloud-run-sa"
  display_name = "Service Account for Cloud Run Services"
  description  = "Used by Cloud Run services to access GCP resources"
  project      = var.gcp_project_id
}

# Service Account for Cloud Build
resource "google_service_account" "cloud_build_sa" {
  account_id   = "${var.project_name}-cloud-build-sa"
  display_name = "Service Account for Cloud Build"
  description  = "Used by Cloud Build to build and deploy services"
  project      = var.gcp_project_id
}

# Service Account for GKE Nodes (if using GKE)
resource "google_service_account" "gke_sa" {
  count        = var.enable_gke ? 1 : 0
  account_id   = "${var.project_name}-gke-sa"
  display_name = "Service Account for GKE Nodes"
  description  = "Used by GKE nodes to access GCP resources"
  project      = var.gcp_project_id
}

# Service Account for Compute Engine (Jenkins)
resource "google_service_account" "jenkins_sa" {
  count        = var.enable_jenkins_vm ? 1 : 0
  account_id   = "${var.project_name}-jenkins-sa"
  display_name = "Service Account for Jenkins VM"
  description  = "Used by Jenkins VM to access GCP resources"
  project      = var.gcp_project_id
}

# Service Account for Analytics (BigQuery, Dataproc)
resource "google_service_account" "analytics_sa" {
  account_id   = "${var.project_name}-analytics-sa"
  display_name = "Service Account for Analytics Services"
  description  = "Used by analytics services to access BigQuery and Dataproc"
  project      = var.gcp_project_id
}

# ============================================
# IAM Roles for Cloud Run Service Account
# ============================================

# Cloud Storage access for quiz images and user avatars
resource "google_project_iam_member" "cloud_run_storage" {
  project = var.gcp_project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

# Cloud SQL Client (if using Cloud SQL)
resource "google_project_iam_member" "cloud_run_cloudsql" {
  count   = var.enable_cloud_sql ? 1 : 0
  project = var.gcp_project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

# Cloud Logging
resource "google_project_iam_member" "cloud_run_logging" {
  project = var.gcp_project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

# Cloud Monitoring
resource "google_project_iam_member" "cloud_run_monitoring" {
  project = var.gcp_project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

# Cloud Trace
resource "google_project_iam_member" "cloud_run_trace" {
  project = var.gcp_project_id
  role    = "roles/cloudtrace.agent"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

# Secret Manager access
resource "google_project_iam_member" "cloud_run_secrets" {
  project = var.gcp_project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

# ============================================
# IAM Roles for Cloud Build Service Account
# ============================================

# Cloud Run Admin (for deployment)
resource "google_project_iam_member" "cloud_build_run_admin" {
  project = var.gcp_project_id
  role    = "roles/run.admin"
  member  = "serviceAccount:${google_service_account.cloud_build_sa.email}"
}

# Cloud Storage Admin (for build artifacts)
resource "google_project_iam_member" "cloud_build_storage" {
  project = var.gcp_project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.cloud_build_sa.email}"
}

# Cloud Build Service Account User
resource "google_project_iam_member" "cloud_build_sa_user" {
  project = var.gcp_project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.cloud_build_sa.email}"
}

# Container Registry Admin
resource "google_project_iam_member" "cloud_build_gcr" {
  project = var.gcp_project_id
  role    = "roles/storage.admin"  # For GCR access
  member  = "serviceAccount:${google_service_account.cloud_build_sa.email}"
}

# Logging
resource "google_project_iam_member" "cloud_build_logging" {
  project = var.gcp_project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.cloud_build_sa.email}"
}

# ============================================
# IAM Roles for Analytics Service Account
# ============================================

# BigQuery Data Editor
resource "google_project_iam_member" "analytics_bigquery_editor" {
  count   = var.enable_bigquery ? 1 : 0
  project = var.gcp_project_id
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${google_service_account.analytics_sa.email}"
}

# BigQuery Job User
resource "google_project_iam_member" "analytics_bigquery_job" {
  count   = var.enable_bigquery ? 1 : 0
  project = var.gcp_project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.analytics_sa.email}"
}

# Dataproc Editor
resource "google_project_iam_member" "analytics_dataproc" {
  count   = var.enable_dataproc ? 1 : 0
  project = var.gcp_project_id
  role    = "roles/dataproc.editor"
  member  = "serviceAccount:${google_service_account.analytics_sa.email}"
}

# Storage Object Viewer (for Dataproc input/output)
resource "google_project_iam_member" "analytics_storage" {
  project = var.gcp_project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.analytics_sa.email}"
}

# ============================================
# IAM Roles for GKE Service Account (if enabled)
# ============================================

resource "google_project_iam_member" "gke_logging" {
  count   = var.enable_gke ? 1 : 0
  project = var.gcp_project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.gke_sa[0].email}"
}

resource "google_project_iam_member" "gke_monitoring" {
  count   = var.enable_gke ? 1 : 0
  project = var.gcp_project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.gke_sa[0].email}"
}

resource "google_project_iam_member" "gke_storage" {
  count   = var.enable_gke ? 1 : 0
  project = var.gcp_project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.gke_sa[0].email}"
}

# ============================================
# Workload Identity Binding (for GKE pods to use SA)
# ============================================

resource "google_service_account_iam_member" "workload_identity_binding" {
  count              = var.enable_gke ? 1 : 0
  service_account_id = google_service_account.cloud_run_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.gcp_project_id}.svc.id.goog[${var.project_name}/default]"
}

# ============================================
# Secret Manager Secrets
# ============================================

# MongoDB URI Secret
resource "google_secret_manager_secret" "mongodb_uri" {
  secret_id = "${var.project_name}-mongodb-uri"
  project   = var.gcp_project_id

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "mongodb_uri" {
  secret      = google_secret_manager_secret.mongodb_uri.id
  secret_data = var.mongodb_uri
}

# JWT Secret
resource "google_secret_manager_secret" "jwt_secret" {
  secret_id = "${var.project_name}-jwt-secret"
  project   = var.gcp_project_id

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "jwt_secret" {
  secret      = google_secret_manager_secret.jwt_secret.id
  secret_data = var.jwt_secret
}

# Email Password
resource "google_secret_manager_secret" "email_password" {
  count     = var.email_password != "" ? 1 : 0
  secret_id = "${var.project_name}-email-password"
  project   = var.gcp_project_id

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "email_password" {
  count       = var.email_password != "" ? 1 : 0
  secret      = google_secret_manager_secret.email_password[0].id
  secret_data = var.email_password
}

# ============================================
# Outputs
# ============================================

output "cloud_run_sa_email" {
  description = "Cloud Run Service Account email"
  value       = google_service_account.cloud_run_sa.email
}

output "cloud_build_sa_email" {
  description = "Cloud Build Service Account email"
  value       = google_service_account.cloud_build_sa.email
}

output "analytics_sa_email" {
  description = "Analytics Service Account email"
  value       = google_service_account.analytics_sa.email
}

output "mongodb_uri_secret" {
  description = "MongoDB URI Secret Manager path"
  value       = google_secret_manager_secret.mongodb_uri.id
  sensitive   = true
}

output "jwt_secret_secret" {
  description = "JWT Secret Manager path"
  value       = google_secret_manager_secret.jwt_secret.id
  sensitive   = true
}
