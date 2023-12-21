@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
set MYDIR=%~dp0
set MYDIR=%MYDIR:~0,-1%
set LOGFILE=%TEMP%\post_install_2_vbx.log

call :log "*****************************"
call :log "*** VirtualBox Post Install Script 2"
call :log "*****************************"

call :log
call :log "*** Removing scheduled task "post_install_2_vbx""
call :log "*** Running: schtasks /delete /tn post_install_2_vbx /f"
schtasks /delete /tn post_install_2_vbx /f || goto error

call :log
call :log "*** Signal end of OS install"
call :log "*** Running: VBoxControl guestproperty set installation_finished y"
VBoxControl guestproperty set installation_finished y || goto error

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
