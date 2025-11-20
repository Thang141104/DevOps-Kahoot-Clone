# ============================================
# GCP Infrastructure Outputs
# ============================================

# Project Information
output "project_id" {
  description = "GCP Project ID"
  value       = var.gcp_project_id
}

output "project_region" {
  description = "GCP Region"
  value       = var.gcp_region
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

# ============================================
# Network Outputs (from gcp-networking.tf)
# ============================================

output "application_url" {
  description = "Main Application URL"
  value = var.deployment_method == "cloud-run" ? (
    length(google_cloud_run_service.frontend) > 0 ? 
    google_cloud_run_service.frontend[0].status[0].url : 
    "Not deployed yet"
  ) : (
    var.enable_gke ? 
    "http://${google_compute_global_address.lb_ip[0].address}" : 
    "Not configured"
  )
}

output "api_gateway_url" {
  description = "API Gateway URL"
  value = var.deployment_method == "cloud-run" ? (
    length(google_cloud_run_service.gateway) > 0 ? 
    google_cloud_run_service.gateway[0].status[0].url : 
    "Not deployed yet"
  ) : "Check GKE services"
}

# ============================================
# Service Endpoints
# ============================================

output "service_endpoints" {
  description = "All service endpoints"
  value = {
    deployment_method = var.deployment_method
    cloud_run_urls = var.deployment_method == "cloud-run" ? {
      gateway   = length(google_cloud_run_service.gateway) > 0 ? google_cloud_run_service.gateway[0].status[0].url : null
      auth      = length(google_cloud_run_service.auth) > 0 ? google_cloud_run_service.auth[0].status[0].url : null
      quiz      = length(google_cloud_run_service.quiz) > 0 ? google_cloud_run_service.quiz[0].status[0].url : null
      game      = length(google_cloud_run_service.game) > 0 ? google_cloud_run_service.game[0].status[0].url : null
      user      = length(google_cloud_run_service.user) > 0 ? google_cloud_run_service.user[0].status[0].url : null
      analytics = length(google_cloud_run_service.analytics) > 0 ? google_cloud_run_service.analytics[0].status[0].url : null
      frontend  = length(google_cloud_run_service.frontend) > 0 ? google_cloud_run_service.frontend[0].status[0].url : null
    } : null
    
    gke_cluster = var.enable_gke ? google_container_cluster.primary[0].name : null
    load_balancer_ip = var.deployment_method == "cloud-run" && length(google_compute_global_address.lb_ip) > 0 ? google_compute_global_address.lb_ip[0].address : null
  }
}

# ============================================
# Console URLs
# ============================================

output "console_urls" {
  description = "GCP Console URLs for quick access"
  value = {
    cloud_run       = "https://console.cloud.google.com/run?project=${var.gcp_project_id}"
    gke            = var.enable_gke ? "https://console.cloud.google.com/kubernetes/list?project=${var.gcp_project_id}" : null
    cloud_build    = "https://console.cloud.google.com/cloud-build/builds?project=${var.gcp_project_id}"
    cloud_storage  = "https://console.cloud.google.com/storage/browser?project=${var.gcp_project_id}"
    bigquery       = var.enable_bigquery ? "https://console.cloud.google.com/bigquery?project=${var.gcp_project_id}" : null
    dataproc       = var.enable_dataproc ? "https://console.cloud.google.com/dataproc?project=${var.gcp_project_id}" : null
    monitoring     = "https://console.cloud.google.com/monitoring?project=${var.gcp_project_id}"
    logging        = "https://console.cloud.google.com/logs/query?project=${var.gcp_project_id}"
    iam            = "https://console.cloud.google.com/iam-admin/iam?project=${var.gcp_project_id}"
    secrets        = "https://console.cloud.google.com/security/secret-manager?project=${var.gcp_project_id}"
  }
}

# ============================================
# CLI Commands
# ============================================

output "useful_commands" {
  description = "Useful CLI commands"
  value = {
    deploy_manually = "gcloud builds submit --config=cloudbuild.yaml --project=${var.gcp_project_id}"
    
    view_logs = "gcloud run services logs read ${var.project_name}-gateway --region=${var.gcp_region} --project=${var.gcp_project_id}"
    
    connect_to_gke = var.enable_gke ? "gcloud container clusters get-credentials ${google_container_cluster.primary[0].name} --region=${var.gcp_region} --project=${var.gcp_project_id}" : null
    
    view_secrets = "gcloud secrets list --project=${var.gcp_project_id}"
    
    query_bigquery = var.enable_bigquery ? "bq query --project_id=${var.gcp_project_id} --use_legacy_sql=false 'SELECT * FROM `${var.gcp_project_id}.${google_bigquery_dataset.analytics[0].dataset_id}.user_events` LIMIT 10'" : null
  }
}

# ============================================
# Summary Information
# ============================================

output "deployment_summary" {
  description = "Deployment summary"
  value = {
    project_name      = var.project_name
    deployment_method = var.deployment_method
    
    benchmarks_enabled = {
      "1_iam"        = true
      "2_monitoring" = var.enable_cloud_monitoring
      "3_networking" = true
      "4_compute"    = var.enable_jenkins_vm
      "5_storage"    = true
      "6_database"   = var.enable_cloud_sql ? "Cloud SQL" : "MongoDB Atlas"
      "7_bigquery"   = var.enable_bigquery
      "8_dataproc"   = var.enable_dataproc
    }
    
    services_deployed = var.deployment_method == "cloud-run" ? [
      "gateway",
      "auth-service",
      "quiz-service",
      "game-service",
      "user-service",
      "analytics-service",
      "frontend"
    ] : []
    
    cost_estimate = "~$50-150/month (varies with usage)"
  }
}

# ============================================
# Next Steps
# ============================================

output "next_steps" {
  description = "Next steps after deployment"
  value = <<-EOT
    
    🎉 DEPLOYMENT SUCCESSFUL!
    
    📋 NEXT STEPS:
    
    1. Access your application:
       ${var.deployment_method == "cloud-run" && length(google_cloud_run_service.frontend) > 0 ? google_cloud_run_service.frontend[0].status[0].url : "Deploy services first"}
    
    2. View logs:
       gcloud run services logs read ${var.project_name}-gateway --region=${var.gcp_region} --project=${var.gcp_project_id}
    
    3. Monitor your application:
       https://console.cloud.google.com/monitoring?project=${var.gcp_project_id}
    
    4. View BigQuery analytics:
       ${var.enable_bigquery ? "https://console.cloud.google.com/bigquery?project=${var.gcp_project_id}&p=${var.gcp_project_id}&d=${google_bigquery_dataset.analytics[0].dataset_id}&page=dataset" : "BigQuery not enabled"}
    
    5. Set up custom domain (optional):
       https://cloud.google.com/run/docs/mapping-custom-domains
    
    6. Enable SSL certificate (optional):
       https://cloud.google.com/load-balancing/docs/ssl-certificates
    
    7. Configure CI/CD:
       - Push code to GitHub
       - Cloud Build will automatically deploy
       - View builds: https://console.cloud.google.com/cloud-build/builds?project=${var.gcp_project_id}
    
    📚 DOCUMENTATION:
    - GCP Documentation: https://cloud.google.com/docs
    - Cloud Run: https://cloud.google.com/run/docs
    - GKE: https://cloud.google.com/kubernetes-engine/docs
    - BigQuery: https://cloud.google.com/bigquery/docs
    
    💡 TIPS:
    - Monitor your costs: https://console.cloud.google.com/billing
    - Set up budget alerts to avoid surprises
    - Use Cloud Monitoring dashboards for real-time insights
    - Enable Cloud Armor for DDoS protection
  EOT
}
