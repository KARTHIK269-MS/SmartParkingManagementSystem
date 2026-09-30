@echo off
title Smart Parking System - Stop Tomcat 9
echo Stopping Apache Tomcat 9...

set "CATALINA_HOME=C:\apache-tomcat-9.0.117"
set "CATALINA_BASE=C:\apache-tomcat-9.0.117"

call "C:\apache-tomcat-9.0.117\bin\shutdown.bat"

echo Tomcat stopped.
pause
