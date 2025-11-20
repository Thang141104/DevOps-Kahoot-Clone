# ============================================
# BENCHMARK 2: Logging and Monitoring
# ============================================

# Enable required APIs
resource "google_project_service" "logging" {
  project = var.gcp_project_id
  service = "logging.googleapis.com"
  
  disable_on_destroy = false
}

resource "google_project_service" "monitoring" {
  project = var.gcp_project_id
  service = "monitoring.googleapis.com"
  
  disable_on_destroy = false
}

resource "google_project_service" "cloud_trace" {
  project = var.gcp_project_id
  service = "cloudtrace.googleapis.com"
  
  disable_on_destroy = false
}

resource "google_project_service" "cloud_profiler" {
  project = var.gcp_project_id
  service = "cloudprofiler.googleapis.com"
  
  disable_on_destroy = false
}

# ============================================
# Cloud Logging - Log Sinks
# ============================================

# Log Sink for Application Logs to BigQuery
resource "google_logging_project_sink" "app_logs_to_bigquery" {
  count       = var.enable_bigquery && var.enable_cloud_monitoring ? 1 : 0
  name        = "${var.project_name}-app-logs-sink"
  project     = var.gcp_project_id
  destination = "bigquery.googleapis.com/projects/${var.gcp_project_id}/datasets/${google_bigquery_dataset.analytics[0].dataset_id}"

  # Filter for application logs
  filter = <<-EOT
    resource.type="cloud_run_revision"
    OR resource.type="k8s_container"
    OR resource.type="gce_instance"
    severity >= "INFO"
  EOT

  unique_writer_identity = true
  
  bigquery_options {
    use_partitioned_tables = true
  }
}

# Grant BigQuery Data Editor to the log sink service account
resource "google_bigquery_dataset_iam_member" "log_sink_bigquery" {
  count      = var.enable_bigquery && var.enable_cloud_monitoring ? 1 : 0
  project    = var.gcp_project_id
  dataset_id = google_bigquery_dataset.analytics[0].dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = google_logging_project_sink.app_logs_to_bigquery[0].writer_identity
}

# Log Sink for Error Logs to Cloud Storage
resource "google_logging_project_sink" "error_logs_to_storage" {
  count       = var.enable_cloud_monitoring ? 1 : 0
  name        = "${var.project_name}-error-logs-sink"
  project     = var.gcp_project_id
  destination = "storage.googleapis.com/${google_storage_bucket.logs[0].name}"

  # Filter for error and critical logs only
  filter = <<-EOT
    severity >= "ERROR"
  EOT

  unique_writer_identity = true
}

# Grant Storage Object Creator to the log sink service account
resource "google_storage_bucket_iam_member" "log_sink_storage" {
  count  = var.enable_cloud_monitoring ? 1 : 0
  bucket = google_storage_bucket.logs[0].name
  role   = "roles/storage.objectCreator"
  member = google_logging_project_sink.error_logs_to_storage[0].writer_identity
}

# ============================================
# Cloud Monitoring - Uptime Checks
# ============================================

# Uptime Check for Gateway Service
resource "google_monitoring_uptime_check_config" "gateway_uptime" {
  count        = var.enable_cloud_monitoring && var.deployment_method == "cloud-run" ? 1 : 0
  display_name = "${var.project_name}-gateway-uptime"
  project      = var.gcp_project_id
  timeout      = "10s"
  period       = "60s"

  http_check {
    path           = "/health"
    port           = 443
    use_ssl        = true
    validate_ssl   = true
    request_method = "GET"
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = var.gcp_project_id
      host       = google_cloud_run_service.gateway[0].status[0].url
    }
  }

  content_matchers {
    content = "OK"
    matcher = "CONTAINS_STRING"
  }
}

# ============================================
# Cloud Monitoring - Alert Policies
# ============================================

# Notification Channel for Alerts (Email)
resource "google_monitoring_notification_channel" "email" {
  count        = var.enable_cloud_monitoring && var.email_user != "" ? 1 : 0
  display_name = "${var.project_name}-email-alerts"
  project      = var.gcp_project_id
  type         = "email"

  labels = {
    email_address = var.email_user
  }
}

# Alert Policy: High Error Rate
resource "google_monitoring_alert_policy" "high_error_rate" {
  count        = var.enable_cloud_monitoring ? 1 : 0
  display_name = "${var.project_name}-high-error-rate"
  project      = var.gcp_project_id
  combiner     = "OR"

  conditions {
    display_name = "Cloud Run - High Error Rate"

    condition_threshold {
      filter          = "resource.type=\"cloud_run_revision\" AND metric.type=\"run.googleapis.com/request_count\" AND metric.labels.response_code_class=\"5xx\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 10
      
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }

  notification_channels = var.email_user != "" ? [google_monitoring_notification_channel.email[0].id] : []

  alert_strategy {
    auto_close = "1800s"
  }

  documentation {
    content   = "High error rate detected in Cloud Run services. Check logs for more details."
    mime_type = "text/markdown"
  }
}

# Alert Policy: High CPU Usage
resource "google_monitoring_alert_policy" "high_cpu" {
  count        = var.enable_cloud_monitoring ? 1 : 0
  display_name = "${var.project_name}-high-cpu-usage"
  project      = var.gcp_project_id
  combiner     = "OR"

  conditions {
    display_name = "Cloud Run - High CPU Usage"

    condition_threshold {
      filter          = "resource.type=\"cloud_run_revision\" AND metric.type=\"run.googleapis.com/container/cpu/utilizations\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8  # 80% CPU
      
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

# Alert Policy: High Memory Usage
resource "google_monitoring_alert_policy" "high_memory" {
  count        = var.enable_cloud_monitoring ? 1 : 0
  display_name = "${var.project_name}-high-memory-usage"
  project      = var.gcp_project_id
  combiner     = "OR"

  conditions {
    display_name = "Cloud Run - High Memory Usage"

    condition_threshold {
      filter          = "resource.type=\"cloud_run_revision\" AND metric.type=\"run.googleapis.com/container/memory/utilizations\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.9  # 90% Memory
      
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

# Alert Policy: Service Downtime
resource "google_monitoring_alert_policy" "service_down" {
  count        = var.enable_cloud_monitoring ? 1 : 0
  display_name = "${var.project_name}-service-downtime"
  project      = var.gcp_project_id
  combiner     = "OR"

  conditions {
    display_name = "Uptime Check Failed"

    condition_threshold {
      filter          = "resource.type=\"uptime_url\" AND metric.type=\"monitoring.googleapis.com/uptime_check/check_passed\""
      duration        = "300s"
      comparison      = "COMPARISON_LT"
      threshold_value = 1
      
      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_FRACTION_TRUE"
        cross_series_reducer = "REDUCE_MEAN"
      }
    }
  }

  notification_channels = var.email_user != "" ? [google_monitoring_notification_channel.email[0].id] : []

  alert_strategy {
    auto_close = "1800s"
  }

  documentation {
    content   = "Service uptime check failed. Service may be down or unresponsive."
    mime_type = "text/markdown"
  }
}

# ============================================
# Cloud Monitoring - Custom Dashboard
# ============================================

resource "google_monitoring_dashboard" "main" {
  count          = var.enable_cloud_monitoring ? 1 : 0
  dashboard_json = jsonencode({
    displayName = "${var.project_name} - Application Dashboard"
    
    mosaicLayout = {
      columns = 12
      
      tiles = [
        {
          width  = 6
          height = 4
          widget = {
            title = "Request Rate (requests/sec)"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"cloud_run_revision\" AND metric.type=\"run.googleapis.com/request_count\""
                    aggregation = {
                      alignmentPeriod  = "60s"
                      perSeriesAligner = "ALIGN_RATE"
                    }
                  }
                }
                plotType = "LINE"
              }]
            }
          }
        },
        {
          xPos   = 6
          width  = 6
          height = 4
          widget = {
            title = "Error Rate (errors/sec)"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"cloud_run_revision\" AND metric.type=\"run.googleapis.com/request_count\" AND metric.labels.response_code_class=\"5xx\""
                    aggregation = {
                      alignmentPeriod  = "60s"
                      perSeriesAligner = "ALIGN_RATE"
                    }
                  }
                }
                plotType = "LINE"
              }]
            }
          }
        },
        {
          yPos   = 4
          width  = 6
          height = 4
          widget = {
            title = "CPU Utilization (%)"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"cloud_run_revision\" AND metric.type=\"run.googleapis.com/container/cpu/utilizations\""
                    aggregation = {
                      alignmentPeriod  = "60s"
                      perSeriesAligner = "ALIGN_MEAN"
                    }
                  }
                }
                plotType = "LINE"
              }]
            }
          }
        },
        {
          xPos   = 6
          yPos   = 4
          width  = 6
          height = 4
          widget = {
            title = "Memory Utilization (%)"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"cloud_run_revision\" AND metric.type=\"run.googleapis.com/container/memory/utilizations\""
                    aggregation = {
                      alignmentPeriod  = "60s"
                      perSeriesAligner = "ALIGN_MEAN"
                    }
                  }
                }
                plotType = "LINE"
              }]
            }
          }
        }
      ]
    }
  })
}

# ============================================
# Outputs
# ============================================

output "monitoring_dashboard_url" {
  description = "URL to Cloud Monitoring Dashboard"
  value       = var.enable_cloud_monitoring ? "https://console.cloud.google.com/monitoring/dashboards/custom/${google_monitoring_dashboard.main[0].id}?project=${var.gcp_project_id}" : "Not enabled"
}

output "logs_explorer_url" {
  description = "URL to Cloud Logging Explorer"
  value       = "https://console.cloud.google.com/logs/query?project=${var.gcp_project_id}"
}
