@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
set MYDIR=%~dp0
set MYDIR=%MYDIR:~0,-1%
set LOGFILE=%TEMP%\post_install_2_vbx.log

call :log "*****************************"
call :log "*** VirtualBox Post Install Script 2"
call :log "*****************************"

call :log
call :log "*** Register "on_login_vbx" script"
call :log "*** Running: copy /Y "%MYDIR%\on_login_vbx.bat" "C:\Windows\Temp""
copy /Y "%MYDIR%\on_login_vbx.bat" "C:\Windows\Temp" || goto error
call :log "*** Running: reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run /v on_login_vbx /t REG_SZ /d "\"C:\Windows\Temp\on_login_vbx.bat\"" /f"
reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run /v on_login_vbx /t REG_SZ /d "\"C:\Windows\Temp\on_login_vbx.bat\"" /f

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
echo %DATE% %TIME:~0,-3% %MSG%
echo %DATE% %TIME:~0,-3% %MSG% >>%LOGFILE%
exit /b 0
