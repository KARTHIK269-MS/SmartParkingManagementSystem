$ErrorActionPreference = "Stop"

$projectDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$classesDir = "$projectDir\src\main\webapp\WEB-INF\classes"

# Classpath setup
$cpParts = @(
    $classesDir,
    "$projectDir\src\main\webapp\WEB-INF\lib\*",
    "C:\Program Files\apache-tomcat-9.0.117\lib\servlet-api.jar",
    "C:\Program Files\apache-tomcat-9.0.117\lib\jsp-api.jar"
)
$cp = $cpParts -join ";"

Write-Host "Compiling test sources..." -ForegroundColor Cyan
& javac -encoding UTF-8 -cp "$cp" -d "$classesDir" "$projectDir\src\test\java\com\parkingsystem\MiniProjectUnitTest.java" "$projectDir\src\test\java\com\parkingsystem\TestSystem.java" "$projectDir\src\test\java\com\parkingsystem\BayAvailabilitySyncTest.java" "$projectDir\src\test\java\com\parkingsystem\AdminReportsTest.java" "$projectDir\src\test\java\com\parkingsystem\ANPRGateWorkflowTest.java" "$projectDir\src\test\java\com\parkingsystem\BookingLifecycleAuditTest.java"

Write-Host "`n1. Running Mini-Project Core Unit Tests..." -ForegroundColor Yellow
& java -cp "$cp" -ea com.parkingsystem.MiniProjectUnitTest

Write-Host "`n2. Running System Integration & Verification Tests..." -ForegroundColor Yellow
& java -cp "$cp" -ea com.parkingsystem.TestSystem

Write-Host "`n3. Running Bay Availability & Active Session Sync Audit Suite..." -ForegroundColor Yellow
& java -cp "$cp" -ea com.parkingsystem.BayAvailabilitySyncTest

Write-Host "`n4. Running Admin Reports & Data Export Audit Suite..." -ForegroundColor Yellow
& java -cp "$cp" -ea com.parkingsystem.AdminReportsTest

Write-Host "`n5. Running ANPR & Gate Access Workflow Audit Suite..." -ForegroundColor Yellow
& java -cp "$cp" -ea com.parkingsystem.ANPRGateWorkflowTest

Write-Host "`n6. Running Booking & Parking-Session Lifecycle Audit Suite..." -ForegroundColor Yellow
& java -cp "$cp" -ea com.parkingsystem.BookingLifecycleAuditTest
