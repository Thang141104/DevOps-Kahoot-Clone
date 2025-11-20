# 🚀 GCP Deployment Guide - Kahoot Clone
## Migrating from AWS to Google Cloud Platform

This guide will help you deploy the Kahoot Clone application to Google Cloud Platform (GCP) using all 8 CIS Benchmarks.

---

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Architecture Overview](#architecture-overview)
3. [8 GCP Benchmarks Implemented](#8-gcp-benchmarks-implemented)
4. [Initial Setup](#initial-setup)
5. [Deployment Steps](#deployment-steps)
6. [Post-Deployment Configuration](#post-deployment-configuration)
7. [Monitoring & Maintenance](#monitoring--maintenance)
8. [Cost Optimization](#cost-optimization)
9. [Troubleshooting](#troubleshooting)

---

## ✅ Prerequisites

### Required Tools

```bash
# Install gcloud CLI
Windows: https://cloud.google.com/sdk/docs/install
Mac: brew install google-cloud-sdk
Linux: curl https://sdk.cloud.google.com | bash

# Install Terraform
Windows: choco install terraform
Mac: brew install terraform
Linux: https://www.terraform.io/downloads

# Install kubectl (if using GKE)
gcloud components install kubectl

# Verify installations
gcloud --version
terraform --version
kubectl version --client
```

### GCP Account Setup

1. **Create GCP Project**
   ```bash
   gcloud projects create YOUR-PROJECT-ID --name="Kahoot Clone"
   gcloud config set project YOUR-PROJECT-ID
   ```

2. **Enable Billing**
   - Go to: https://console.cloud.google.com/billing
   - Link billing account to your project

3. **Enable Required APIs**
   ```bash
   gcloud services enable \
     compute.googleapis.com \
     container.googleapis.com \
     run.googleapis.com \
     cloudbuild.googleapis.com \
     secretmanager.googleapis.com \
     storage.googleapis.com \
     bigquery.googleapis.com \
     dataproc.googleapis.com \
     logging.googleapis.com \
     monitoring.googleapis.com \
     cloudtrace.googleapis.com \
     servicenetworking.googleapis.com \
     sqladmin.googleapis.com \
     artifactregistry.googleapis.com
   ```

4. **Set up Authentication**
   ```bash
   gcloud auth login
   gcloud auth application-default login
   ```

---

## 🏗️ Architecture Overview

### Deployment Options

#### Option 1: Cloud Run (Recommended) ⭐
- **Pros**: Serverless, auto-scaling, pay-per-use, easiest to manage
- **Cons**: Limited control, cold starts
- **Cost**: ~$20-50/month
- **Best for**: Most use cases, production-ready

#### Option 2: GKE (Kubernetes)
- **Pros**: Full control, portable, advanced features
- **Cons**: More complex, higher cost
- **Cost**: ~$100-200/month
- **Best for**: Large-scale, complex workloads

#### Option 3: Hybrid
- **Pros**: Flexibility, optimize per service
- **Cons**: Most complex setup
- **Cost**: Variable
- **Best for**: Specific requirements per service

### Services Architecture

```
┌─────────────────────────────────────────────────────────┐
│                  Google Cloud Platform                  │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │  Cloud Build (CI/CD)                           │   │
│  │  ✓ Replaces Jenkins                            │   │
│  │  ✓ GitHub integration                          │   │
│  │  ✓ Automatic deployments                       │   │
│  └─────────────────────────────────────────────────┘   │
│                         ↓                               │
│  ┌─────────────────────────────────────────────────┐   │
│  │  Cloud Run / GKE (Compute)                     │   │
│  │  ├─ Gateway Service (3000)                     │   │
│  │  ├─ Auth Service (3001)                        │   │
│  │  ├─ Quiz Service (3002)                        │   │
│  │  ├─ Game Service (3003) - Socket.io           │   │
│  │  ├─ User Service (3004)                        │   │
│  │  ├─ Analytics Service (3005)                   │   │
│  │  └─ Frontend (3006)                            │   │
│  └─────────────────────────────────────────────────┘   │
│                         ↓                               │
│  ┌─────────────────┬─────────────────┬─────────────┐   │
│  │ Cloud Storage   │ MongoDB Atlas   │ BigQuery    │   │
│  │ • Quiz media    │ • App data      │ • Analytics │   │
│  │ • User avatars  │ • Game sessions │ • Logs      │   │
│  │ • Backups       │ • User profiles │ • Reports   │   │
│  └─────────────────┴─────────────────┴─────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │  Cloud Monitoring & Logging                    │   │
│  │  ✓ Real-time metrics                           │   │
│  │  ✓ Alerts & notifications                      │   │
│  │  ✓ Log analytics                               │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## 🎯 8 GCP Benchmarks Implemented

### 1️⃣ Identity and Access Management (IAM)

**Implementation:**
- ✅ Service Accounts for each component
- ✅ Workload Identity (GKE)
- ✅ Secret Manager for sensitive data
- ✅ Least privilege principle
- ✅ IAM roles and bindings

**Files:** `terraform/gcp-iam.tf`

**Key Features:**
- Cloud Run Service Account
- Cloud Build Service Account
- Analytics Service Account
- GKE Service Account (if using Kubernetes)
- Automated secret rotation

---

### 2️⃣ Logging and Monitoring

**Implementation:**
- ✅ Cloud Logging for all services
- ✅ Cloud Monitoring dashboards
- ✅ Alert policies (CPU, Memory, Errors)
- ✅ Uptime checks
- ✅ Log sinks to BigQuery

**Files:** `terraform/gcp-monitoring.tf`

**Key Features:**
- Application logs → BigQuery
- Error logs → Cloud Storage
- Real-time monitoring dashboard
- Email/SMS alerts
- 30-day log retention

---

### 3️⃣ Networking

**Implementation:**
- ✅ VPC Network (10.0.0.0/16)
- ✅ Cloud NAT for outbound traffic
- ✅ Cloud Load Balancer
- ✅ Firewall rules
- ✅ VPC Connector (Cloud Run ↔ VPC)
- ✅ Private Google Access

**Files:** `terraform/gcp-networking.tf`

**Key Features:**
- Isolated VPC network
- Private IP for services
- Cloud Armor (DDoS protection)
- SSL/TLS termination
- Global load balancing

---

### 4️⃣ Virtual Machines (Compute Engine)

**Implementation:**
- ✅ Optional Jenkins VM
- ✅ Managed Instance Groups
- ✅ Auto-scaling
- ✅ Health checks
- ✅ Preemptible instances for cost savings

**Files:** `terraform/gcp-compute.tf`

**Key Features:**
- Ubuntu 22.04 LTS
- Automatic OS patches
- Custom startup scripts
- SSH via IAP (no public SSH)
- Instance templates

**Note:** Jenkins VM is **optional** - Cloud Build is recommended instead.

---

### 5️⃣ Storage (Cloud Storage)

**Implementation:**
- ✅ Quiz Media Bucket (public read)
- ✅ User Avatars Bucket (public read)
- ✅ Backups Bucket (private)
- ✅ Logs Bucket (private)
- ✅ Build Artifacts Bucket
- ✅ Lifecycle policies
- ✅ Versioning enabled

**Files:** `terraform/gcp-storage.tf`

**Key Features:**
- CORS configuration
- Pub/Sub notifications
- Automatic archival (Nearline/Coldline)
- 90-day retention for media
- 365-day retention for backups

---

### 6️⃣ Database Services (Cloud SQL)

**Implementation:**
- ✅ Cloud SQL PostgreSQL 15 (optional)
- ✅ MongoDB Atlas integration
- ✅ Private IP only
- ✅ Automated backups (7 days)
- ✅ Point-in-time recovery
- ✅ High availability (Regional)
- ✅ SSL connections

**Files:** `terraform/gcp-database.tf`

**Key Features:**
- Daily backups at 3 AM
- 7-day backup retention
- VPC peering for private access
- Cloud SQL Proxy support
- Monitoring & alerts

**Recommendation:** Use **MongoDB Atlas** (Cloud) instead of Cloud SQL for MongoDB compatibility.

---

### 7️⃣ BigQuery

**Implementation:**
- ✅ Analytics dataset
- ✅ Partitioned tables (by date)
- ✅ Clustered columns for performance
- ✅ Pre-built views (DAU, Popular Quizzes)
- ✅ Scheduled queries (daily aggregation)
- ✅ Log sink integration

**Files:** `terraform/gcp-bigquery.tf`

**Key Features:**
- `user_events` table (user activity)
- `game_sessions` table (game data)
- `quiz_statistics` table (quiz metrics)
- `application_logs` table (from Cloud Logging)
- Daily active users view
- Popular quizzes view

**Sample Query:**
```sql
SELECT 
  DATE(event_timestamp) as date,
  COUNT(DISTINCT user_id) as active_users
FROM `your-project.kahoot_clone_analytics.user_events`
WHERE event_timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
GROUP BY date
ORDER BY date DESC;
```

---

### 8️⃣ Dataproc

**Implementation:**
- ✅ Dataproc cluster (Spark/Hadoop)
- ✅ PySpark analytics jobs
- ✅ Scheduled ETL workflows
- ✅ Integration with BigQuery
- ✅ Auto-delete idle clusters (cost saving)

**Files:** `terraform/gcp-dataproc.tf`

**Key Features:**
- Spark 3.x on Debian 11
- Jupyter & Zeppelin notebooks
- Preemptible workers (50% cost reduction)
- Automated ETL pipeline
- Daily analytics at 2 AM

**Use Cases:**
- Large-scale data processing
- Machine learning on game data
- Batch analytics aggregation
- Data transformations

**Sample PySpark Job:**
```python
# Aggregate quiz popularity metrics
spark.read.format("bigquery") \
  .option("table", "quiz_analytics.game_sessions") \
  .load() \
  .groupBy("quiz_id") \
  .agg(count("*").alias("total_games")) \
  .write.format("bigquery") \
  .option("table", "quiz_analytics.popularity") \
  .save()
```

---

## 🛠️ Initial Setup

### 1. Clone Repository

```bash
git clone https://github.com/Thang141104/DevOps-Kahoot-Clone.git
cd DevOps-Kahoot-Clone
```

### 2. Configure MongoDB Atlas (Recommended)

1. Go to: https://www.mongodb.com/cloud/atlas
2. Create a free cluster
3. Get connection string:
   ```
   mongodb+srv://username:password@cluster.mongodb.net/quiz-app?retryWrites=true&w=majority
   ```

### 3. Configure Terraform Variables

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:

```hcl
gcp_project_id = "your-project-id-here"
gcp_region     = "us-central1"
environment    = "production"

deployment_method = "cloud-run"  # or "gke"

mongodb_uri = "mongodb+srv://user:pass@cluster.mongodb.net/quiz-app"
jwt_secret  = "generate-a-secure-random-string"

email_user     = "your-email@gmail.com"
email_password = "your-app-password"

enable_bigquery       = true
enable_dataproc       = false  # Set true if needed
enable_cloud_sql      = false  # Use MongoDB Atlas instead
enable_cloud_monitoring = true
```

### 4. Initialize Terraform

```bash
terraform init
terraform plan  # Review changes
```

---

## 🚀 Deployment Steps

### Method 1: Using Terraform (Infrastructure)

```bash
cd terraform

# Preview changes
terraform plan -out=tfplan

# Apply infrastructure
terraform apply tfplan

# Get outputs
terraform output
```

**This creates:**
- VPC Network
- Service Accounts
- Cloud Storage Buckets
- BigQuery Dataset
- Secret Manager Secrets
- IAM Bindings
- Monitoring & Logging
- (Optional) Dataproc Cluster
- (Optional) GKE Cluster

### Method 2: Using Cloud Build (Application)

**Option A: Automatic (GitHub Push)**

1. Connect GitHub to Cloud Build:
   ```bash
   gcloud builds connections create github \
     --region=us-central1 \
     --name=github-connection
   ```

2. Push code to GitHub:
   ```bash
   git add .
   git commit -m "Deploy to GCP"
   git push origin main
   ```

3. Cloud Build automatically deploys! ✨

**Option B: Manual Deployment**

```bash
# Submit build manually
gcloud builds submit --config=cloudbuild.yaml \
  --project=YOUR-PROJECT-ID \
  --region=us-central1

# Or use substitutions
gcloud builds submit --config=cloudbuild.yaml \
  --substitutions=_REGION=us-central1,_PROJECT_NAME=kahoot-clone
```

### Method 3: Using Cloud Run CLI (Quick Deploy)

```bash
# Set variables
export PROJECT_ID="your-project-id"
export REGION="us-central1"

# Build and deploy Gateway
gcloud builds submit --tag gcr.io/$PROJECT_ID/kahoot-clone-gateway ./gateway
gcloud run deploy kahoot-clone-gateway \
  --image gcr.io/$PROJECT_ID/kahoot-clone-gateway \
  --region $REGION \
  --platform managed \
  --allow-unauthenticated

# Repeat for other services...
```

---

## ⚙️ Post-Deployment Configuration

### 1. Update Frontend Environment

Get Gateway URL:
```bash
GATEWAY_URL=$(gcloud run services describe kahoot-clone-gateway --region=us-central1 --format='value(status.url)')
echo "Gateway URL: $GATEWAY_URL"
```

Update frontend environment and redeploy.

### 2. Set Up Custom Domain (Optional)

```bash
# Map domain to Cloud Run
gcloud run domain-mappings create \
  --service=kahoot-clone-frontend \
  --domain=yourdomain.com \
  --region=us-central1
```

### 3. Enable SSL Certificate

```bash
# Create managed SSL certificate
gcloud compute ssl-certificates create kahoot-ssl \
  --domains=yourdomain.com \
  --global
```

### 4. Configure CORS

Already configured in `gcp-storage.tf` for Cloud Storage buckets.

### 5. Seed Initial Data (Optional)

```bash
# Connect to MongoDB Atlas
mongosh "mongodb+srv://cluster.mongodb.net/quiz-app" --username youruser

# Or use seed script
cd services/user-service
node seed.js
```

---

## 📊 Monitoring & Maintenance

### View Logs

```bash
# Cloud Run logs
gcloud run services logs read kahoot-clone-gateway --region=us-central1

# All logs
gcloud logging read "resource.type=cloud_run_revision" --limit=50

# Error logs only
gcloud logging read "severity>=ERROR" --limit=20
```

### Monitor Services

```bash
# Check service status
gcloud run services list --region=us-central1

# View metrics
gcloud monitoring dashboards list
```

### Access Monitoring Dashboard

```bash
# Get dashboard URL
terraform output monitoring_dashboard_url

# Or visit directly
open "https://console.cloud.google.com/monitoring?project=YOUR-PROJECT-ID"
```

### BigQuery Analytics

```sql
-- Daily Active Users
SELECT * FROM `your-project.kahoot_clone_analytics.daily_active_users`
ORDER BY date DESC
LIMIT 30;

-- Popular Quizzes
SELECT * FROM `your-project.kahoot_clone_analytics.popular_quizzes`
LIMIT 10;

-- Error Analysis
SELECT 
  severity,
  COUNT(*) as error_count,
  text_payload
FROM `your-project.kahoot_clone_analytics.application_logs`
WHERE severity = 'ERROR'
  AND timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 24 HOUR)
GROUP BY severity, text_payload
ORDER BY error_count DESC;
```

---

## 💰 Cost Optimization

### Estimated Costs

| Service | Configuration | Monthly Cost |
|---------|--------------|--------------|
| **Cloud Run** | 7 services, low traffic | $10-30 |
| **Cloud Storage** | 10GB storage | $0.20 |
| **BigQuery** | 10GB data, queries | $2-5 |
| **Cloud Logging** | 10GB logs | $5 |
| **Cloud Monitoring** | Basic metrics | Free |
| **MongoDB Atlas** | M0 cluster | Free |
| **Cloud NAT** | 1 gateway | $40 |
| **Load Balancer** | If used | $20 |
| **Dataproc** | If enabled | $100+ |
| **TOTAL** | Cloud Run setup | **$50-100** |
| **TOTAL** | GKE setup | **$150-300** |

### Cost-Saving Tips

1. **Use Cloud Run** instead of GKE (saves $100+/month)
2. **Scale to zero** when not in use:
   ```hcl
   cloud_run_min_instances = 0
   ```
3. **Use MongoDB Atlas Free Tier** instead of Cloud SQL
4. **Set BigQuery partitions** to expire:
   ```hcl
   default_table_expiration_ms = 7776000000  # 90 days
   ```
5. **Enable Dataproc only when needed** (auto-delete idle clusters)
6. **Use preemptible instances** for non-critical workloads
7. **Set up budget alerts**:
   ```bash
   gcloud billing budgets create \
     --billing-account=BILLING_ACCOUNT_ID \
     --display-name="Monthly Budget" \
     --budget-amount=100USD
   ```

---

## 🐛 Troubleshooting

### Common Issues

#### 1. Terraform Apply Fails

**Error:** `Error 403: Cloud Run API not enabled`

**Solution:**
```bash
gcloud services enable run.googleapis.com
terraform apply -target=google_project_service.run
terraform apply
```

#### 2. Cloud Build Permission Denied

**Error:** `Error: googleapi: Error 403: Permission denied`

**Solution:**
```bash
# Grant Cloud Build service account permissions
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member=serviceAccount:$PROJECT_NUMBER@cloudbuild.gserviceaccount.com \
  --role=roles/run.admin
```

#### 3. Cloud Run Service Not Starting

**Error:** Container fails health check

**Solution:**
```bash
# Check logs
gcloud run services logs read SERVICE_NAME --region=us-central1 --limit=50

# Common fixes:
# - Ensure PORT env variable is set correctly
# - Check MongoDB connection string
# - Verify secrets are accessible
```

#### 4. MongoDB Connection Timeout

**Error:** `MongoServerSelectionError: connection timed out`

**Solution:**
1. Whitelist Cloud Run IPs in MongoDB Atlas
2. Or use VPC Peering
3. Or enable VPC Connector

#### 5. Socket.io Connection Issues

**Error:** WebSocket connection failed

**Solution:**
```javascript
// Update game-service to use polling for Cloud Run
const io = socketIo(server, {
  cors: { origin: "*" },
  transports: ['polling', 'websocket'],  // Polling first
  upgradeTimeout: 30000
});
```

#### 6. BigQuery Access Denied

**Error:** `403 Access Denied: BigQuery BigQuery: Permission denied`

**Solution:**
```bash
# Grant service account BigQuery permissions
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member=serviceAccount:SERVICE_ACCOUNT_EMAIL \
  --role=roles/bigquery.dataEditor
```

### Get Help

- **GCP Support:** https://cloud.google.com/support
- **Community:** https://stackoverflow.com/questions/tagged/google-cloud-platform
- **Documentation:** https://cloud.google.com/docs

---

## 📚 Additional Resources

- **GCP Free Tier:** https://cloud.google.com/free
- **Cloud Run Docs:** https://cloud.google.com/run/docs
- **BigQuery Best Practices:** https://cloud.google.com/bigquery/docs/best-practices
- **Cost Optimization:** https://cloud.google.com/cost-management
- **Security Best Practices:** https://cloud.google.com/security/best-practices

---

## 🎉 Conclusion

Congratulations! You've successfully migrated your Kahoot Clone from AWS to GCP with all 8 CIS benchmarks implemented.

Your application now benefits from:
- ✅ Serverless architecture (Cloud Run)
- ✅ Automated CI/CD (Cloud Build)
- ✅ Comprehensive monitoring (Cloud Monitoring)
- ✅ Advanced analytics (BigQuery)
- ✅ Enterprise security (IAM, Secret Manager)
- ✅ Cost optimization (scale to zero, pay-per-use)
- ✅ High availability (global load balancing)
- ✅ Big data processing (Dataproc)

**Next:** Explore advanced features like Cloud CDN, Cloud Armor, and AI/ML integration!

---

**Made with ❤️ for Google Cloud Platform**
