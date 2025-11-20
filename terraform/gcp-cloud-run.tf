# ============================================
# Cloud Run Services Deployment
# ============================================

# Enable Cloud Run API
resource "google_project_service" "run" {
  project = var.gcp_project_id
  service = "run.googleapis.com"
  
  disable_on_destroy = false
}

# Enable Container Registry API
resource "google_project_service" "container_registry" {
  project = var.gcp_project_id
  service = "containerregistry.googleapis.com"
  
  disable_on_destroy = false
}

# Enable Artifact Registry API
resource "google_project_service" "artifact_registry" {
  project = var.gcp_project_id
  service = "artifactregistry.googleapis.com"
  
  disable_on_destroy = false
}

# ============================================
# Artifact Registry Repository
# ============================================

resource "google_artifact_registry_repository" "docker_repo" {
  count         = var.deployment_method == "cloud-run" || var.deployment_method == "gke" ? 1 : 0
  project       = var.gcp_project_id
  location      = var.gcp_region
  repository_id = "${var.project_name}-docker-repo"
  description   = "Docker repository for ${var.project_name} services"
  format        = "DOCKER"

  labels = {
    environment = var.environment
    managed_by  = "terraform"
  }
}

# ============================================
# Cloud Run Service: API Gateway
# ============================================

resource "google_cloud_run_service" "gateway" {
  count    = var.deployment_method == "cloud-run" ? 1 : 0
  name     = "${var.project_name}-gateway"
  project  = var.gcp_project_id
  location = var.gcp_region

  template {
    spec {
      service_account_name = google_service_account.cloud_run_sa.email
      
      containers {
        image = "gcr.io/${var.gcp_project_id}/${var.project_name}-gateway:latest"
        
        ports {
          container_port = 3000
        }

        resources {
          limits = {
            cpu    = var.cloud_run_cpu
            memory = var.cloud_run_memory
          }
        }
        env {
          name  = "NODE_ENV"
          value = var.environment
        }

        env {
          name  = "AUTH_SERVICE_URL"
          value = "https://${google_cloud_run_service.auth[0].status[0].url}"
        }

        env {
          name  = "QUIZ_SERVICE_URL"
          value = "https://${google_cloud_run_service.quiz[0].status[0].url}"
        }

        env {
          name  = "GAME_SERVICE_URL"
          value = "https://${google_cloud_run_service.game[0].status[0].url}"
        }

        env {
          name  = "USER_SERVICE_URL"
          value = "https://${google_cloud_run_service.user[0].status[0].url}"
        }

        env {
          name  = "ANALYTICS_SERVICE_URL"
          value = "https://${google_cloud_run_service.analytics[0].status[0].url}"
        }
      }
    }

    metadata {
      annotations = {
        "autoscaling.knative.dev/minScale"      = tostring(var.cloud_run_min_instances)
        "autoscaling.knative.dev/maxScale"      = tostring(var.cloud_run_max_instances)
        # "run.googleapis.com/vpc-access-connector" = google_vpc_access_connector.connector[0].id  # DISABLED
        # "run.googleapis.com/vpc-access-egress" = "all-traffic"  # DISABLED
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  autogenerate_revision_name = true
}

# ============================================
# Cloud Run Service: Auth Service
# ============================================

resource "google_cloud_run_service" "auth" {
  count    = var.deployment_method == "cloud-run" ? 1 : 0
  name     = "${var.project_name}-auth"
  project  = var.gcp_project_id
  location = var.gcp_region

  depends_on = [
    null_resource.build_auth_image,
    time_sleep.wait_for_images
  ]

  template {
    spec {
      service_account_name = google_service_account.cloud_run_sa.email
      
      containers {
        image = "gcr.io/${var.gcp_project_id}/${var.project_name}-auth:latest"
        
        ports {
          container_port = 3001
        }

        resources {
          limits = {
            cpu    = var.cloud_run_cpu
            memory = var.cloud_run_memory
          }
        }
        env {
          name  = "NODE_ENV"
          value = var.environment
        }

        env {
          name = "MONGODB_URI"
          value_from {
            secret_key_ref {
              name = google_secret_manager_secret.mongodb_uri.secret_id
              key  = "latest"
            }
          }
        }

        env {
          name = "JWT_SECRET"
          value_from {
            secret_key_ref {
              name = google_secret_manager_secret.jwt_secret.secret_id
              key  = "latest"
            }
          }
        }

        env {
          name  = "EMAIL_USER"
          value = var.email_user
        }

        env {
          name = "EMAIL_PASSWORD"
          value_from {
            secret_key_ref {
              name = var.email_password != "" ? google_secret_manager_secret.email_password[0].secret_id : "empty"
              key  = "latest"
            }
          }
        }
      }
    }

    metadata {
      annotations = {
        "autoscaling.knative.dev/minScale"      = tostring(var.cloud_run_min_instances)
        "autoscaling.knative.dev/maxScale"      = tostring(var.cloud_run_max_instances)
        # "run.googleapis.com/vpc-access-connector" = google_vpc_access_connector.connector[0].id  # DISABLED
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

# ============================================
# Cloud Run Service: Quiz Service
# ============================================

resource "google_cloud_run_service" "quiz" {
  count    = var.deployment_method == "cloud-run" ? 1 : 0
  name     = "${var.project_name}-quiz"
  project  = var.gcp_project_id
  location = var.gcp_region

  template {
    spec {
      service_account_name = google_service_account.cloud_run_sa.email
      
      containers {
        image = "gcr.io/${var.gcp_project_id}/${var.project_name}-quiz:latest"
        
        ports {
          container_port = 3002
        }

        resources {
          limits = {
            cpu    = var.cloud_run_cpu
            memory = var.cloud_run_memory
          }
        }
        env {
          name  = "NODE_ENV"
          value = var.environment
        }

        env {
          name = "MONGODB_URI"
          value_from {
            secret_key_ref {
              name = google_secret_manager_secret.mongodb_uri.secret_id
              key  = "latest"
            }
          }
        }

        env {
          name  = "GCS_BUCKET_NAME"
          value = google_storage_bucket.quiz_media.name
        }
      }
    }

    metadata {
      annotations = {
        "autoscaling.knative.dev/minScale"      = tostring(var.cloud_run_min_instances)
        "autoscaling.knative.dev/maxScale"      = tostring(var.cloud_run_max_instances)
        # "run.googleapis.com/vpc-access-connector" = google_vpc_access_connector.connector[0].id  # DISABLED
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

# ============================================
# Cloud Run Service: Game Service
# ============================================

resource "google_cloud_run_service" "game" {
  count    = var.deployment_method == "cloud-run" ? 1 : 0
  name     = "${var.project_name}-game"
  project  = var.gcp_project_id
  location = var.gcp_region

  template {
    spec {
      service_account_name = google_service_account.cloud_run_sa.email
      timeout_seconds      = 3600  # 1 hour for long-running games
      
      containers {
        image = "gcr.io/${var.gcp_project_id}/${var.project_name}-game:latest"
        
        ports {
          container_port = 3003
        }

        resources {
          limits = {
            cpu    = "2"      # More CPU for Socket.io
            memory = "1Gi"    # More memory for real-time connections
          }
        }
        env {
          name  = "NODE_ENV"
          value = var.environment
        }

        env {
          name = "MONGODB_URI"
          value_from {
            secret_key_ref {
              name = google_secret_manager_secret.mongodb_uri.secret_id
              key  = "latest"
            }
          }
        }

        env {
          name  = "ANALYTICS_SERVICE_URL"
          value = "https://${google_cloud_run_service.analytics[0].status[0].url}"
        }
      }
    }

    metadata {
      annotations = {
        "autoscaling.knative.dev/minScale"      = "1"  # Keep at least 1 for Socket.io
        "autoscaling.knative.dev/maxScale"      = "20"
        # "run.googleapis.com/vpc-access-connector" = google_vpc_access_connector.connector[0].id  # DISABLED
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

# ============================================
# Cloud Run Service: User Service
# ============================================

resource "google_cloud_run_service" "user" {
  count    = var.deployment_method == "cloud-run" ? 1 : 0
  name     = "${var.project_name}-user"
  project  = var.gcp_project_id
  location = var.gcp_region

  template {
    spec {
      service_account_name = google_service_account.cloud_run_sa.email
      
      containers {
        image = "gcr.io/${var.gcp_project_id}/${var.project_name}-user:latest"
        
        ports {
          container_port = 3004
        }

        resources {
          limits = {
            cpu    = var.cloud_run_cpu
            memory = var.cloud_run_memory
          }
        }
        env {
          name  = "NODE_ENV"
          value = var.environment
        }

        env {
          name = "MONGODB_URI"
          value_from {
            secret_key_ref {
              name = google_secret_manager_secret.mongodb_uri.secret_id
              key  = "latest"
            }
          }
        }

        env {
          name  = "GCS_BUCKET_NAME"
          value = google_storage_bucket.user_avatars.name
        }
      }
    }

    metadata {
      annotations = {
        "autoscaling.knative.dev/minScale"      = tostring(var.cloud_run_min_instances)
        "autoscaling.knative.dev/maxScale"      = tostring(var.cloud_run_max_instances)
        # "run.googleapis.com/vpc-access-connector" = google_vpc_access_connector.connector[0].id  # DISABLED
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

# ============================================
# Cloud Run Service: Analytics Service
# ============================================

resource "google_cloud_run_service" "analytics" {
  count    = var.deployment_method == "cloud-run" ? 1 : 0
  name     = "${var.project_name}-analytics"
  project  = var.gcp_project_id
  location = var.gcp_region

  template {
    spec {
      service_account_name = google_service_account.analytics_sa.email
      
      containers {
        image = "gcr.io/${var.gcp_project_id}/${var.project_name}-analytics:latest"
        
        ports {
          container_port = 3005
        }

        resources {
          limits = {
            cpu    = var.cloud_run_cpu
            memory = var.cloud_run_memory
          }
        }
        env {
          name  = "NODE_ENV"
          value = var.environment
        }

        env {
          name = "MONGODB_URI"
          value_from {
            secret_key_ref {
              name = google_secret_manager_secret.mongodb_uri.secret_id
              key  = "latest"
            }
          }
        }

        env {
          name  = "BIGQUERY_DATASET"
          value = var.enable_bigquery ? google_bigquery_dataset.analytics[0].dataset_id : ""
        }

        env {
          name  = "GCP_PROJECT_ID"
          value = var.gcp_project_id
        }
      }
    }

    metadata {
      annotations = {
        "autoscaling.knative.dev/minScale"      = tostring(var.cloud_run_min_instances)
        "autoscaling.knative.dev/maxScale"      = tostring(var.cloud_run_max_instances)
        # "run.googleapis.com/vpc-access-connector" = google_vpc_access_connector.connector[0].id  # DISABLED
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

# ============================================
# Cloud Run Service: Frontend
# ============================================

resource "google_cloud_run_service" "frontend" {
  count    = var.deployment_method == "cloud-run" ? 1 : 0
  name     = "${var.project_name}-frontend"
  project  = var.gcp_project_id
  location = var.gcp_region

  template {
    spec {
      service_account_name = google_service_account.cloud_run_sa.email
      
      containers {
        image = "gcr.io/${var.gcp_project_id}/${var.project_name}-frontend:latest"
        
        ports {
          container_port = 3006
        }

        resources {
          limits = {
            cpu    = var.cloud_run_cpu
            memory = var.cloud_run_memory
          }
        }
        env {
          name  = "REACT_APP_API_URL"
          value = "https://${google_cloud_run_service.gateway[0].status[0].url}"
        }

        env {
          name  = "REACT_APP_SOCKET_URL"
          value = "https://${google_cloud_run_service.game[0].status[0].url}"
        }
      }
    }

    metadata {
      annotations = {
        "autoscaling.knative.dev/minScale"      = tostring(var.cloud_run_min_instances)
        "autoscaling.knative.dev/maxScale"      = tostring(var.cloud_run_max_instances)
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

# ============================================
# IAM - Allow public access to Cloud Run services
# ============================================

resource "google_cloud_run_service_iam_member" "gateway_public" {
  count    = var.deployment_method == "cloud-run" ? 1 : 0
  project  = var.gcp_project_id
  location = var.gcp_region
  service  = google_cloud_run_service.gateway[0].name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_cloud_run_service_iam_member" "frontend_public" {
  count    = var.deployment_method == "cloud-run" ? 1 : 0
  project  = var.gcp_project_id
  location = var.gcp_region
  service  = google_cloud_run_service.frontend[0].name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# ============================================
# Outputs
# ============================================

output "cloud_run_gateway_url" {
  description = "Cloud Run Gateway Service URL"
  value       = var.deployment_method == "cloud-run" ? google_cloud_run_service.gateway[0].status[0].url : "Not using Cloud Run"
}

output "cloud_run_frontend_url" {
  description = "Cloud Run Frontend Service URL"
  value       = var.deployment_method == "cloud-run" ? google_cloud_run_service.frontend[0].status[0].url : "Not using Cloud Run"
}

output "cloud_run_services" {
  description = "All Cloud Run Service URLs"
  value = var.deployment_method == "cloud-run" ? {
    gateway   = google_cloud_run_service.gateway[0].status[0].url
    auth      = google_cloud_run_service.auth[0].status[0].url
    quiz      = google_cloud_run_service.quiz[0].status[0].url
    game      = google_cloud_run_service.game[0].status[0].url
    user      = google_cloud_run_service.user[0].status[0].url
    analytics = google_cloud_run_service.analytics[0].status[0].url
    frontend  = google_cloud_run_service.frontend[0].status[0].url
  } : {}
}

output "artifact_registry_repository" {
  description = "Artifact Registry Repository"
  value       = var.deployment_method == "cloud-run" || var.deployment_method == "gke" ? google_artifact_registry_repository.docker_repo[0].name : "Not using Artifact Registry"
}

