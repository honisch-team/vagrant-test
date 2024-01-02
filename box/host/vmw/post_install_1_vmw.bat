@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
set MYDIR=%~dp0
set MYDIR=%MYDIR:~0,-1%
set LOGFILE=%TEMP%\post_install_1_vmw.log

call :log "*****************************"
call :log "*** VMware Post Install Script 1"
call :log "*****************************"

call :log
call :log "*** Installing KB4474419"
call :log "*** Running: wusa "F:\kb4474419.msu" /quiet /norestart"
wusa "F:\kb4474419.msu" /quiet /norestart
if %ERRORLEVEL% equ 0 goto kb4474419_success
if %ERRORLEVEL% equ 3010 goto kb4474419_success
goto error
:kb4474419_success

call :log
call :log "*** Scheduling Post Install Script 2 after reboot"
call :log "*** Running: reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce /v post_install_2_vmw /t REG_SZ /d "\"%MYDIR%\post_install_2_vmw.bat\"" /f"
reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce /v post_install_2_vmw /t REG_SZ /d "\"%MYDIR%\post_install_2_vmw.bat\"" /f

set REBOOT_DELAY=30
call :log
call :log "*** Reboot in %REBOOT_DELAY% seconds"
call :log "*** Running: shutdown /a"
shutdown /a >nul 2>&1
call :log "*** Running: shutdown /r /f /t %REBOOT_DELAY%"
shutdown /r /f /t %REBOOT_DELAY%

call :log
call :log "*****************************"
call :log "*** Success: Installation will continue after scheduled reboot %REBOOT_DELAY% seconds..."
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
