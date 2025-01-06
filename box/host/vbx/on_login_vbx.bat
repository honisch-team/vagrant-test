@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
set MYDIR=%~dp0
set MYDIR=%MYDIR:~0,-1%

echo *****************************
echo *** VirtualBox On Login Script
echo *****************************

echo.
echo *** Signal user login
"%SystemRoot%\System32\VBoxControl.exe" guestproperty set vm_user_logon true --flags TRANSRESET

echo.
echo *****************************
echo *** Success: VirtualBox On Login Script
echo *****************************
goto end

:error
echo.
echo *****************************
echo *** ERROR: VirtualBox On Login Script (%ERRORLEVEL%)
echo *****************************

:end

