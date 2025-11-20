# ============================================
# Automatic Docker Image Building
# ============================================
# This file uses null_resource with local-exec to build
# Docker images automatically when running terraform apply

# Build Auth Service Image
resource "null_resource" "build_auth_image" {
  count = var.deployment_method == "cloud-run" ? 1 : 0

  triggers = {
    # Rebuild when Dockerfile or package.json changes
    dockerfile_hash = filemd5("${path.module}/../services/auth-service/Dockerfile")
    package_hash    = filemd5("${path.module}/../services/auth-service/package.json")
  }

  provisioner "local-exec" {
    command     = "gcloud builds submit --tag gcr.io/${var.gcp_project_id}/kahoot-clone-auth:latest ${path.module}/../services/auth-service --project=${var.gcp_project_id}"
    working_dir = path.module
  }
}

# Build Quiz Service Image
resource "null_resource" "build_quiz_image" {
  count = var.deployment_method == "cloud-run" ? 1 : 0

  triggers = {
    dockerfile_hash = filemd5("${path.module}/../services/quiz-service/Dockerfile")
    package_hash    = filemd5("${path.module}/../services/quiz-service/package.json")
  }

  provisioner "local-exec" {
    command     = "gcloud builds submit --tag gcr.io/${var.gcp_project_id}/kahoot-clone-quiz:latest ${path.module}/../services/quiz-service --project=${var.gcp_project_id}"
    working_dir = path.module
  }
}

# Build User Service Image
resource "null_resource" "build_user_image" {
  count = var.deployment_method == "cloud-run" ? 1 : 0

  triggers = {
    dockerfile_hash = filemd5("${path.module}/../services/user-service/Dockerfile")
    package_hash    = filemd5("${path.module}/../services/user-service/package.json")
  }

  provisioner "local-exec" {
    command     = "gcloud builds submit --tag gcr.io/${var.gcp_project_id}/kahoot-clone-user:latest ${path.module}/../services/user-service --project=${var.gcp_project_id}"
    working_dir = path.module
  }
}

# Build Game Service Image
resource "null_resource" "build_game_image" {
  count = var.deployment_method == "cloud-run" ? 1 : 0

  triggers = {
    dockerfile_hash = filemd5("${path.module}/../services/game-service/Dockerfile")
    package_hash    = filemd5("${path.module}/../services/game-service/package.json")
  }

  provisioner "local-exec" {
    command     = "gcloud builds submit --tag gcr.io/${var.gcp_project_id}/kahoot-clone-game:latest ${path.module}/../services/game-service --project=${var.gcp_project_id}"
    working_dir = path.module
  }
}

# Build Analytics Service Image
resource "null_resource" "build_analytics_image" {
  count = var.deployment_method == "cloud-run" ? 1 : 0

  triggers = {
    dockerfile_hash = filemd5("${path.module}/../services/analytics-service/Dockerfile")
    package_hash    = filemd5("${path.module}/../services/analytics-service/package.json")
  }

  provisioner "local-exec" {
    command     = "gcloud builds submit --tag gcr.io/${var.gcp_project_id}/kahoot-clone-analytics:latest ${path.module}/../services/analytics-service --project=${var.gcp_project_id}"
    working_dir = path.module
  }
}

# Build Gateway Image
resource "null_resource" "build_gateway_image" {
  count = var.deployment_method == "cloud-run" ? 1 : 0

  triggers = {
    dockerfile_hash = filemd5("${path.module}/../gateway/Dockerfile")
    package_hash    = filemd5("${path.module}/../gateway/package.json")
  }

  provisioner "local-exec" {
    command     = "gcloud builds submit --tag gcr.io/${var.gcp_project_id}/kahoot-clone-gateway:latest ${path.module}/../gateway --project=${var.gcp_project_id}"
    working_dir = path.module
  }
}

# Build Frontend Image
resource "null_resource" "build_frontend_image" {
  count = var.deployment_method == "cloud-run" ? 1 : 0

  triggers = {
    dockerfile_hash = filemd5("${path.module}/../frontend/Dockerfile")
    package_hash    = filemd5("${path.module}/../frontend/package.json")
  }

  provisioner "local-exec" {
    command     = "gcloud builds submit --tag gcr.io/${var.gcp_project_id}/kahoot-clone-frontend:latest ${path.module}/../frontend --project=${var.gcp_project_id}"
    working_dir = path.module
  }
}

# Make Cloud Run services depend on image builds
resource "time_sleep" "wait_for_images" {
  count = var.deployment_method == "cloud-run" ? 1 : 0

  depends_on = [
    null_resource.build_auth_image,
    null_resource.build_quiz_image,
    null_resource.build_user_image,
    null_resource.build_game_image,
    null_resource.build_analytics_image,
    null_resource.build_gateway_image,
    null_resource.build_frontend_image
  ]

  create_duration = "10s"  # Wait 10 seconds for images to be available
}

# Output build status
output "docker_images_built" {
  description = "Docker images build status"
  value = var.deployment_method == "cloud-run" ? {
    auth      = "gcr.io/${var.gcp_project_id}/kahoot-clone-auth:latest"
    quiz      = "gcr.io/${var.gcp_project_id}/kahoot-clone-quiz:latest"
    user      = "gcr.io/${var.gcp_project_id}/kahoot-clone-user:latest"
    game      = "gcr.io/${var.gcp_project_id}/kahoot-clone-game:latest"
    analytics = "gcr.io/${var.gcp_project_id}/kahoot-clone-analytics:latest"
    gateway   = "gcr.io/${var.gcp_project_id}/kahoot-clone-gateway:latest"
    frontend  = "gcr.io/${var.gcp_project_id}/kahoot-clone-frontend:latest"
  } : {}
}
