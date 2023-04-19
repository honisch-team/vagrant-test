@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
set MYDIR=%~dp0
set MYDIR=%MYDIR:~0,-1%

echo *****************************
echo *** VMware Post Install Script 2
echo *****************************

echo.
echo *** Removing scheduled task "vmw_post_install_2"
schtasks /delete /tn vmw_post_install_2 /f || goto error

echo.
echo *** Installing VMware Tools
E:\setup.exe /S /v "/qn REBOOT=R"
if %ERRORLEVEL% equ 0 goto vmware_tools_success
if %ERRORLEVEL% equ 3010 goto vmware_tools_success
goto error
:vmware_tools_success

echo.
echo *** Scheduling "vmw_post_install_3" after reboot
schtasks /create /sc onlogon /tn vmw_post_install_3 /tr "%MYDIR%\vmw_post_install_3.bat" /rl highest || goto error

set REBOOT_DELAY=10
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
