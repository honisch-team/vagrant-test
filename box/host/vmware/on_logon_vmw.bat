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
echo *** Success: Installation finished
echo *****************************
goto end

:error
echo.
echo *****************************
echo *** ERROR, installation aborted (%ERRORLEVEL%)
echo *****************************

:end

