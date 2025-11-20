# Build all Docker images using Google Cloud Build
# This script builds and pushes all 7 microservices to Google Container Registry

$PROJECT_ID = "nt542-q11-ggcloud"
$SERVICES = @(
    @{Name="auth"; Path="./services/auth-service"},
    @{Name="quiz"; Path="./services/quiz-service"},
    @{Name="user"; Path="./services/user-service"},
    @{Name="game"; Path="./services/game-service"},
    @{Name="analytics"; Path="./services/analytics-service"},
    @{Name="gateway"; Path="./gateway"},
    @{Name="frontend"; Path="./frontend"}
)

Write-Host "`n========== BUILDING ALL DOCKER IMAGES ==========" -ForegroundColor Green
Write-Host "Project: $PROJECT_ID" -ForegroundColor Cyan
Write-Host "Total Services: $($SERVICES.Count)`n" -ForegroundColor Cyan

$successCount = 0
$failCount = 0
$startTime = Get-Date

foreach ($service in $SERVICES) {
    $serviceName = $service.Name
    $servicePath = $service.Path
    $imageTag = "gcr.io/$PROJECT_ID/kahoot-clone-$serviceName`:latest"
    
    Write-Host "[$($SERVICES.IndexOf($service) + 1)/$($SERVICES.Count)] Building $serviceName..." -ForegroundColor Yellow
    Write-Host "  Path: $servicePath" -ForegroundColor Gray
    Write-Host "  Image: $imageTag" -ForegroundColor Gray
    
    try {
        $output = gcloud builds submit --tag $imageTag $servicePath --project=$PROJECT_ID 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✅ SUCCESS: $serviceName built and pushed!" -ForegroundColor Green
            $successCount++
        } else {
            Write-Host "  ❌ FAILED: $serviceName build failed!" -ForegroundColor Red
            Write-Host "  Error: $output" -ForegroundColor Red
            $failCount++
        }
    } catch {
        Write-Host "  ❌ ERROR: $_" -ForegroundColor Red
        $failCount++
    }
    
    Write-Host ""
}

$endTime = Get-Date
$duration = $endTime - $startTime

Write-Host "`n========== BUILD SUMMARY ==========" -ForegroundColor Green
Write-Host "✅ Successful: $successCount" -ForegroundColor Green
Write-Host "❌ Failed: $failCount" -ForegroundColor Red
Write-Host "⏱️ Total Time: $($duration.ToString('mm\:ss'))" -ForegroundColor Cyan

if ($failCount -eq 0) {
    Write-Host "`n🎉 All images built successfully!" -ForegroundColor Green
    Write-Host "`nNext step: Run 'terraform apply' to deploy Cloud Run services" -ForegroundColor Cyan
} else {
    Write-Host "`n⚠️ Some builds failed. Please check errors above." -ForegroundColor Yellow
    exit 1
}
