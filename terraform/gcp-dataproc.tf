# ============================================
# BENCHMARK 8: Dataproc
# ============================================

# Enable Dataproc API
resource "google_project_service" "dataproc" {
  count   = var.enable_dataproc ? 1 : 0
  project = var.gcp_project_id
  service = "dataproc.googleapis.com"
  
  disable_on_destroy = false
}

# ============================================
# Cloud Storage Bucket for Dataproc
# ============================================

resource "google_storage_bucket" "dataproc_staging" {
  count         = var.enable_dataproc ? 1 : 0
  name          = "${var.project_name}-dataproc-staging-${var.gcp_project_id}"
  project       = var.gcp_project_id
  location      = var.storage_location
  storage_class = "STANDARD"
  
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  lifecycle_rule {
    condition {
      age = 30  # Delete staging files after 30 days
    }
    action {
      type = "Delete"
    }
  }

  labels = {
    environment = var.environment
    purpose     = "dataproc-staging"
    managed_by  = "terraform"
  }
}

resource "google_storage_bucket" "dataproc_temp" {
  count         = var.enable_dataproc ? 1 : 0
  name          = "${var.project_name}-dataproc-temp-${var.gcp_project_id}"
  project       = var.gcp_project_id
  location      = var.storage_location
  storage_class = "STANDARD"
  
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  lifecycle_rule {
    condition {
      age = 1  # Delete temp files after 1 day
    }
    action {
      type = "Delete"
    }
  }

  labels = {
    environment = var.environment
    purpose     = "dataproc-temp"
    managed_by  = "terraform"
  }
}

# ============================================
# Dataproc Cluster
# ============================================

resource "google_dataproc_cluster" "analytics_cluster" {
  count   = var.enable_dataproc ? 1 : 0
  name    = "${var.project_name}-dataproc-cluster"
  project = var.gcp_project_id
  region  = var.gcp_region

  cluster_config {
    staging_bucket = google_storage_bucket.dataproc_staging[0].name
    temp_bucket    = google_storage_bucket.dataproc_temp[0].name

    # Master node configuration
    master_config {
      num_instances = 1
      machine_type  = "n1-standard-4"
      disk_config {
        boot_disk_type    = "pd-standard"
        boot_disk_size_gb = 50
      }
    }

    # Worker nodes configuration
    worker_config {
      num_instances = var.dataproc_num_workers
      machine_type  = var.dataproc_worker_machine_type
      disk_config {
        boot_disk_type    = "pd-standard"
        boot_disk_size_gb = 50
      }
    }

    # Preemptible workers (cost-effective)
    preemptible_worker_config {
      num_instances = 2
    }

    # Software configuration
    software_config {
      image_version = "2.1-debian11"  # Latest stable
      
      override_properties = {
        "dataproc:dataproc.allow.zero.workers" = "false"
        "spark:spark.executor.memory"          = "4g"
        "spark:spark.driver.memory"            = "4g"
        "spark:spark.executor.cores"           = "2"
      }

      optional_components = [
        "JUPYTER",
        "ZEPPELIN"
      ]
    }

    # Network configuration
    gce_cluster_config {
      network    = google_compute_network.vpc.id
      subnetwork = google_compute_subnetwork.subnet.id
      
      internal_ip_only = true  # No public IPs

      service_account = google_service_account.analytics_sa.email
      service_account_scopes = [
        "cloud-platform"
      ]

      tags = ["dataproc", "allow-internal"]
    }

    # Initialization actions
    initialization_action {
      script      = "gs://goog-dataproc-initialization-actions-${var.gcp_region}/python/pip-install.sh"
      timeout_sec = 500
    }

    # Lifecycle configuration (for cost savings)
    lifecycle_config {
      idle_delete_ttl = "3600s"  # Auto-delete after 1 hour idle
      auto_delete_time = null     # Don't auto-delete at specific time
    }

    # Encryption
    encryption_config {
      gce_pd_kms_key_name = null  # Use Google-managed encryption
    }
  }

  labels = {
    environment = var.environment
    purpose     = "analytics"
    managed_by  = "terraform"
  }
}

# ============================================
# Dataproc Workflow Template
# ============================================

resource "google_dataproc_workflow_template" "analytics_etl" {
  count    = var.enable_dataproc ? 1 : 0
  name     = "${var.project_name}-analytics-etl"
  project  = var.gcp_project_id
  location = var.gcp_region

  placement {
    managed_cluster {
      cluster_name = "${var.project_name}-ephemeral-cluster"
      
      config {
        staging_bucket = google_storage_bucket.dataproc_staging[0].name

        master_config {
          num_instances = 1
          machine_type  = "n1-standard-4"
          disk_config {
            boot_disk_type    = "pd-standard"
            boot_disk_size_gb = 50
          }
        }

        worker_config {
          num_instances = 2
          machine_type  = "n1-standard-4"
          disk_config {
            boot_disk_type    = "pd-standard"
            boot_disk_size_gb = 50
          }
        }

        software_config {
          image_version = "2.1-debian11"
        }

        gce_cluster_config {
          network    = google_compute_network.vpc.id
          subnetwork = google_compute_subnetwork.subnet.id
          
          internal_ip_only = true

          service_account = google_service_account.analytics_sa.email
          service_account_scopes = [
            "cloud-platform"
          ]
        }
      }
    }
  }

  jobs {
    step_id = "extract-game-data"
    
    spark_sql_job {
      query_list {
        queries = [
          <<-SQL
            SELECT
              session_id,
              quiz_id,
              COUNT(DISTINCT user_id) as unique_players,
              AVG(score) as avg_score
            FROM
              bigquery.table.`${var.gcp_project_id}.${var.enable_bigquery ? google_bigquery_dataset.analytics[0].dataset_id : "analytics"}.game_sessions`
            GROUP BY
              session_id, quiz_id
          SQL
        ]
      }
    }
  }

  jobs {
    step_id       = "load-to-bigquery"
    prerequisite_step_ids = ["extract-game-data"]
    
    spark_job {
      main_class = "com.google.cloud.dataproc.templates.LoadToBigQuery"
      jar_file_uris = [
        "gs://spark-lib/bigquery/spark-bigquery-latest_2.12.jar"
      ]
    }
  }

  labels = {
    environment = var.environment
    managed_by  = "terraform"
  }
}

# ============================================
# Dataproc Job (Example PySpark Job)
# ============================================

# Storage bucket for PySpark scripts
resource "google_storage_bucket_object" "pyspark_analytics_script" {
  count  = var.enable_dataproc ? 1 : 0
  name   = "scripts/analytics_job.py"
  bucket = google_storage_bucket.dataproc_staging[0].name
  
  content = <<-PYTHON
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, count, avg, sum as spark_sum
import sys

def main():
    # Initialize Spark Session
    spark = SparkSession.builder \
        .appName("Quiz Analytics ETL") \
        .config("spark.jars.packages", "com.google.cloud.spark:spark-bigquery-with-dependencies_2.12:0.32.2") \
        .getOrCreate()
    
    # Read from BigQuery
    project_id = "${var.gcp_project_id}"
    dataset_id = "${var.enable_bigquery ? google_bigquery_dataset.analytics[0].dataset_id : "analytics"}"
    
    # Load game sessions
    game_sessions = spark.read \
        .format("bigquery") \
        .option("table", f"{project_id}.{dataset_id}.game_sessions") \
        .load()
    
    # Load user events
    user_events = spark.read \
        .format("bigquery") \
        .option("table", f"{project_id}.{dataset_id}.user_events") \
        .load()
    
    # Compute quiz popularity metrics
    quiz_popularity = game_sessions \
        .groupBy("quiz_id") \
        .agg(
            count("session_id").alias("total_games"),
            spark_sum("total_players").alias("total_players"),
            avg("winner_score").alias("avg_winner_score")
        ) \
        .orderBy(col("total_games").desc())
    
    # Write results back to BigQuery
    quiz_popularity.write \
        .format("bigquery") \
        .option("table", f"{project_id}.{dataset_id}.quiz_popularity_metrics") \
        .option("writeMethod", "direct") \
        .mode("overwrite") \
        .save()
    
    print("Analytics ETL job completed successfully!")
    spark.stop()

if __name__ == "__main__":
    main()
  PYTHON
}

# ============================================
# Cloud Scheduler for Dataproc Jobs
# ============================================

resource "google_cloud_scheduler_job" "dataproc_daily_analytics" {
  count       = var.enable_dataproc ? 1 : 0
  name        = "${var.project_name}-daily-analytics"
  project     = var.gcp_project_id
  region      = var.gcp_region
  description = "Run daily analytics ETL on Dataproc"
  schedule    = "0 2 * * *"  # 2 AM daily
  time_zone   = "America/New_York"

  http_target {
    http_method = "POST"
    uri         = "https://dataproc.googleapis.com/v1/projects/${var.gcp_project_id}/regions/${var.gcp_region}/workflowTemplates/${google_dataproc_workflow_template.analytics_etl[0].name}:instantiate"
    
    oauth_token {
      service_account_email = google_service_account.analytics_sa.email
    }
  }

  retry_config {
    retry_count = 3
  }
}

# ============================================
# Outputs
# ============================================

output "dataproc_cluster_name" {
  description = "Dataproc Cluster Name"
  value       = var.enable_dataproc ? google_dataproc_cluster.analytics_cluster[0].name : "Dataproc not enabled"
}

output "dataproc_cluster_url" {
  description = "Dataproc Cluster URL"
  value       = var.enable_dataproc ? "https://console.cloud.google.com/dataproc/clusters/${google_dataproc_cluster.analytics_cluster[0].name}?project=${var.gcp_project_id}&region=${var.gcp_region}" : "Dataproc not enabled"
}

output "dataproc_staging_bucket" {
  description = "Dataproc Staging Bucket"
  value       = var.enable_dataproc ? google_storage_bucket.dataproc_staging[0].name : "Dataproc not enabled"
}

output "pyspark_script_path" {
  description = "PySpark Analytics Script Path"
  value       = var.enable_dataproc ? "gs://${google_storage_bucket.dataproc_staging[0].name}/${google_storage_bucket_object.pyspark_analytics_script[0].name}" : "Dataproc not enabled"
}
