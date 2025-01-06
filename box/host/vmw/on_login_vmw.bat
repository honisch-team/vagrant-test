@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
set MYDIR=%~dp0
set MYDIR=%MYDIR:~0,-1%

echo *****************************
echo *** VMware On Login Script
echo *****************************

echo.
echo *** Signal user login
"%ProgramFiles%\VMware\VMware Tools\rpctool.exe" "info-set guestinfo.user_logged_in y" 

echo.
echo *****************************
echo *** Success: VMware On Login Script
echo *****************************
goto end

:error
echo.
echo *****************************
echo *** ERROR: VMware On Login Script (%ERRORLEVEL%)
echo *****************************

:end

