#!/usr/bin/env pwsh
# ================================
# Security Audit - Check for Sensitive Data
# ================================

Write-Host "🔒 Security Audit - Checking for sensitive data in Git" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan

$sensitivePatterns = @{
    "AWS Account ID" = '\d{12}'
    "AWS Access Key" = 'AKIA[0-9A-Z]{16}'
    "AWS Secret Key" = '[A-Za-z0-9/+=]{40}'
    "MongoDB URI" = 'mongodb(\+srv)?://[^@]+@[^/]+'
    "JWT Secret" = 'jwt[_-]?secret["\s:=]+[A-Za-z0-9+/=]{32,}'
    "Email Password" = 'email[_-]?password["\s:=]+\S+'
    "Private Key" = '-----BEGIN (RSA|EC|OPENSSH) PRIVATE KEY-----'
}

$sensitiveFiles = @(
    "*.tfvars",
    "*.pem",
    "*.key",
    ".env",
    "*secrets*.yaml",
    "credentials",
    "ecr-config.json",
    ".deployment-info.json"
)

# Get staged files
$stagedFiles = git diff --cached --name-only 2>$null
if (-not $stagedFiles) {
    $stagedFiles = git status --short | Where-Object { $_ -match '^\?\?' -or $_ -match '^[AM]' } | ForEach-Object { $_.Substring(3) }
}

$issues = @()
$warnings = @()

Write-Host "📋 Checking staged/untracked files..." -ForegroundColor Yellow

foreach ($file in $stagedFiles) {
    $file = $file.Trim()
    if (-not (Test-Path $file)) { continue }
    if (Test-Path $file -PathType Container) { continue }
    
    # Check if file matches sensitive patterns
    $isSensitive = $false
    foreach ($pattern in $sensitiveFiles) {
        if ($file -like $pattern) {
            $issues += "❌ SENSITIVE FILE: $file (matches pattern: $pattern)"
            $isSensitive = $true
            break
        }
    }
    
    if ($isSensitive) { continue }
    
    # Check file content
    try {
        $content = Get-Content $file -Raw -ErrorAction SilentlyContinue
        if (-not $content) { continue }
        
        foreach ($name in $sensitivePatterns.Keys) {
            $pattern = $sensitivePatterns[$name]
            if ($content -match $pattern) {
                $matches = [regex]::Matches($content, $pattern)
                foreach ($match in $matches) {
                    $preview = $match.Value
                    if ($preview.Length -gt 50) {
                        $preview = $preview.Substring(0, 47) + "..."
                    }
                    $warnings += "⚠️  $file : $name detected - '$preview'"
                }
            }
        }
        
        # Check for hardcoded credentials
        if ($content -match '(password|secret|key|token)\s*[:=]\s*["'']?[a-zA-Z0-9]{8,}') {
            $warnings += "⚠️  $file : Possible hardcoded credentials detected"
        }
        
    } catch {
        # Skip binary files
    }
}

Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "🔍 Audit Results:`n" -ForegroundColor Cyan

if ($issues.Count -eq 0 -and $warnings.Count -eq 0) {
    Write-Host "✅ No sensitive data detected in staged files" -ForegroundColor Green
    Write-Host "   Safe to commit!" -ForegroundColor Green
    exit 0
}

if ($issues.Count -gt 0) {
    Write-Host "🚨 CRITICAL ISSUES (DO NOT COMMIT):" -ForegroundColor Red
    foreach ($issue in $issues) {
        Write-Host "   $issue" -ForegroundColor Red
    }
    Write-Host ""
}

if ($warnings.Count -gt 0) {
    Write-Host "⚠️  WARNINGS (Review before commit):" -ForegroundColor Yellow
    foreach ($warning in $warnings) {
        Write-Host "   $warning" -ForegroundColor Yellow
    }
    Write-Host ""
}

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "`n📋 Recommendations:" -ForegroundColor Cyan

if ($issues.Count -gt 0) {
    Write-Host "   1. DO NOT COMMIT these files!" -ForegroundColor Red
    Write-Host "   2. Add them to .gitignore" -ForegroundColor White
    Write-Host "   3. Run: git reset HEAD <file>" -ForegroundColor Gray
    Write-Host "   4. Verify: git status" -ForegroundColor Gray
}

if ($warnings.Count -gt 0) {
    Write-Host "   1. Review detected patterns" -ForegroundColor Yellow
    Write-Host "   2. Use environment variables instead of hardcoding" -ForegroundColor White
    Write-Host "   3. Use K8s secrets for sensitive data" -ForegroundColor White
    Write-Host "   4. Create .env.example without real values" -ForegroundColor White
}

Write-Host "`n🔐 Best Practices:" -ForegroundColor Cyan
Write-Host "   ✅ Use .env files (ignored by git)" -ForegroundColor White
Write-Host "   ✅ Use K8s secrets for production" -ForegroundColor White
Write-Host "   ✅ Use AWS Secrets Manager / Parameter Store" -ForegroundColor White
Write-Host "   ✅ Never commit .tfvars, .pem, or credential files" -ForegroundColor White
Write-Host "   ✅ Use .env.example with placeholder values" -ForegroundColor White

if ($issues.Count -gt 0) {
    Write-Host "`n❌ COMMIT BLOCKED - Fix issues above first!" -ForegroundColor Red
    exit 1
} else {
    Write-Host "`n⚠️  Review warnings, then proceed with caution." -ForegroundColor Yellow
    exit 0
}
