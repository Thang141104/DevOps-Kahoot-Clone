# ============================================
# BENCHMARK 7: BigQuery
# ============================================

# Enable BigQuery API
resource "google_project_service" "bigquery" {
  count   = var.enable_bigquery ? 1 : 0
  project = var.gcp_project_id
  service = "bigquery.googleapis.com"
  
  disable_on_destroy = false
}

# Enable BigQuery Data Transfer Service
resource "google_project_service" "bigquery_datatransfer" {
  count   = var.enable_bigquery ? 1 : 0
  project = var.gcp_project_id
  service = "bigquerydatatransfer.googleapis.com"
  
  disable_on_destroy = false
}

# ============================================
# BigQuery Dataset for Analytics
# ============================================

resource "google_bigquery_dataset" "analytics" {
  count                       = var.enable_bigquery ? 1 : 0
  dataset_id                  = replace("${var.project_name}_analytics", "-", "_")
  project                     = var.gcp_project_id
  friendly_name               = "Analytics Dataset"
  description                 = "Dataset for storing analytics data and logs"
  location                    = var.bigquery_dataset_location
  default_table_expiration_ms = 31536000000  # 365 days

  labels = {
    environment = var.environment
    purpose     = "analytics"
    managed_by  = "terraform"
  }

  access {
    role          = "OWNER"
    user_by_email = google_service_account.analytics_sa.email
  }

  access {
    role          = "WRITER"
    user_by_email = google_service_account.cloud_run_sa.email
  }

  access {
    role          = "READER"
    special_group = "projectReaders"
  }
}

# ============================================
# BigQuery Tables
# ============================================

# Table: User Events
resource "google_bigquery_table" "user_events" {
  count       = var.enable_bigquery ? 1 : 0
  dataset_id  = google_bigquery_dataset.analytics[0].dataset_id
  project     = var.gcp_project_id
  table_id    = "user_events"
  description = "User activity events"

  time_partitioning {
    type  = "DAY"
    field = "event_timestamp"
  }

  clustering = ["user_id", "event_type"]

  schema = jsonencode([
    {
      name        = "event_id"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Unique event identifier"
    },
    {
      name        = "event_type"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Type of event (e.g., game_joined, quiz_created)"
    },
    {
      name        = "user_id"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "User identifier"
    },
    {
      name        = "event_timestamp"
      type        = "TIMESTAMP"
      mode        = "REQUIRED"
      description = "Event timestamp"
    },
    {
      name        = "metadata"
      type        = "JSON"
      mode        = "NULLABLE"
      description = "Additional event metadata"
    },
    {
      name        = "session_id"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Session identifier"
    },
    {
      name        = "ip_address"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "User IP address"
    },
    {
      name        = "user_agent"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "User agent string"
    }
  ])

  labels = {
    environment = var.environment
    managed_by  = "terraform"
  }
}

# Table: Game Sessions
resource "google_bigquery_table" "game_sessions" {
  count       = var.enable_bigquery ? 1 : 0
  dataset_id  = google_bigquery_dataset.analytics[0].dataset_id
  project     = var.gcp_project_id
  table_id    = "game_sessions"
  description = "Game session data"

  time_partitioning {
    type  = "DAY"
    field = "started_at"
  }

  clustering = ["quiz_id", "host_id"]

  schema = jsonencode([
    {
      name        = "session_id"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Game session identifier"
    },
    {
      name        = "pin"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Game PIN"
    },
    {
      name        = "quiz_id"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Quiz identifier"
    },
    {
      name        = "host_id"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Host user identifier"
    },
    {
      name        = "started_at"
      type        = "TIMESTAMP"
      mode        = "REQUIRED"
      description = "Game start timestamp"
    },
    {
      name        = "ended_at"
      type        = "TIMESTAMP"
      mode        = "NULLABLE"
      description = "Game end timestamp"
    },
    {
      name        = "total_players"
      type        = "INTEGER"
      mode        = "REQUIRED"
      description = "Total number of players"
    },
    {
      name        = "total_questions"
      type        = "INTEGER"
      mode        = "REQUIRED"
      description = "Total number of questions"
    },
    {
      name        = "winner_id"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Winner user identifier"
    },
    {
      name        = "winner_score"
      type        = "INTEGER"
      mode        = "NULLABLE"
      description = "Winner final score"
    }
  ])

  labels = {
    environment = var.environment
    managed_by  = "terraform"
  }
}

# Table: Quiz Statistics
resource "google_bigquery_table" "quiz_stats" {
  count       = var.enable_bigquery ? 1 : 0
  dataset_id  = google_bigquery_dataset.analytics[0].dataset_id
  project     = var.gcp_project_id
  table_id    = "quiz_statistics"
  description = "Quiz usage statistics"

  time_partitioning {
    type  = "DAY"
    field = "date"
  }

  clustering = ["quiz_id", "author_id"]

  schema = jsonencode([
    {
      name        = "quiz_id"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Quiz identifier"
    },
    {
      name        = "author_id"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Quiz author identifier"
    },
    {
      name        = "date"
      type        = "DATE"
      mode        = "REQUIRED"
      description = "Statistics date"
    },
    {
      name        = "total_plays"
      type        = "INTEGER"
      mode        = "REQUIRED"
      description = "Total number of plays"
    },
    {
      name        = "unique_players"
      type        = "INTEGER"
      mode        = "REQUIRED"
      description = "Number of unique players"
    },
    {
      name        = "average_score"
      type        = "FLOAT"
      mode        = "NULLABLE"
      description = "Average player score"
    },
    {
      name        = "completion_rate"
      type        = "FLOAT"
      mode        = "NULLABLE"
      description = "Completion rate percentage"
    }
  ])

  labels = {
    environment = var.environment
    managed_by  = "terraform"
  }
}

# Table: Application Logs (from Cloud Logging)
resource "google_bigquery_table" "app_logs" {
  count       = var.enable_bigquery ? 1 : 0
  dataset_id  = google_bigquery_dataset.analytics[0].dataset_id
  project     = var.gcp_project_id
  table_id    = "application_logs"
  description = "Application logs from Cloud Logging"

  time_partitioning {
    type  = "DAY"
    field = "timestamp"
  }

  clustering = ["severity", "resource_type"]

  schema = jsonencode([
    {
      name        = "timestamp"
      type        = "TIMESTAMP"
      mode        = "REQUIRED"
      description = "Log timestamp"
    },
    {
      name        = "severity"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Log severity (INFO, WARNING, ERROR, etc.)"
    },
    {
      name        = "resource_type"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "GCP resource type"
    },
    {
      name        = "log_name"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Log name"
    },
    {
      name        = "text_payload"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Log message"
    },
    {
      name        = "json_payload"
      type        = "JSON"
      mode        = "NULLABLE"
      description = "Structured log data"
    },
    {
      name        = "labels"
      type        = "JSON"
      mode        = "NULLABLE"
      description = "Log labels"
    }
  ])

  labels = {
    environment = var.environment
    managed_by  = "terraform"
  }
}

# ============================================
# BigQuery Views
# ============================================

# View: Daily Active Users
resource "google_bigquery_table" "daily_active_users" {
  count      = var.enable_bigquery ? 1 : 0
  dataset_id = google_bigquery_dataset.analytics[0].dataset_id
  project    = var.gcp_project_id
  table_id   = "daily_active_users"

  view {
    query          = <<-SQL
      SELECT
        DATE(event_timestamp) as date,
        COUNT(DISTINCT user_id) as active_users
      FROM
        `${var.gcp_project_id}.${google_bigquery_dataset.analytics[0].dataset_id}.user_events`
      WHERE
        event_timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
      GROUP BY
        date
      ORDER BY
        date DESC
    SQL
    use_legacy_sql = false
  }
}

# View: Popular Quizzes
resource "google_bigquery_table" "popular_quizzes" {
  count      = var.enable_bigquery ? 1 : 0
  dataset_id = google_bigquery_dataset.analytics[0].dataset_id
  project    = var.gcp_project_id
  table_id   = "popular_quizzes"

  view {
    query          = <<-SQL
      SELECT
        quiz_id,
        COUNT(*) as total_games,
        SUM(total_players) as total_players,
        MAX(ended_at) as last_played
      FROM
        `${var.gcp_project_id}.${google_bigquery_dataset.analytics[0].dataset_id}.game_sessions`
      WHERE
        started_at >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
      GROUP BY
        quiz_id
      ORDER BY
        total_games DESC
      LIMIT 100
    SQL
    use_legacy_sql = false
  }
}

# ============================================
# Scheduled Queries
# ============================================

# Daily aggregation of user events
resource "google_bigquery_data_transfer_config" "daily_aggregation" {
  count                  = var.enable_bigquery ? 1 : 0
  project                = var.gcp_project_id
  location               = var.bigquery_dataset_location  # Must match dataset location (US, EU, etc.)
  display_name           = "${var.project_name}-daily-aggregation"
  data_source_id         = "scheduled_query"
  schedule               = "every day 02:00"
  destination_dataset_id = google_bigquery_dataset.analytics[0].dataset_id

  params = {
    query = <<-SQL
      INSERT INTO `${var.gcp_project_id}.${google_bigquery_dataset.analytics[0].dataset_id}.quiz_statistics`
      SELECT
        quiz_id,
        host_id as author_id,
        DATE(started_at) as date,
        COUNT(*) as total_plays,
        COUNT(DISTINCT CONCAT(session_id, '-', CAST(total_players AS STRING))) as unique_players,
        AVG(winner_score) as average_score,
        AVG(CASE WHEN ended_at IS NOT NULL THEN 1.0 ELSE 0.0 END) as completion_rate
      FROM
        `${var.gcp_project_id}.${google_bigquery_dataset.analytics[0].dataset_id}.game_sessions`
      WHERE
        DATE(started_at) = CURRENT_DATE() - 1
      GROUP BY
        quiz_id, author_id, date
    SQL
  }
}

# ============================================
# Outputs
# ============================================

output "bigquery_dataset_id" {
  description = "BigQuery Dataset ID"
  value       = var.enable_bigquery ? google_bigquery_dataset.analytics[0].dataset_id : "BigQuery not enabled"
}

output "bigquery_dataset_url" {
  description = "BigQuery Dataset URL"
  value       = var.enable_bigquery ? "https://console.cloud.google.com/bigquery?project=${var.gcp_project_id}&p=${var.gcp_project_id}&d=${google_bigquery_dataset.analytics[0].dataset_id}&page=dataset" : "BigQuery not enabled"
}

output "bigquery_tables" {
  description = "BigQuery Tables"
  value = var.enable_bigquery ? {
    user_events    = google_bigquery_table.user_events[0].table_id
    game_sessions  = google_bigquery_table.game_sessions[0].table_id
    quiz_stats     = google_bigquery_table.quiz_stats[0].table_id
    app_logs       = google_bigquery_table.app_logs[0].table_id
  } : {}
}
