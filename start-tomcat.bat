@echo off
title Smart Parking System - Apache Tomcat 9
echo ========================================================
echo Starting Apache Tomcat 9 (Java 17)
echo Application: Smart Parking Management System (PRJ_35)
echo ========================================================

set "CATALINA_HOME=C:\apache-tomcat-9.0.117"
set "CATALINA_BASE=C:\apache-tomcat-9.0.117"

call "C:\apache-tomcat-9.0.117\bin\startup.bat"

echo.
echo Tomcat is starting in a separate window!
echo Once started, open your browser at:
echo http://localhost:8080/smart-parking-system/
echo.
pause
