@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
set MYDIR=%~dp0
set MYDIR=%MYDIR:~0,-1%
set LOGFILE=%TEMP%\post_install_1_vbx.log

call :log "*****************************"
call :log "*** VirtualBox Post Install Script 1"
call :log "*****************************"

call :log
call :log "*** Installing certificates"
set MY_VBOX_ADDITIONS=E:
call :log "*** Running: %MY_VBOX_ADDITIONS%\cert\VBoxCertUtil.exe add-trusted-publisher %MY_VBOX_ADDITIONS%\cert\vbox*.cer --root %MY_VBOX_ADDITIONS%\cert\vbox*.cer"
%MY_VBOX_ADDITIONS%\cert\VBoxCertUtil.exe add-trusted-publisher %MY_VBOX_ADDITIONS%\cert\vbox*.cer --root %MY_VBOX_ADDITIONS%\cert\vbox*.cer || goto error

call :log
call :log "*** Installing guest additions"
call :log "*** Running: %MY_VBOX_ADDITIONS%\VBoxWindowsAdditions.exe /S"
%MY_VBOX_ADDITIONS%\VBoxWindowsAdditions.exe /S || goto error

call :log
call :log "*** Scheduling Post Install Script 2 after reboot"
call :log "*** Running: schtasks /create /sc onlogon /tn post_install_2_vbx /tr "%MYDIR%\post_install_2_vbx.bat" /rl highest"
schtasks /create /sc onlogon /tn post_install_2_vbx /tr "%MYDIR%\post_install_2_vbx.bat" /rl highest || goto error

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
