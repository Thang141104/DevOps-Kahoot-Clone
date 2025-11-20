# ============================================
# BENCHMARK 5: Storage (Cloud Storage)
# ============================================

# Enable Cloud Storage API
resource "google_project_service" "storage" {
  project = var.gcp_project_id
  service = "storage.googleapis.com"
  
  disable_on_destroy = false
}

# ============================================
# Cloud Storage Buckets
# ============================================

# Bucket for Quiz Images/Videos
resource "google_storage_bucket" "quiz_media" {
  name          = "${var.project_name}-quiz-media-${var.gcp_project_id}"
  project       = var.gcp_project_id
  location      = var.storage_location
  storage_class = var.storage_class
  
  uniform_bucket_level_access = true
  
  # Public access for quiz images
  public_access_prevention = "inherited"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 90  # Delete old versions after 90 days
      num_newer_versions = 3
    }
    action {
      type = "Delete"
    }
  }

  cors {
    origin          = ["*"]
    method          = ["GET", "HEAD", "PUT", "POST", "DELETE"]
    response_header = ["*"]
    max_age_seconds = 3600
  }

  labels = {
    environment = var.environment
    purpose     = "quiz-media"
    managed_by  = "terraform"
  }
}

# Bucket for User Avatars
resource "google_storage_bucket" "user_avatars" {
  name          = "${var.project_name}-user-avatars-${var.gcp_project_id}"
  project       = var.gcp_project_id
  location      = var.storage_location
  storage_class = var.storage_class
  
  uniform_bucket_level_access = true
  public_access_prevention    = "inherited"

  versioning {
    enabled = false
  }

  lifecycle_rule {
    condition {
      age = 365  # Archive after 1 year
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  cors {
    origin          = ["*"]
    method          = ["GET", "HEAD", "PUT", "POST"]
    response_header = ["*"]
    max_age_seconds = 3600
  }

  labels = {
    environment = var.environment
    purpose     = "user-avatars"
    managed_by  = "terraform"
  }
}

# Bucket for Application Backups
resource "google_storage_bucket" "backups" {
  name          = "${var.project_name}-backups-${var.gcp_project_id}"
  project       = var.gcp_project_id
  location      = var.storage_location
  storage_class = "NEARLINE"  # Cost-effective for backups
  
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 30  # Move to coldline after 30 days
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }

  lifecycle_rule {
    condition {
      age = 365  # Delete backups older than 1 year
    }
    action {
      type = "Delete"
    }
  }

  labels = {
    environment = var.environment
    purpose     = "backups"
    managed_by  = "terraform"
  }
}

# Bucket for Logs (from Cloud Logging)
resource "google_storage_bucket" "logs" {
  count         = var.enable_cloud_monitoring ? 1 : 0
  name          = "${var.project_name}-logs-${var.gcp_project_id}"
  project       = var.gcp_project_id
  location      = var.storage_location
  storage_class = "STANDARD"
  
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = false
  }

  lifecycle_rule {
    condition {
      age = var.log_retention_days
    }
    action {
      type = "Delete"
    }
  }

  labels = {
    environment = var.environment
    purpose     = "logs"
    managed_by  = "terraform"
  }
}

# Bucket for Static Website (Frontend - optional)
resource "google_storage_bucket" "frontend" {
  count         = var.deployment_method == "cloud-run" ? 0 : 1
  name          = "${var.project_name}-frontend-${var.gcp_project_id}"
  project       = var.gcp_project_id
  location      = var.storage_location
  storage_class = "STANDARD"
  
  uniform_bucket_level_access = true
  public_access_prevention    = "inherited"

  website {
    main_page_suffix = "index.html"
    not_found_page   = "index.html"  # For SPA routing
  }

  cors {
    origin          = ["*"]
    method          = ["GET", "HEAD"]
    response_header = ["*"]
    max_age_seconds = 3600
  }

  labels = {
    environment = var.environment
    purpose     = "frontend-static"
    managed_by  = "terraform"
  }
}

# ============================================
# IAM Bindings for Buckets
# ============================================

# Make quiz media publicly readable
resource "google_storage_bucket_iam_member" "quiz_media_public" {
  bucket = google_storage_bucket.quiz_media.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

# Make user avatars publicly readable
resource "google_storage_bucket_iam_member" "user_avatars_public" {
  bucket = google_storage_bucket.user_avatars.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

# Grant Cloud Run SA full access to quiz media bucket
resource "google_storage_bucket_iam_member" "quiz_media_cloud_run" {
  bucket = google_storage_bucket.quiz_media.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

# Grant Cloud Run SA full access to user avatars bucket
resource "google_storage_bucket_iam_member" "user_avatars_cloud_run" {
  bucket = google_storage_bucket.user_avatars.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

# Grant Cloud Run SA access to backups bucket
resource "google_storage_bucket_iam_member" "backups_cloud_run" {
  bucket = google_storage_bucket.backups.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

# Make frontend bucket publicly readable (if using Cloud Storage for frontend)
resource "google_storage_bucket_iam_member" "frontend_public" {
  count  = var.deployment_method == "cloud-run" ? 0 : 1
  bucket = google_storage_bucket.frontend[0].name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

# ============================================
# Cloud Storage Notifications (to Pub/Sub)
# ============================================

# Pub/Sub topic for storage events
resource "google_pubsub_topic" "storage_events" {
  name    = "${var.project_name}-storage-events"
  project = var.gcp_project_id

  labels = {
    environment = var.environment
    managed_by  = "terraform"
  }
}

# Notification for quiz media uploads
resource "google_storage_notification" "quiz_media_notification" {
  bucket         = google_storage_bucket.quiz_media.name
  payload_format = "JSON_API_V1"
  topic          = google_pubsub_topic.storage_events.id
  
  event_types = ["OBJECT_FINALIZE", "OBJECT_DELETE"]

  depends_on = [google_pubsub_topic_iam_member.storage_publisher]
}

# Grant Cloud Storage permission to publish to Pub/Sub
data "google_storage_project_service_account" "gcs_account" {
  project = var.gcp_project_id
}

resource "google_pubsub_topic_iam_member" "storage_publisher" {
  project = var.gcp_project_id
  topic   = google_pubsub_topic.storage_events.name
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"
}

# ============================================
# Outputs
# ============================================

output "quiz_media_bucket_name" {
  description = "Quiz Media Bucket Name"
  value       = google_storage_bucket.quiz_media.name
}

output "quiz_media_bucket_url" {
  description = "Quiz Media Bucket URL"
  value       = "gs://${google_storage_bucket.quiz_media.name}"
}

output "user_avatars_bucket_name" {
  description = "User Avatars Bucket Name"
  value       = google_storage_bucket.user_avatars.name
}

output "user_avatars_bucket_url" {
  description = "User Avatars Bucket URL"
  value       = "gs://${google_storage_bucket.user_avatars.name}"
}

output "backups_bucket_name" {
  description = "Backups Bucket Name"
  value       = google_storage_bucket.backups.name
}

output "logs_bucket_name" {
  description = "Logs Bucket Name"
  value       = var.enable_cloud_monitoring ? google_storage_bucket.logs[0].name : "Logs bucket not enabled"
}

output "frontend_bucket_url" {
  description = "Frontend Static Website URL"
  value       = var.deployment_method == "cloud-run" ? "Not using Cloud Storage for frontend" : "https://storage.googleapis.com/${google_storage_bucket.frontend[0].name}/index.html"
}
