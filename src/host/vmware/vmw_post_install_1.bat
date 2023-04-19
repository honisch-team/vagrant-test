@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
set MYDIR=%~dp0
set MYDIR=%MYDIR:~0,-1%

echo *****************************
echo *** VMware Post Install Script 1
echo *****************************

echo.
echo *** Installing KB4474419
wusa "F:\kb4474419.msu" /quiet /norestart
if %ERRORLEVEL% equ 0 goto kb4474419_success
if %ERRORLEVEL% equ 3010 goto kb4474419_success
goto error
:kb4474419_success

echo.
echo *** Scheduling Post Install Script 2 after reboot
schtasks /create /sc onlogon /tn vmw_post_install_2 /tr "%MYDIR%\vmw_post_install_2.bat" /rl highest || goto error

set REBOOT_DELAY=30
echo.
echo *** Reboot in %REBOOT_DELAY% seconds
shutdown /a >nul 2>&1
shutdown /r /f /t %REBOOT_DELAY%

echo.
echo *****************************
echo *** Success: Installation will continue after scheduled reboot %REBOOT_DELAY% seconds...
echo *****************************
goto end

:error
echo.
echo *****************************
echo *** ERROR, installation aborted (%ERRORLEVEL%)
echo *****************************

:end
Pause