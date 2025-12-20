#!/usr/bin/env pwsh
# ================================
# Infrastructure Health Check
# ================================

param(
    [switch]$Detailed
)

Write-Host "🔍 Infrastructure Health Check" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan

cd terraform

# Get terraform outputs
Write-Host "📋 Fetching infrastructure info..." -ForegroundColor Yellow
$outputs = terraform output -json | ConvertFrom-Json

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to get terraform outputs. Run 'terraform apply' first." -ForegroundColor Red
    exit 1
}

# Extract values
$jenkinsIp = $outputs.jenkins_public_ip.value
$jenkinsUrl = $outputs.jenkins_url.value
$k8sMasterIp = $outputs.k8s_master_public_ip.value
$frontendUrl = $outputs.application_urls.value.frontend
$gatewayUrl = $outputs.application_urls.value.gateway
$prometheusUrl = $outputs.application_urls.value.prometheus
$grafanaUrl = $outputs.application_urls.value.grafana
$ecrRegistry = $outputs.ecr_registry_url.value

Write-Host "`n📊 Infrastructure Status:`n" -ForegroundColor Cyan

# Function to check URL
function Test-ServiceUrl {
    param(
        [string]$Name,
        [string]$Url,
        [int]$Timeout = 5
    )
    
    Write-Host "  🔗 $Name" -NoNewline -ForegroundColor White
    Write-Host " - $Url" -ForegroundColor Gray
    
    try {
        $response = Invoke-WebRequest -Uri $Url -TimeoutSec $Timeout -UseBasicParsing -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            Write-Host "     ✅ ONLINE" -ForegroundColor Green
            return $true
        } else {
            Write-Host "     ⚠️  HTTP $($response.StatusCode)" -ForegroundColor Yellow
            return $false
        }
    } catch {
        Write-Host "     ❌ OFFLINE" -ForegroundColor Red
        if ($Detailed) {
            Write-Host "     Error: $($_.Exception.Message)" -ForegroundColor Gray
        }
        return $false
    }
}

# Function to check SSH
function Test-SSHConnection {
    param(
        [string]$Name,
        [string]$Ip
    )
    
    Write-Host "  🔌 $Name SSH" -NoNewline -ForegroundColor White
    Write-Host " - $Ip:22" -ForegroundColor Gray
    
    $tcpClient = New-Object System.Net.Sockets.TcpClient
    try {
        $tcpClient.Connect($Ip, 22)
        if ($tcpClient.Connected) {
            Write-Host "     ✅ REACHABLE" -ForegroundColor Green
            $tcpClient.Close()
            return $true
        }
    } catch {
        Write-Host "     ❌ UNREACHABLE" -ForegroundColor Red
        return $false
    } finally {
        $tcpClient.Dispose()
    }
}

# Check Jenkins
Write-Host "🏗️  Jenkins Server:" -ForegroundColor Cyan
Test-SSHConnection -Name "Jenkins" -Ip $jenkinsIp
Test-ServiceUrl -Name "Jenkins Web UI" -Url $jenkinsUrl
Write-Host ""

# Check K8s Master
Write-Host "☸️  Kubernetes Cluster:" -ForegroundColor Cyan
Test-SSHConnection -Name "K8s Master" -Ip $k8sMasterIp
Write-Host ""

# Check Applications
Write-Host "🚀 Applications:" -ForegroundColor Cyan
$frontendStatus = Test-ServiceUrl -Name "Frontend" -Url $frontendUrl
$gatewayStatus = Test-ServiceUrl -Name "API Gateway" -Url $gatewayUrl
Write-Host ""

# Check Monitoring
Write-Host "📊 Monitoring Stack:" -ForegroundColor Cyan
$prometheusStatus = Test-ServiceUrl -Name "Prometheus" -Url $prometheusUrl
$grafanaStatus = Test-ServiceUrl -Name "Grafana" -Url $grafanaUrl
Write-Host ""

# Check ECR
Write-Host "📦 Container Registry:" -ForegroundColor Cyan
Write-Host "  🗄️  ECR Registry" -NoNewline -ForegroundColor White
Write-Host " - $ecrRegistry" -ForegroundColor Gray

try {
    $repos = aws ecr describe-repositories --query 'repositories[].repositoryName' --output json | ConvertFrom-Json
    if ($repos.Count -gt 0) {
        Write-Host "     ✅ $($repos.Count) repositories" -ForegroundColor Green
        
        if ($Detailed) {
            foreach ($repo in $repos) {
                $images = aws ecr list-images --repository-name $repo --query 'imageIds | length(@)' --output text
                Write-Host "        - $repo : $images images" -ForegroundColor Gray
            }
        }
    } else {
        Write-Host "     ⚠️  No repositories" -ForegroundColor Yellow
    }
} catch {
    Write-Host "     ❌ Cannot access ECR" -ForegroundColor Red
}

Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

# Summary
Write-Host "`n📋 Summary:" -ForegroundColor Cyan

$totalChecks = 6
$passedChecks = 0
if ($frontendStatus) { $passedChecks++ }
if ($gatewayStatus) { $passedChecks++ }
if ($prometheusStatus) { $passedChecks++ }
if ($grafanaStatus) { $passedChecks++ }

$healthPercentage = [math]::Round(($passedChecks / 4) * 100)

Write-Host "   Health: " -NoNewline
if ($healthPercentage -ge 75) {
    Write-Host "$healthPercentage% " -NoNewline -ForegroundColor Green
    Write-Host "✅ HEALTHY" -ForegroundColor Green
} elseif ($healthPercentage -ge 50) {
    Write-Host "$healthPercentage% " -NoNewline -ForegroundColor Yellow
    Write-Host "⚠️  DEGRADED" -ForegroundColor Yellow
} else {
    Write-Host "$healthPercentage% " -NoNewline -ForegroundColor Red
    Write-Host "❌ UNHEALTHY" -ForegroundColor Red
}

Write-Host "`n🔗 Quick Links:" -ForegroundColor Cyan
Write-Host "   Jenkins:    $jenkinsUrl" -ForegroundColor White
Write-Host "   Frontend:   $frontendUrl" -ForegroundColor White
Write-Host "   Gateway:    $gatewayUrl" -ForegroundColor White
Write-Host "   Prometheus: $prometheusUrl" -ForegroundColor White
Write-Host "   Grafana:    $grafanaUrl" -ForegroundColor White

Write-Host "`n📝 SSH Commands:" -ForegroundColor Cyan
Write-Host "   Jenkins: ssh -i ~/.ssh/kahoot-key.pem ubuntu@$jenkinsIp" -ForegroundColor Gray
Write-Host "   K8s:     ssh -i ~/.ssh/kahoot-key.pem ubuntu@$k8sMasterIp" -ForegroundColor Gray

if ($Detailed) {
    Write-Host "`n🔍 Run with -Detailed flag for more information" -ForegroundColor Gray
}

cd ..
