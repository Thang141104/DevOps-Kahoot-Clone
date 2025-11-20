# Enable required APIs
resource "google_project_service" "cloud_run" {
  project = var.gcp_project_id
  service = "run.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloud_build" {
  project = var.gcp_project_id
  service = "cloudbuild.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "secret_manager" {
  project = var.gcp_project_id
  service = "secretmanager.googleapis.com"
  disable_on_destroy = false
}

# Service Account for Cloud Run
resource "google_service_account" "cloud_run_sa" {
  account_id   = "cloud-run-kahoot"
  display_name = "Cloud Run Service Account for Kahoot Clone"
  project      = var.gcp_project_id
}

# Secret Manager for MongoDB URI
resource "google_secret_manager_secret" "mongodb_uri" {
  secret_id = "mongodb-uri"
  project   = var.gcp_project_id
  
  replication {
    auto {}
  }
  
  depends_on = [google_project_service.secret_manager]
}

resource "google_secret_manager_secret_version" "mongodb_uri_version" {
  secret      = google_secret_manager_secret.mongodb_uri.id
  secret_data = var.mongodb_uri
}

resource "google_secret_manager_secret_iam_member" "mongodb_uri_access" {
  secret_id = google_secret_manager_secret.mongodb_uri.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

# ============================================================================
# DOCKER IMAGE BUILDS (Sequential to avoid quota limits)
# ============================================================================

# 1. Build Auth Service Image
resource "null_resource" "build_auth_image" {
  triggers = {
    dockerfile_hash = filemd5("${path.module}/../services/auth-service/Dockerfile")
    package_hash    = filemd5("${path.module}/../services/auth-service/package.json")
  }

  provisioner "local-exec" {
    command     = "gcloud builds submit --tag gcr.io/${var.gcp_project_id}/kahoot-clone-auth:latest ${path.module}/../services/auth-service"
    working_dir = path.module
  }

  depends_on = [google_project_service.cloud_build]
}

# 2. Build Quiz Service Image
resource "null_resource" "build_quiz_image" {
  triggers = {
    dockerfile_hash = filemd5("${path.module}/../services/quiz-service/Dockerfile")
    package_hash    = filemd5("${path.module}/../services/quiz-service/package.json")
  }

  provisioner "local-exec" {
    command     = "gcloud builds submit --tag gcr.io/${var.gcp_project_id}/kahoot-clone-quiz:latest ${path.module}/../services/quiz-service"
    working_dir = path.module
  }

  depends_on = [null_resource.build_auth_image]
}

# 3. Build User Service Image
resource "null_resource" "build_user_image" {
  triggers = {
    dockerfile_hash = filemd5("${path.module}/../services/user-service/Dockerfile")
    package_hash    = filemd5("${path.module}/../services/user-service/package.json")
  }

  provisioner "local-exec" {
    command     = "gcloud builds submit --tag gcr.io/${var.gcp_project_id}/kahoot-clone-user:latest ${path.module}/../services/user-service"
    working_dir = path.module
  }

  depends_on = [null_resource.build_quiz_image]
}

# 4. Build Game Service Image
resource "null_resource" "build_game_image" {
  triggers = {
    dockerfile_hash = filemd5("${path.module}/../services/game-service/Dockerfile")
    package_hash    = filemd5("${path.module}/../services/game-service/package.json")
  }

  provisioner "local-exec" {
    command     = "gcloud builds submit --tag gcr.io/${var.gcp_project_id}/kahoot-clone-game:latest ${path.module}/../services/game-service"
    working_dir = path.module
  }

  depends_on = [null_resource.build_user_image]
}

# 5. Build Analytics Service Image
resource "null_resource" "build_analytics_image" {
  triggers = {
    dockerfile_hash = filemd5("${path.module}/../services/analytics-service/Dockerfile")
    package_hash    = filemd5("${path.module}/../services/analytics-service/package.json")
  }

  provisioner "local-exec" {
    command     = "gcloud builds submit --tag gcr.io/${var.gcp_project_id}/kahoot-clone-analytics:latest ${path.module}/../services/analytics-service"
    working_dir = path.module
  }

  depends_on = [null_resource.build_game_image]
}

# 6. Build Gateway Service Image
resource "null_resource" "build_gateway_image" {
  triggers = {
    dockerfile_hash = filemd5("${path.module}/../gateway/Dockerfile")
    package_hash    = filemd5("${path.module}/../gateway/package.json")
  }

  provisioner "local-exec" {
    command     = "gcloud builds submit --tag gcr.io/${var.gcp_project_id}/kahoot-clone-gateway:latest ${path.module}/../gateway"
    working_dir = path.module
  }

  depends_on = [null_resource.build_analytics_image]
}

# 7. Build Frontend Image
resource "null_resource" "build_frontend_image" {
  triggers = {
    dockerfile_hash   = filemd5("${path.module}/../frontend/Dockerfile")
    package_hash      = filemd5("${path.module}/../frontend/package.json")
    cloudbuild_hash   = filemd5("${path.module}/../frontend/cloudbuild.yaml")
    gateway_url       = google_cloud_run_service.gateway.status[0].url
    game_url          = google_cloud_run_service.game.status[0].url
  }

  provisioner "local-exec" {
    command     = "gcloud builds submit --config=cloudbuild.yaml --substitutions=_REACT_APP_API_URL=${google_cloud_run_service.gateway.status[0].url},_REACT_APP_SOCKET_URL=${google_cloud_run_service.game.status[0].url} ."
    working_dir = "${path.module}/../frontend"
  }

  depends_on = [
    null_resource.build_gateway_image,
    google_cloud_run_service.gateway,
    google_cloud_run_service.game
  ]
}

# Wait for all images to be available
resource "time_sleep" "wait_for_images" {
  create_duration = "10s"

  depends_on = [
    null_resource.build_auth_image,
    null_resource.build_quiz_image,
    null_resource.build_user_image,
    null_resource.build_game_image,
    null_resource.build_analytics_image,
    null_resource.build_gateway_image
  ]
}

# ============================================================================
# CLOUD RUN SERVICES
# ============================================================================

# Auth Service
resource "google_cloud_run_service" "auth" {
  name     = "kahoot-auth-service"
  location = var.gcp_region
  project  = var.gcp_project_id

  template {
    spec {
      service_account_name = google_service_account.cloud_run_sa.email
      containers {
        image = "gcr.io/${var.gcp_project_id}/kahoot-clone-auth:latest"
        ports {
          container_port = 3001
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
          name  = "JWT_SECRET"
          value = "your-secret-key-change-in-production"
        }
        env {
          name  = "NODE_ENV"
          value = "production"
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  depends_on = [
    google_project_service.cloud_run,
    null_resource.build_auth_image,
    time_sleep.wait_for_images
  ]
}

# Quiz Service
resource "google_cloud_run_service" "quiz" {
  name     = "kahoot-quiz-service"
  location = var.gcp_region
  project  = var.gcp_project_id

  template {
    spec {
      service_account_name = google_service_account.cloud_run_sa.email
      containers {
        image = "gcr.io/${var.gcp_project_id}/kahoot-clone-quiz:latest"
        ports {
          container_port = 3002
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
          name  = "JWT_SECRET"
          value = "your-secret-key-change-in-production"
        }
        env {
          name  = "NODE_ENV"
          value = "production"
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  depends_on = [
    google_project_service.cloud_run,
    null_resource.build_quiz_image,
    time_sleep.wait_for_images
  ]
}

# User Service
resource "google_cloud_run_service" "user" {
  name     = "kahoot-user-service"
  location = var.gcp_region
  project  = var.gcp_project_id

  template {
    spec {
      service_account_name = google_service_account.cloud_run_sa.email
      containers {
        image = "gcr.io/${var.gcp_project_id}/kahoot-clone-user:latest"
        ports {
          container_port = 3004
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
          name  = "JWT_SECRET"
          value = "your-secret-key-change-in-production"
        }
        env {
          name  = "NODE_ENV"
          value = "production"
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  depends_on = [
    google_project_service.cloud_run,
    null_resource.build_user_image,
    time_sleep.wait_for_images
  ]
}

# Game Service
resource "google_cloud_run_service" "game" {
  name     = "kahoot-game-service"
  location = var.gcp_region
  project  = var.gcp_project_id

  template {
    spec {
      service_account_name = google_service_account.cloud_run_sa.email
      containers {
        image = "gcr.io/${var.gcp_project_id}/kahoot-clone-game:latest"
        ports {
          container_port = 3003
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
          name  = "JWT_SECRET"
          value = "your-secret-key-change-in-production"
        }
        env {
          name  = "NODE_ENV"
          value = "production"
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  depends_on = [
    google_project_service.cloud_run,
    null_resource.build_game_image,
    time_sleep.wait_for_images
  ]
}

# Analytics Service
resource "google_cloud_run_service" "analytics" {
  name     = "kahoot-analytics-service"
  location = var.gcp_region
  project  = var.gcp_project_id

  template {
    spec {
      service_account_name = google_service_account.cloud_run_sa.email
      containers {
        image = "gcr.io/${var.gcp_project_id}/kahoot-clone-analytics:latest"
        ports {
          container_port = 3005
        }
        env {
          name  = "JWT_SECRET"
          value = "your-secret-key-change-in-production"
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
          name  = "NODE_ENV"
          value = "production"
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  depends_on = [
    google_project_service.cloud_run,
    null_resource.build_analytics_image,
    time_sleep.wait_for_images
  ]
}

# Gateway Service
resource "google_cloud_run_service" "gateway" {
  name     = "kahoot-gateway-service"
  location = var.gcp_region
  project  = var.gcp_project_id

  template {
    spec {
      service_account_name = google_service_account.cloud_run_sa.email
      containers {
        image = "gcr.io/${var.gcp_project_id}/kahoot-clone-gateway:latest"
        ports {
          container_port = 3000
        }
        env {
          name  = "AUTH_SERVICE_URL"
          value = google_cloud_run_service.auth.status[0].url
        }
        env {
          name  = "QUIZ_SERVICE_URL"
          value = google_cloud_run_service.quiz.status[0].url
        }
        env {
          name  = "GAME_SERVICE_URL"
          value = google_cloud_run_service.game.status[0].url
        }
        env {
          name  = "USER_SERVICE_URL"
          value = google_cloud_run_service.user.status[0].url
        }
        env {
          name  = "ANALYTICS_SERVICE_URL"
          value = google_cloud_run_service.analytics.status[0].url
        }
        env {
          name  = "NODE_ENV"
          value = "production"
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  depends_on = [
    google_project_service.cloud_run,
    null_resource.build_gateway_image,
    time_sleep.wait_for_images,
    google_cloud_run_service.auth,
    google_cloud_run_service.quiz,
    google_cloud_run_service.game,
    google_cloud_run_service.user,
    google_cloud_run_service.analytics
  ]
}

# Frontend Service
resource "google_cloud_run_service" "frontend" {
  name     = "kahoot-frontend-service"
  location = var.gcp_region
  project  = var.gcp_project_id

  template {
    spec {
      service_account_name = google_service_account.cloud_run_sa.email
      containers {
        image = "gcr.io/${var.gcp_project_id}/kahoot-clone-frontend:latest"
        ports {
          container_port = 3006
        }
        env {
          name  = "REACT_APP_API_URL"
          value = google_cloud_run_service.gateway.status[0].url
        }
        env {
          name  = "REACT_APP_SOCKET_URL"
          value = google_cloud_run_service.game.status[0].url
        }
        env {
          name  = "NODE_ENV"
          value = "production"
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  depends_on = [
    google_project_service.cloud_run,
    null_resource.build_frontend_image,
    time_sleep.wait_for_images,
    google_cloud_run_service.gateway
  ]
}

# ============================================================================
# IAM - Public Access
# ============================================================================

resource "google_cloud_run_service_iam_member" "auth_public" {
  service  = google_cloud_run_service.auth.name
  location = google_cloud_run_service.auth.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_cloud_run_service_iam_member" "quiz_public" {
  service  = google_cloud_run_service.quiz.name
  location = google_cloud_run_service.quiz.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_cloud_run_service_iam_member" "user_public" {
  service  = google_cloud_run_service.user.name
  location = google_cloud_run_service.user.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_cloud_run_service_iam_member" "game_public" {
  service  = google_cloud_run_service.game.name
  location = google_cloud_run_service.game.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_cloud_run_service_iam_member" "analytics_public" {
  service  = google_cloud_run_service.analytics.name
  location = google_cloud_run_service.analytics.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_cloud_run_service_iam_member" "gateway_public" {
  service  = google_cloud_run_service.gateway.name
  location = google_cloud_run_service.gateway.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_cloud_run_service_iam_member" "frontend_public" {
  service  = google_cloud_run_service.frontend.name
  location = google_cloud_run_service.frontend.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "gateway_url" {
  description = "URL of the Gateway service"
  value       = google_cloud_run_service.gateway.status[0].url
}

output "frontend_url" {
  description = "URL of the Frontend service"
  value       = google_cloud_run_service.frontend.status[0].url
}

output "auth_service_url" {
  description = "URL of the Auth service"
  value       = google_cloud_run_service.auth.status[0].url
}

output "quiz_service_url" {
  description = "URL of the Quiz service"
  value       = google_cloud_run_service.quiz.status[0].url
}

output "user_service_url" {
  description = "URL of the User service"
  value       = google_cloud_run_service.user.status[0].url
}

output "game_service_url" {
  description = "URL of the Game service"
  value       = google_cloud_run_service.game.status[0].url
}

output "analytics_service_url" {
  description = "URL of the Analytics service"
  value       = google_cloud_run_service.analytics.status[0].url
}
