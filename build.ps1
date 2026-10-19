# ==========================================================
# Smart Parking Management System — Automated Build Script
# Java 17 + Dynamic Web Project Packaging (.war)
# ==========================================================

$ErrorActionPreference = "Stop"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host " Building Smart Parking Management System " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

$projectDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$classesDir = "$projectDir\src\main\webapp\WEB-INF\classes"
$buildClassesDir = "$projectDir\build\classes"
$targetDir = "$projectDir\target"

New-Item -ItemType Directory -Force -Path $classesDir | Out-Null
New-Item -ItemType Directory -Force -Path $buildClassesDir | Out-Null
New-Item -ItemType Directory -Force -Path $targetDir | Out-Null

# Resolve Tomcat libraries dynamically
$tomcatLibPaths = @(
    "C:\Program Files\apache-tomcat-9.0.117\lib",
    "C:\apache-tomcat-9.0.117\lib",
    "$env:CATALINA_HOME\lib"
)

$servletJar = $null
$jspJar = $null

foreach ($tPath in $tomcatLibPaths) {
    if (Test-Path "$tPath\servlet-api.jar") {
        $servletJar = "$tPath\servlet-api.jar"
        $jspJar = "$tPath\jsp-api.jar"
        break
    }
}

if (-not $servletJar) {
    # Check bundled WEB-INF/lib
    $servletJar = "$projectDir\src\main\webapp\WEB-INF\lib\servlet-api.jar"
    $jspJar = "$projectDir\src\main\webapp\WEB-INF\lib\jsp-api.jar"
}

$libJars = Get-ChildItem -Path "$projectDir\src\main\webapp\WEB-INF\lib" -Filter "*.jar" | Select-Object -ExpandProperty FullName
$classpath = (@($servletJar, $jspJar) + $libJars | Select-Object -Unique) -join ";"

$sources = Get-ChildItem -Path "$projectDir\src\main\java" -Filter "*.java" -Recurse | Select-Object -ExpandProperty FullName
Write-Host "1. Compiling $($sources.Count) Java 17 source files..." -ForegroundColor Yellow

& javac -encoding UTF-8 -cp "$classpath" -d "$classesDir" $sources

if ($LASTEXITCODE -ne 0) {
    Write-Host "Compilation failed!" -ForegroundColor Red
    exit 1
}

# Copy db.properties if exists
if (Test-Path "$projectDir\db.properties") {
    Copy-Item -Path "$projectDir\db.properties" -Destination "$classesDir\db.properties" -Force
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

# Optional sync to local Eclipse WTP if present on this machine
$wtpBase = Join-Path $env:USERPROFILE "eclipse-workspace\main.html\src\.metadata\.plugins\org.eclipse.wst.server.core\tmp1\wtpwebapps\smart-parking-system"
if (Test-Path $wtpBase) {
    Write-Host "3. Synchronizing to Eclipse Tomcat WTP deployment directory..." -ForegroundColor Yellow
    Copy-Item -Path "$projectDir\src\main\webapp\*" -Destination "$wtpBase" -Recurse -Force
    Write-Host "[OK] WTP directory synchronized!" -ForegroundColor Green
}

Write-Host "==================================================" -ForegroundColor Cyan
