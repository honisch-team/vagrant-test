@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
set MYDIR=%~dp0
set MYDIR=%MYDIR:~0,-1%

echo *****************************
echo *** VMware Post Install Script 3
echo *****************************

echo.
echo *** Removing scheduled task "vmw_post_install_3"
schtasks /delete /tn vmw_post_install_3 /f || goto error
echo Exit code: %ERRORLEVEL%

echo.
echo *** Create "vmw_on_logon" scheduled task
copy /Y "%MYDIR%\vmw_on_logon.bat" "C:\Windows\Temp" || goto error
schtasks /create /sc onlogon /tn vmw_on_logon /tr "C:\Windows\Temp\vmw_on_logon.bat" /rl highest || goto error

echo.
echo *** Signal end of OS install
"%ProgramFiles%\VMware\VMware Tools\rpctool.exe" "info-set guestinfo.installation_finished y"

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
Pause
