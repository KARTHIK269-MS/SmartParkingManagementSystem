# ==========================================================
# Deploy to Apache Tomcat 9
# ==========================================================

$projectDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$warSource = "$projectDir\target\smart-parking-system.war"

# Locate Tomcat webapps directory
$possibleTomcatPaths = @(
    "$env:CATALINA_HOME\webapps",
    "C:\Program Files\apache-tomcat-9.0.117\webapps",
    "C:\apache-tomcat-9.0.117\webapps"
)

$tomcatWebapps = $null
foreach ($path in $possibleTomcatPaths) {
    if (Test-Path $path) {
        $tomcatWebapps = $path
        break
    }
}

if (-not $tomcatWebapps) {
    Write-Host "[ERROR] Could not find Tomcat webapps directory. Please set CATALINA_HOME environment variable." -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $warSource)) {
    Write-Host "WAR file not found. Running build.ps1 first..." -ForegroundColor Yellow
    & "$projectDir\build.ps1"
}

Write-Host "Deploying smart-parking-system.war to Tomcat 9 webapps: $tomcatWebapps..." -ForegroundColor Cyan
Copy-Item -Path $warSource -Destination "$tomcatWebapps\smart-parking-system.war" -Force

Write-Host "[OK] Deployment complete!" -ForegroundColor Green
Write-Host "Access Application at: http://localhost:8080/smart-parking-system/" -ForegroundColor Green
