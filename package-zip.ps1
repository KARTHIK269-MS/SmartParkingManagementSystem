# ==========================================================
# Package Clean Academic Submission ZIP
# ==========================================================

$ErrorActionPreference = "Stop"

$projectDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$zipFile = "$projectDir\smart-parking-system-clean-submission.zip"
$stageDir = "$projectDir\stage-clean-submission"

Write-Host "Creating clean submission ZIP: $zipFile..." -ForegroundColor Cyan

# Remove old artifacts if present
if (Test-Path $zipFile) {
    Remove-Item $zipFile -Force
}
if (Test-Path $stageDir) {
    Remove-Item $stageDir -Recurse -Force
}

New-Item -ItemType Directory -Path $stageDir | Out-Null

# Exclude list for top-level
$excludeList = @(
    "backup-before-improvements",
    "backup-before-final-qa",
    "db.properties",
    "target",
    "build",
    ".git",
    ".settings",
    "smart-parking-system-clean-submission.zip",
    "stage-clean-submission"
)

# Copy included items to stage
$items = Get-ChildItem -Path $projectDir | Where-Object {
    $name = $_.Name
    $excludeList -notcontains $name -and -not ($name.EndsWith(".zip"))
}

foreach ($item in $items) {
    Copy-Item -Path $item.FullName -Destination "$stageDir\$($item.Name)" -Recurse -Force
}

# Clean any accidentally copied db.properties in stage (e.g. inside classes)
Get-ChildItem -Path $stageDir -Recurse -Filter "db.properties" | ForEach-Object {
    Remove-Item $_.FullName -Force
    Write-Host "Excluded private credential file: $($_.FullName)" -ForegroundColor Yellow
}

# Clean any pycache or temporary logs
Get-ChildItem -Path $stageDir -Recurse -Filter "__pycache__" | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
Get-ChildItem -Path $stageDir -Recurse -Filter "*.log" | Remove-Item -Force -ErrorAction SilentlyContinue

# Compress staged folder
Compress-Archive -Path "$stageDir\*" -DestinationPath $zipFile -Force

# Clean up stage directory
Remove-Item $stageDir -Recurse -Force

$zipItem = Get-Item $zipFile
Write-Host "[OK] Clean submission zip created successfully!" -ForegroundColor Green
Write-Host "  Path: $($zipItem.FullName)" -ForegroundColor Green
Write-Host "  Size: $([math]::Round($zipItem.Length / 1MB, 2)) MB" -ForegroundColor Green
