# ============================================
# Cloud Build Configuration (replaces Jenkins)
# ============================================

# Enable Cloud Build API
resource "google_project_service" "cloudbuild" {
  project = var.gcp_project_id
  service = "cloudbuild.googleapis.com"
  
  disable_on_destroy = false
}

# Enable Cloud Source Repositories API
resource "google_project_service" "sourcerepo" {
  project = var.gcp_project_id
  service = "sourcerepo.googleapis.com"
  
  disable_on_destroy = false
}

# Enable Cloud Scheduler API (for scheduled builds)
resource "google_project_service" "cloudscheduler" {
  project = var.gcp_project_id
  service = "cloudscheduler.googleapis.com"
  
  disable_on_destroy = false
}

# ============================================
# Cloud Build Triggers (GitHub Integration)
# ============================================

# Trigger: Build and Deploy on Push to Main
resource "google_cloudbuild_trigger" "deploy_main" {
  project     = var.gcp_project_id
  name        = "${var.project_name}-deploy-main"
  description = "Build and deploy all services on push to main branch"

  github {
    owner = "Thang141104"  # Your GitHub username
    name  = "DevOps-Kahoot-Clone"
    
    push {
      branch = "^main$"
    }
  }

  filename = "cloudbuild.yaml"

  substitutions = {
    _PROJECT_ID       = var.gcp_project_id
    _REGION           = var.gcp_region
    _DEPLOYMENT_TYPE  = var.deployment_method
    _GCS_QUIZ_BUCKET  = google_storage_bucket.quiz_media.name
    _GCS_AVATAR_BUCKET = google_storage_bucket.user_avatars.name
  }

  service_account = google_service_account.cloud_build_sa.id
}

# Trigger: Build and Test on Pull Request
resource "google_cloudbuild_trigger" "test_pr" {
  project     = var.gcp_project_id
  name        = "${var.project_name}-test-pr"
  description = "Run tests on pull requests"

  github {
    owner = "Thang141104"
    name  = "DevOps-Kahoot-Clone"
    
    pull_request {
      branch          = ".*"
      comment_control = "COMMENTS_ENABLED"
    }
  }

  filename = "cloudbuild-test.yaml"

  service_account = google_service_account.cloud_build_sa.id
}

# Trigger: Manual Deployment
resource "google_cloudbuild_trigger" "manual_deploy" {
  project     = var.gcp_project_id
  name        = "${var.project_name}-manual-deploy"
  description = "Manual deployment trigger"

  # No automatic trigger - must be invoked manually
  disabled = false

  github {
    owner = "Thang141104"
    name  = "DevOps-Kahoot-Clone"
    
    push {
      branch = "^(main|staging|dev)$"
    }
  }

  filename = "cloudbuild.yaml"

  substitutions = {
    _PROJECT_ID       = var.gcp_project_id
    _REGION           = var.gcp_region
    _DEPLOYMENT_TYPE  = var.deployment_method
  }

  service_account = google_service_account.cloud_build_sa.id

  # Approval required
  approval_config {
    approval_required = true
  }
}

# ============================================
# Cloud Build Worker Pool (for private builds)
# ============================================

resource "google_cloudbuild_worker_pool" "private_pool" {
  count    = var.deployment_method == "gke" ? 1 : 0
  name     = "${var.project_name}-worker-pool"
  project  = var.gcp_project_id
  location = var.gcp_region

  worker_config {
    disk_size_gb   = 100
    machine_type   = "e2-medium"
    no_external_ip = false
  }

  network_config {
    peered_network = google_compute_network.vpc.id
  }
}

# ============================================
# Cloud Storage Bucket for Build Artifacts
# ============================================

resource "google_storage_bucket" "build_artifacts" {
  name          = "${var.project_name}-build-artifacts-${var.gcp_project_id}"
  project       = var.gcp_project_id
  location      = var.storage_location
  storage_class = "STANDARD"
  
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 30  # Delete artifacts older than 30 days
    }
    action {
      type = "Delete"
    }
  }

  labels = {
    environment = var.environment
    purpose     = "build-artifacts"
    managed_by  = "terraform"
  }
}

# Grant Cloud Build SA access to artifacts bucket
resource "google_storage_bucket_iam_member" "cloudbuild_artifacts" {
  bucket = google_storage_bucket.build_artifacts.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.cloud_build_sa.email}"
}

# ============================================
# Cloud Build Notifications (via Pub/Sub)
# ============================================

# Pub/Sub topic for build notifications
resource "google_pubsub_topic" "build_notifications" {
  name    = "${var.project_name}-build-notifications"
  project = var.gcp_project_id

  labels = {
    environment = var.environment
    managed_by  = "terraform"
  }
}

# Pub/Sub subscription for build notifications
resource "google_pubsub_subscription" "build_notifications_sub" {
  name    = "${var.project_name}-build-notifications-sub"
  project = var.gcp_project_id
  topic   = google_pubsub_topic.build_notifications.name

  ack_deadline_seconds = 20

  push_config {
    push_endpoint = "https://example.com/webhook"  # Replace with your webhook endpoint
  }

  labels = {
    environment = var.environment
    managed_by  = "terraform"
  }
}

# ============================================
# Cloud Build Notification Config
# ============================================

resource "google_cloudbuild_trigger" "build_notifications" {
  project     = var.gcp_project_id
  name        = "${var.project_name}-build-status-notifier"
  description = "Notify build status"

  pubsub_config {
    topic = google_pubsub_topic.build_notifications.id
  }

  github {
    owner = "Thang141104"
    name  = "DevOps-Kahoot-Clone"
    
    push {
      branch = ".*"
    }
  }

  filename = "cloudbuild.yaml"

  service_account = google_service_account.cloud_build_sa.id
}

# ============================================
# IAM for Cloud Build
# ============================================

# Grant Cloud Build permission to deploy to Cloud Run
resource "google_project_iam_member" "cloudbuild_run_developer" {
  project = var.gcp_project_id
  role    = "roles/run.developer"
  member  = "serviceAccount:${google_service_account.cloud_build_sa.email}"
}

# Grant Cloud Build permission to act as service accounts
resource "google_project_iam_member" "cloudbuild_sa_user" {
  project = var.gcp_project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.cloud_build_sa.email}"
}

# Grant Cloud Build permission to access secrets
resource "google_secret_manager_secret_iam_member" "cloudbuild_mongodb" {
  secret_id = google_secret_manager_secret.mongodb_uri.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.cloud_build_sa.email}"
}

resource "google_secret_manager_secret_iam_member" "cloudbuild_jwt" {
  secret_id = google_secret_manager_secret.jwt_secret.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.cloud_build_sa.email}"
}

# ============================================
# Outputs
# ============================================

output "cloud_build_trigger_main" {
  description = "Cloud Build Trigger ID for main branch"
  value       = google_cloudbuild_trigger.deploy_main.trigger_id
}

output "cloud_build_trigger_pr" {
  description = "Cloud Build Trigger ID for pull requests"
  value       = google_cloudbuild_trigger.test_pr.trigger_id
}

output "cloud_build_console_url" {
  description = "Cloud Build Console URL"
  value       = "https://console.cloud.google.com/cloud-build/builds?project=${var.gcp_project_id}"
}

output "build_artifacts_bucket" {
  description = "Build Artifacts Bucket"
  value       = google_storage_bucket.build_artifacts.name
}
