@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
set MYDIR=%~dp0
set MYDIR=%MYDIR:~0,-1%
set LOGFILE=%TEMP%\post_install_3_vmw.log

call :log "*****************************"
call :log "*** VMware Post Install Script 3"
call :log "*****************************"

call :log
call :log "*** Removing scheduled task "post_install_3_vmw""
call :log "*** Running: schtasks /delete /tn post_install_3_vmw /f"
schtasks /delete /tn post_install_3_vmw /f || goto error

call :log
call :log "*** Create "on_logon_vmw" scheduled task"
call :log "*** Running: copy /Y "%MYDIR%\on_logon_vmw.bat" "C:\Windows\Temp""
copy /Y "%MYDIR%\on_logon_vmw.bat" "C:\Windows\Temp" || goto error
call :log "*** Running: schtasks /create /sc onlogon /tn on_logon_vmw /tr "C:\Windows\Temp\on_logon_vmw.bat" /rl highest"
schtasks /create /sc onlogon /tn on_logon_vmw /tr "C:\Windows\Temp\on_logon_vmw.bat" /rl highest || goto error

call :log
call :log "*** Signal end of OS install"
rem The following message doesn't work with "call :log" due to contained double quotes
echo *** Running: "%ProgramFiles%\VMware\VMware Tools\rpctool.exe" "info-set guestinfo.installation_finished y"
echo *** Running: "%ProgramFiles%\VMware\VMware Tools\rpctool.exe" "info-set guestinfo.installation_finished y" >>%LOGFILE%
"%ProgramFiles%\VMware\VMware Tools\rpctool.exe" "info-set guestinfo.installation_finished y"

call :log
call :log "*****************************"
call :log "*** Success: Installation finished
call :log "*****************************"
goto end

:error
call :log
call :log "*****************************"
call :log "*** ERROR, installation aborted (%ERRORLEVEL%)"
call :log "*****************************"

:end
Pause
goto :eof

:log
set MSG=%~1
if "%MSG%"=="" (
  echo.
  echo. >>%LOGFILE%
) else (
  echo %MSG%
  echo %MSG% >>%LOGFILE%
)
exit /b 0
