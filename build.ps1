# ==========================================================
# Smart Parking Management System — Automated Build Script
# Java 17 + Dynamic Web Project Packaging (.war)
# ==========================================================

$ErrorActionPreference = "Stop"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host " Building Smart Parking Management System (PRJ_35) " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

$projectDir = "C:\Users\LENOVO\smart-parking-system"
$classesDir = "$projectDir\src\main\webapp\WEB-INF\classes"
$buildClassesDir = "$projectDir\build\classes"
$targetDir = "$projectDir\target"

New-Item -ItemType Directory -Force -Path $classesDir | Out-Null
New-Item -ItemType Directory -Force -Path $buildClassesDir | Out-Null
New-Item -ItemType Directory -Force -Path $targetDir | Out-Null

$classpath = @(
    "C:\Program Files\apache-tomcat-9.0.117\lib\servlet-api.jar",
    "C:\Program Files\apache-tomcat-9.0.117\lib\jsp-api.jar",
    "$projectDir\src\main\webapp\WEB-INF\lib\mysql-connector-j-9.7.0.jar"
) -join ";"

$sources = Get-ChildItem -Path "$projectDir\src\main\java" -Filter "*.java" -Recurse | Select-Object -ExpandProperty FullName
Write-Host "1. Compiling $($sources.Count) Java 17 source files..." -ForegroundColor Yellow

& javac -encoding UTF-8 -cp "$classpath" -d "$classesDir" $sources

if ($LASTEXITCODE -ne 0) {
    Write-Host "Compilation failed!" -ForegroundColor Red
    exit 1
}

# Copy to Eclipse build/classes
Copy-Item -Path "$classesDir\*" -Destination "$buildClassesDir" -Recurse -Force

Write-Host "2. Packaging smart-parking-system.war..." -ForegroundColor Yellow
$origLoc = Get-Location
Set-Location "$projectDir\src\main\webapp"
& jar -cvf "$targetDir\smart-parking-system.war" * | Out-Null
Set-Location $origLoc

$warFile = Get-Item "$targetDir\smart-parking-system.war"
Write-Host "[OK] Build Successful! WAR created:" -ForegroundColor Green
Write-Host "  Path: $($warFile.FullName)" -ForegroundColor Green
Write-Host "  Size: $([math]::Round($warFile.Length / 1MB, 2)) MB" -ForegroundColor Green

$wtpDir = "C:\Users\LENOVO\eclipse-workspace\main.html\src\.metadata\.plugins\org.eclipse.wst.server.core\tmp1\wtpwebapps\smart-parking-system"
if (Test-Path $wtpDir) {
    Write-Host "3. Synchronizing to Eclipse Tomcat WTP deployment directory..." -ForegroundColor Yellow
    Copy-Item -Path "$projectDir\src\main\webapp\*" -Destination "$wtpDir" -Recurse -Force
    Write-Host "[OK] WTP directory synchronized!" -ForegroundColor Green
}

$standaloneTomcat = "C:\Program Files\apache-tomcat-9.0.117\webapps"
if (Test-Path $standaloneTomcat) {
    try {
        Copy-Item -Path "$targetDir\smart-parking-system.war" -Destination "$standaloneTomcat" -Force -ErrorAction SilentlyContinue
        Write-Host "[OK] Standalone Tomcat webapps synchronized!" -ForegroundColor Green
    } catch {}
}
Write-Host "==================================================" -ForegroundColor Cyan
