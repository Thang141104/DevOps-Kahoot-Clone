# ============================================
# BENCHMARK 6: Cloud SQL Database Services
# ============================================

# Enable Cloud SQL Admin API
resource "google_project_service" "sqladmin" {
  count   = var.enable_cloud_sql ? 1 : 0
  project = var.gcp_project_id
  service = "sqladmin.googleapis.com"
  
  disable_on_destroy = false
}

# ============================================
# Cloud SQL Instance (PostgreSQL)
# Alternative to MongoDB Atlas
# ============================================

resource "google_sql_database_instance" "postgres" {
  count            = var.enable_cloud_sql ? 1 : 0
  name             = "${var.project_name}-postgres-${random_id.db_suffix[0].hex}"
  project          = var.gcp_project_id
  region           = var.gcp_region
  database_version = "POSTGRES_15"

  settings {
    tier              = "db-f1-micro"  # Change to db-custom-2-7680 for production
    availability_type = "REGIONAL"     # Use ZONAL for dev
    disk_type         = "PD_SSD"
    disk_size         = 20
    disk_autoresize   = true

    backup_configuration {
      enabled                        = true
      start_time                     = "03:00"  # 3 AM
      point_in_time_recovery_enabled = true
      transaction_log_retention_days = 7
      backup_retention_settings {
        retained_backups = 7
        retention_unit   = "COUNT"
      }
    }

    ip_configuration {
      ipv4_enabled    = false  # Disable public IP
      private_network = google_compute_network.vpc.id
      require_ssl     = true
    }

    database_flags {
      name  = "max_connections"
      value = "100"
    }

    database_flags {
      name  = "shared_buffers"
      value = "256000"  # 256MB
    }

    maintenance_window {
      day          = 7  # Sunday
      hour         = 3  # 3 AM
      update_track = "stable"
    }

    insights_config {
      query_insights_enabled  = true
      query_string_length     = 1024
      record_application_tags = true
      record_client_address   = true
    }
  }

  deletion_protection = true

  depends_on = [
    google_service_networking_connection.private_vpc_connection
  ]
}

# Random suffix for database name
resource "random_id" "db_suffix" {
  count       = var.enable_cloud_sql ? 1 : 0
  byte_length = 4
}

# Database
resource "google_sql_database" "quiz_app_db" {
  count    = var.enable_cloud_sql ? 1 : 0
  name     = "quiz_app"
  project  = var.gcp_project_id
  instance = google_sql_database_instance.postgres[0].name
}

# Database User
resource "random_password" "db_password" {
  count   = var.enable_cloud_sql ? 1 : 0
  length  = 32
  special = true
}

resource "google_sql_user" "app_user" {
  count    = var.enable_cloud_sql ? 1 : 0
  name     = "quiz_app_user"
  project  = var.gcp_project_id
  instance = google_sql_database_instance.postgres[0].name
  password = random_password.db_password[0].result
}

# Store database password in Secret Manager
resource "google_secret_manager_secret" "db_password" {
  count     = var.enable_cloud_sql ? 1 : 0
  secret_id = "${var.project_name}-db-password"
  project   = var.gcp_project_id

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "db_password" {
  count       = var.enable_cloud_sql ? 1 : 0
  secret      = google_secret_manager_secret.db_password[0].id
  secret_data = random_password.db_password[0].result
}

# ============================================
# Cloud SQL Proxy Setup (for local development)
# ============================================

# Service Account for Cloud SQL Proxy
resource "google_service_account" "cloud_sql_proxy" {
  count        = var.enable_cloud_sql ? 1 : 0
  account_id   = "${var.project_name}-sql-proxy-sa"
  display_name = "Service Account for Cloud SQL Proxy"
  project      = var.gcp_project_id
}

resource "google_project_iam_member" "cloud_sql_proxy_client" {
  count   = var.enable_cloud_sql ? 1 : 0
  project = var.gcp_project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.cloud_sql_proxy[0].email}"
}

# ============================================
# MongoDB Atlas Integration (Alternative)
# Note: Using MongoDB Atlas instead of Cloud SQL
# Connection string stored in Secret Manager
# ============================================

# Store MongoDB Atlas connection string
resource "google_secret_manager_secret" "mongodb_atlas_uri" {
  count     = var.enable_cloud_sql ? 0 : 1
  secret_id = "${var.project_name}-mongodb-atlas-uri"
  project   = var.gcp_project_id

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "mongodb_atlas_uri" {
  count       = var.enable_cloud_sql ? 0 : 1
  secret      = google_secret_manager_secret.mongodb_atlas_uri[0].id
  secret_data = var.mongodb_uri
}

# ============================================
# Database Monitoring & Alerts
# ============================================

# Alert for high CPU usage on Cloud SQL
resource "google_monitoring_alert_policy" "cloudsql_high_cpu" {
  count        = var.enable_cloud_sql && var.enable_cloud_monitoring ? 1 : 0
  display_name = "${var.project_name}-cloudsql-high-cpu"
  project      = var.gcp_project_id
  combiner     = "OR"

  conditions {
    display_name = "Cloud SQL - High CPU Usage"

    condition_threshold {
      filter          = "resource.type=\"cloudsql_database\" AND metric.type=\"cloudsql.googleapis.com/database/cpu/utilization\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8  # 80%
      
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = var.email_user != "" ? [google_monitoring_notification_channel.email[0].id] : []

  alert_strategy {
    auto_close = "1800s"
  }
}

# Alert for high memory usage on Cloud SQL
resource "google_monitoring_alert_policy" "cloudsql_high_memory" {
  count        = var.enable_cloud_sql && var.enable_cloud_monitoring ? 1 : 0
  display_name = "${var.project_name}-cloudsql-high-memory"
  project      = var.gcp_project_id
  combiner     = "OR"

  conditions {
    display_name = "Cloud SQL - High Memory Usage"

    condition_threshold {
      filter          = "resource.type=\"cloudsql_database\" AND metric.type=\"cloudsql.googleapis.com/database/memory/utilization\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.9  # 90%
      
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = var.email_user != "" ? [google_monitoring_notification_channel.email[0].id] : []

  alert_strategy {
    auto_close = "1800s"
  }
}

# ============================================
# Outputs
# ============================================

output "cloud_sql_instance_name" {
  description = "Cloud SQL Instance Name"
  value       = var.enable_cloud_sql ? google_sql_database_instance.postgres[0].name : "Cloud SQL not enabled - using MongoDB Atlas"
}

output "cloud_sql_connection_name" {
  description = "Cloud SQL Connection Name (for Cloud SQL Proxy)"
  value       = var.enable_cloud_sql ? google_sql_database_instance.postgres[0].connection_name : "Cloud SQL not enabled"
}

output "cloud_sql_private_ip" {
  description = "Cloud SQL Private IP"
  value       = var.enable_cloud_sql ? google_sql_database_instance.postgres[0].private_ip_address : "Cloud SQL not enabled"
}

output "database_connection_string" {
  description = "Database Connection String"
  value       = var.enable_cloud_sql ? "postgresql://${google_sql_user.app_user[0].name}:PASSWORD@${google_sql_database_instance.postgres[0].private_ip_address}:5432/${google_sql_database.quiz_app_db[0].name}" : "Using MongoDB Atlas - see Secret Manager"
  sensitive   = true
}

output "db_password_secret" {
  description = "Database Password Secret Manager Path"
  value       = var.enable_cloud_sql ? google_secret_manager_secret.db_password[0].id : "Using MongoDB Atlas"
  sensitive   = true
}
