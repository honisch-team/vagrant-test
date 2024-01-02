@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
set MYDIR=%~dp0
set MYDIR=%MYDIR:~0,-1%
set LOGFILE=%TEMP%\post_install_3_vmw.log

call :log "*****************************"
call :log "*** VMware Post Install Script 3"
call :log "*****************************"

call :log
call :log "*** Register "on_logon_vmw" script"
call :log "*** Running: copy /Y "%MYDIR%\on_logon_vmw.bat" "C:\Windows\Temp""
copy /Y "%MYDIR%\on_logon_vmw.bat" "C:\Windows\Temp" || goto error
call :log "*** Running: reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run /v on_logon_vmw /t REG_SZ /d "\"C:\Windows\Temp\on_logon_vmw.bat\"" /f"
reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run /v on_logon_vmw /t REG_SZ /d "\"C:\Windows\Temp\on_logon_vmw.bat\"" /f

call :log
call :log "*** Signal end of OS install"
rem The following message doesn't work with "call :log" due to contained double quotes
echo %DATE% %TIME:~0,-3% *** Running: "%ProgramFiles%\VMware\VMware Tools\rpctool.exe" "info-set guestinfo.installation_finished y"
echo %DATE% %TIME:~0,-3% *** Running: "%ProgramFiles%\VMware\VMware Tools\rpctool.exe" "info-set guestinfo.installation_finished y" >>%LOGFILE%
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
echo %DATE% %TIME:~0,-3% %MSG%
echo %DATE% %TIME:~0,-3% %MSG% >>%LOGFILE%
exit /b 0
