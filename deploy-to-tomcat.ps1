# ==========================================================
# Deploy to Apache Tomcat 9
# ==========================================================

$tomcatWebapps = "C:\apache-tomcat-9.0.117\webapps"
$warSource = "C:\Users\LENOVO\smart-parking-system\target\smart-parking-system.war"

if (-not (Test-Path $warSource)) {
    Write-Host "WAR file not found. Running build.ps1 first..." -ForegroundColor Yellow
    & "C:\Users\LENOVO\smart-parking-system\build.ps1"
}

Write-Host "Deploying smart-parking-system.war to Tomcat 9 webapps..." -ForegroundColor Cyan
Copy-Item -Path $warSource -Destination "$tomcatWebapps\smart-parking-system.war" -Force

Write-Host "[OK] Deployment complete!" -ForegroundColor Green
Write-Host "Access Application at: http://localhost:8080/smart-parking-system/" -ForegroundColor Green
