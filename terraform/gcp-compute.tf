# ============================================
# BENCHMARK 4: Virtual Machines (Compute Engine)
# ============================================

# Enable Compute Engine API
resource "google_project_service" "compute_engine" {
  project = var.gcp_project_id
  service = "compute.googleapis.com"
  
  disable_on_destroy = false
}

# ============================================
# Compute Engine Instance for Jenkins (Optional)
# ============================================

resource "google_compute_instance" "jenkins" {
  count        = var.enable_jenkins_vm ? 1 : 0
  name         = "${var.project_name}-jenkins"
  project      = var.gcp_project_id
  zone         = var.gcp_zone
  machine_type = var.jenkins_machine_type

  tags = ["jenkins", "allow-ssh", "allow-lb", "allow-health-checks"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 50  # GB
      type  = "pd-standard"
    }
  }

  network_interface {
    network    = google_compute_network.vpc.id
    subnetwork = google_compute_subnetwork.subnet.id

    # Give Jenkins a public IP for easy access
    access_config {
      nat_ip = google_compute_address.jenkins_ip[0].address
    }
  }

  service_account {
    email  = google_service_account.jenkins_sa[0].email
    scopes = ["cloud-platform"]
  }

  metadata = {
    enable-oslogin = "TRUE"
  }

  # Startup script - Install Jenkins, Docker, kubectl
  metadata_startup_script = <<-EOF
    #!/bin/bash
    set -e
    
    # Update system
    apt-get update
    apt-get install -y apt-transport-https ca-certificates curl software-properties-common
    
    # Install Docker
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    usermod -aG docker ubuntu
    
    # Install Jenkins
    wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | apt-key add -
    sh -c 'echo deb https://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
    apt-get update
    apt-get install -y jenkins openjdk-11-jdk
    
    # Install kubectl
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    
    # Install gcloud SDK
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
    apt-get update && apt-get install -y google-cloud-sdk
    
    # Start Jenkins
    systemctl start jenkins
    systemctl enable jenkins
    
    echo "Jenkins installation complete. Access at: http://$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip -H 'Metadata-Flavor: Google'):8080"
  EOF

  allow_stopping_for_update = true

  labels = {
    environment = var.environment
    app         = "jenkins"
    managed_by  = "terraform"
  }

  lifecycle {
    ignore_changes = [
      metadata_startup_script,
    ]
  }
}

# Static IP for Jenkins
resource "google_compute_address" "jenkins_ip" {
  count   = var.enable_jenkins_vm ? 1 : 0
  name    = "${var.project_name}-jenkins-ip"
  project = var.gcp_project_id
  region  = var.gcp_region
}

# Firewall rule for Jenkins UI (port 8080)
resource "google_compute_firewall" "jenkins_ui" {
  count   = var.enable_jenkins_vm ? 1 : 0
  name    = "${var.project_name}-jenkins-ui"
  project = var.gcp_project_id
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["8080", "50000"]  # Jenkins UI and agent port
  }

  source_ranges = ["0.0.0.0/0"]  # CHANGE THIS to your IP for security
  target_tags   = ["jenkins"]
  description   = "Allow Jenkins UI access"
}

# ============================================
# Compute Engine Instance Template (for Auto-scaling)
# ============================================

resource "google_compute_instance_template" "app_template" {
  count        = var.deployment_method == "gke" ? 0 : 1  # Only if not using GKE/Cloud Run
  name_prefix  = "${var.project_name}-app-template-"
  project      = var.gcp_project_id
  machine_type = "e2-medium"
  region       = var.gcp_region

  tags = ["app-server", "allow-ssh", "allow-lb", "allow-health-checks"]

  disk {
    source_image = "ubuntu-os-cloud/ubuntu-2204-lts"
    auto_delete  = true
    boot         = true
    disk_size_gb = 20
    disk_type    = "pd-standard"
  }

  network_interface {
    network    = google_compute_network.vpc.id
    subnetwork = google_compute_subnetwork.subnet.id

    access_config {
      # Ephemeral public IP
    }
  }

  service_account {
    email  = google_service_account.cloud_run_sa.email
    scopes = ["cloud-platform"]
  }

  metadata = {
    enable-oslogin = "TRUE"
  }

  # Startup script for app instances
  metadata_startup_script = <<-EOF
    #!/bin/bash
    set -e
    
    # Update system
    apt-get update
    apt-get install -y docker.io git curl
    
    # Start Docker
    systemctl start docker
    systemctl enable docker
    
    # Clone repository
    cd /opt
    git clone ${var.github_repo}
    cd DevOps-Kahoot-Clone
    git checkout ${var.github_branch}
    
    # Run with docker-compose
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    
    # Set environment variables
    export MONGODB_URI="${var.mongodb_uri}"
    export JWT_SECRET="${var.jwt_secret}"
    
    # Start services
    docker-compose up -d
    
    echo "Application started successfully"
  EOF

  labels = {
    environment = var.environment
    app         = var.project_name
    managed_by  = "terraform"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================
# Managed Instance Group (Auto-scaling)
# ============================================

resource "google_compute_region_instance_group_manager" "app_mig" {
  count              = var.deployment_method == "gke" || var.deployment_method == "cloud-run" ? 0 : 1
  name               = "${var.project_name}-app-mig"
  project            = var.gcp_project_id
  region             = var.gcp_region
  base_instance_name = "${var.project_name}-app"

  version {
    instance_template = google_compute_instance_template.app_template[0].id
  }

  target_size = 2

  named_port {
    name = "http"
    port = 3000
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.app_health[0].id
    initial_delay_sec = 300
  }

  update_policy {
    type                         = "PROACTIVE"
    minimal_action               = "REPLACE"
    max_surge_fixed              = 3
    max_unavailable_fixed        = 0
    instance_redistribution_type = "PROACTIVE"
  }
}

# Health Check for MIG
resource "google_compute_health_check" "app_health" {
  count   = var.deployment_method == "gke" || var.deployment_method == "cloud-run" ? 0 : 1
  name    = "${var.project_name}-app-health"
  project = var.gcp_project_id

  timeout_sec         = 5
  check_interval_sec  = 10
  healthy_threshold   = 2
  unhealthy_threshold = 3

  http_health_check {
    port         = 3000
    request_path = "/health"
  }
}

# Auto-scaler
resource "google_compute_region_autoscaler" "app_autoscaler" {
  count   = var.deployment_method == "gke" || var.deployment_method == "cloud-run" ? 0 : 1
  name    = "${var.project_name}-app-autoscaler"
  project = var.gcp_project_id
  region  = var.gcp_region
  target  = google_compute_region_instance_group_manager.app_mig[0].id

  autoscaling_policy {
    min_replicas    = 2
    max_replicas    = 10
    cooldown_period = 60

    cpu_utilization {
      target = 0.7  # 70% CPU
    }

    metric {
      name   = "compute.googleapis.com/instance/network/received_bytes_count"
      target = 1000000  # 1MB/s
      type   = "GAUGE"
    }
  }
}

# ============================================
# Outputs
# ============================================

output "jenkins_public_ip" {
  description = "Jenkins VM public IP"
  value       = var.enable_jenkins_vm ? google_compute_address.jenkins_ip[0].address : "Jenkins VM not enabled"
}

output "jenkins_url" {
  description = "Jenkins URL"
  value       = var.enable_jenkins_vm ? "http://${google_compute_address.jenkins_ip[0].address}:8080" : "Jenkins VM not enabled"
}

output "instance_template_id" {
  description = "App instance template ID"
  value       = var.deployment_method == "gke" || var.deployment_method == "cloud-run" ? "Not using Compute Engine instances" : google_compute_instance_template.app_template[0].id
}
