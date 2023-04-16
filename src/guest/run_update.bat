@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
set MYDIR=%~dp0
set MYDIR=%MYDIR:~0,-1%

echo *****************************
echo *** Updating VM
echo *****************************

rem Set default values
set EXIT_CODE=0

rem Parse options
if "%~1"=="" goto skip_getopts
:getopts
if /I "%~1"=="NO_INSTALL_WU" set NO_INSTALL_WU=1 & echo Skip installing Windows Updates & goto next_opt
if /I "%~1"=="NO_CLEANUP_DISM" set NO_CLEANUP_DISM=1 & echo Skip cleanup Windows Update & goto next_opt
if /I "%~1"=="NO_CLEANUP_WUD" set NO_CLEANUP_WUD=1 & echo Skip cleanup %WINDIR%\SoftwareDistribution\Download & goto next_opt
if /I "%~1"=="NO_CLEANUP_FILES" set NO_CLEANUP_FILES=1 & echo Skip cleanup various files & goto next_opt
if /I "%~1"=="NO_ZERODISK" set NO_ZERODISK=1 & echo Skip cleanup %WINDIR%\SoftwareDistribution\Download & goto next_opt
if /I "%~1"=="NO_CLEANMGR" set NO_CLEANMGR=1 & echo Skip Windows CleanMgr & goto next_opt
echo *** Warning: Unknown option "%~1"
:next_opt
shift
if not "%~1"=="" goto getopts
:skip_getopts

rem Load update state
set UPDATE_STATE_FILE=%MYDIR%\run_update.state.bat
if exist "%UPDATE_STATE_FILE%" (
  echo *** Loading update state from %UPDATE_STATE_FILE%...
  call "%UPDATE_STATE_FILE%" || goto error
)

rem Check whether we need to jump to a specific entry point
if defined UPDATE_NEXT_ENTRY_POINT (
  echo *** Continue with %UPDATE_NEXT_ENTRY_POINT%
  goto %UPDATE_NEXT_ENTRY_POINT%
)

rem Set network connection profile to private
echo.
echo *** Set network connection profile to private
CScript //NoLogo "%MYDIR%\toolbox.wsf" /cmd:setnetconnectionprofile /location:private || goto error
net stop netprofm & net start netprofm

rem Enable WinRM
echo.
echo *** Enable WinRM
call winrm quickconfig -q
call winrm set winrm/config/winrs @{MaxMemoryPerShellMB="512"}
call winrm set winrm/config @{MaxTimeoutms="1800000"}
call winrm set winrm/config/service @{AllowUnencrypted="true"}
call winrm set winrm/config/service/auth @{Basic="true"}
sc config WinRM start= auto

rem Set Powershell execution policy
echo.
echo *** Set Powershell execution policy
reg add "HKLM\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell" /v ExecutionPolicy /t REG_SZ /d Unrestricted /f || goto error

rem Set power settings
echo.
echo *** Set power settings
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c || goto error
powercfg /change monitor-timeout-ac 0 || goto error
powercfg /change disk-timeout-ac 0 || goto error
powercfg /hibernate off >nul 2>&1

rem Turn off system restore
echo.
echo *** Turn off system restore
wmic /namespace:\\root\default Path SystemRestore Call disable "C:\" || goto error
vssadmin delete shadows /all /quiet >nul 2>&1

rem Disable WinSAT
echo.
echo *** Disable WinSAT
schtasks /Change /TN "Microsoft\Windows\Maintenance\WinSAT" /Disable || goto error

rem  Enable RDP
echo.
echo *** Enable RDP
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f || goto error
netsh advfirewall firewall set rule group="remote desktop" new enable=Yes || goto error

rem Disable password expiration
echo.
echo *** Disable password expiration for user %USERNAME%
wmic USERACCOUNT WHERE Name='%USERNAME%' SET PasswordExpires=FALSE || goto

rem Disable automatic Windows activation
echo.
echo *** Disable automatic Windows activation
reg add "HKLM\SOFTWARE\Microsoft\Windows NT \CurrentVersion\SoftwareProtectionPlatform\Activation" /v Manual /t REG_DWORD /d 1 /f || goto error

rem Configure Windows Explorer
echo.
echo *** Configure Windows Explorer settings
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Hidden /t REG_DWORD /d 1 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v HideFileExt /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v NavPaneShowAllFolders /t REG_DWORD /d 1 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v NavPaneExpandToCurrentFolder /t REG_DWORD /d 1 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowEncryptCompressedColor /t REG_DWORD /d 1 /f

rem Install KB3138612 to fix Windows Update
echo.
echo *** Installing KB3138612 to fix Windows Update
wusa "%MYDIR%\kb3138612.msu" /quiet /norestart
if %ERRORLEVEL% equ 3010 (
  echo Returncode %ERRORLEVEL% indicates success + reboot required
  set UPDATE_NEXT_ENTRY_POINT=install_windows_updates
  goto reboot_and_continue
)
if %ERRORLEVEL% neq 0 goto error

rem Install Windows updates
:install_windows_updates
echo.
if defined NO_INSTALL_WU (
  echo *** Skip installing Windows Updates
  goto after_install_windows_updates
)
echo *** Installing Windows Updates
CScript //NoLogo "%MYDIR%\toolbox.wsf" /cmd:installwindowsupdates /maxUpdates:50
rem Script indicates success
if %ERRORLEVEL% equ 0 (
  echo Update script indicates success
  set UPDATE_NEXT_ENTRY_POINT=install_windows_updates
  goto exit_and_continue
)
rem Script indicates success + reboot required
if %ERRORLEVEL% equ 2 (
  echo Update script indicates success + reboot required
  set UPDATE_NEXT_ENTRY_POINT=install_windows_updates
  goto reboot_and_continue
)
rem Script indicates no updates found
if %ERRORLEVEL% equ 3 (
  echo Update script indicates "no updates found"
  goto cleanup_windows_update
)
rem Treat other exit codes as error
goto error
:after_install_windows_updates

rem Cleanup Windows Update
:cleanup_windows_update
echo.
if defined NO_CLEANUP_DISM (
  echo *** Skip cleanup Windows Update
  goto after_cleanup_windows_update
)
echo *** Cleanup Windows Update
dism /Online /Cleanup-Image /spsuperseded || goto error

rem Reboot and continue
echo.
echo *** Reboot and continue
set UPDATE_NEXT_ENTRY_POINT=cleanup_cleanmgr
goto reboot_and_continue
:after_cleanup_windows_update

rem Run Windows CleanMgr
:cleanup_cleanmgr
echo.
if defined NO_CLEANMGR (
  echo *** Skip cleanup using Windows CleanMgr
  goto after_cleanup_cleanmgr
)
echo *** Cleanup using Windows CleanMgr
rem Prepare registry
set CLEANMGR_GROUP=StateFlags0064
set CLEANMGR_ROOT_KEY=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches
set CLEANMGR_GROUP=StateFlags0064
set CLEANMGR_ROOT_KEY=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches
reg add "%CLEANMGR_ROOT_KEY%\Active Setup Temp Folders" /v %CLEANMGR_GROUP% /t REG_DWORD /d 2 /f
reg add "%CLEANMGR_ROOT_KEY%\Downloaded Program Files" /v %CLEANMGR_GROUP% /t REG_DWORD /d 2 /f
reg add "%CLEANMGR_ROOT_KEY%\Internet Cache Files" /v %CLEANMGR_GROUP% /t REG_DWORD /d 2 /f
reg add "%CLEANMGR_ROOT_KEY%\Memory Dump Files" /v %CLEANMGR_GROUP% /t REG_DWORD /d 2 /f
reg add "%CLEANMGR_ROOT_KEY%\Old ChkDsk Files" /v %CLEANMGR_GROUP% /t REG_DWORD /d 2 /f
reg add "%CLEANMGR_ROOT_KEY%\Previous Installations" /v %CLEANMGR_GROUP% /t REG_DWORD /d 2 /f
reg add "%CLEANMGR_ROOT_KEY%\Recycle Bin" /v %CLEANMGR_GROUP% /t REG_DWORD /d 2 /f
reg add "%CLEANMGR_ROOT_KEY%\ServicePack Cleanup" /v %CLEANMGR_GROUP% /t REG_DWORD /d 2 /f
reg add "%CLEANMGR_ROOT_KEY%\Setup Log Files" /v %CLEANMGR_GROUP% /t REG_DWORD /d 2 /f
reg add "%CLEANMGR_ROOT_KEY%\System error memory dump files" /v %CLEANMGR_GROUP% /t REG_DWORD /d 2 /f
reg add "%CLEANMGR_ROOT_KEY%\System error minidump files" /v %CLEANMGR_GROUP% /t REG_DWORD /d 2 /f
reg add "%CLEANMGR_ROOT_KEY%\Temporary Files" /v %CLEANMGR_GROUP% /t REG_DWORD /d 2 /f
reg add "%CLEANMGR_ROOT_KEY%\Temporary Setup Files" /v %CLEANMGR_GROUP% /t REG_DWORD /d 2 /f
reg add "%CLEANMGR_ROOT_KEY%\Thumbnail Cache" /v %CLEANMGR_GROUP% /t REG_DWORD /d 2 /f
reg add "%CLEANMGR_ROOT_KEY%\Update Cleanup" /v %CLEANMGR_GROUP% /t REG_DWORD /d 2 /f
reg add "%CLEANMGR_ROOT_KEY%\Upgrade Discarded Files" /v %CLEANMGR_GROUP% /t REG_DWORD /d 2 /f
reg add "%CLEANMGR_ROOT_KEY%\Windows Error Reporting Archive Files" /v %CLEANMGR_GROUP% /t REG_DWORD /d 2 /f
reg add "%CLEANMGR_ROOT_KEY%\Windows Error Reporting Queue Files" /v %CLEANMGR_GROUP% /t REG_DWORD /d 2 /f
reg add "%CLEANMGR_ROOT_KEY%\Windows Error Reporting System Archive Files" /v %CLEANMGR_GROUP% /t REG_DWORD /d 2 /f
reg add "%CLEANMGR_ROOT_KEY%\Windows Error Reporting System Queue Files" /v %CLEANMGR_GROUP% /t REG_DWORD /d 2 /f
reg add "%CLEANMGR_ROOT_KEY%\Windows Upgrade Log Files" /v %CLEANMGR_GROUP% /t REG_DWORD /d 2 /f
rem Run cleanup
echo *** Starting cleanmgr
cleanmgr /sagerun:64
echo Cleanmgr returned %ERRORLEVEL%

rem Reboot and continue
echo.
echo *** Reboot and continue
set UPDATE_NEXT_ENTRY_POINT=cleanup_windows_update_downloads
goto reboot_and_continue
:after_cleanup_cleanmgr

rem Cleanup SoftwareDistribution\Download folder
:cleanup_windows_update_downloads
echo.
if defined NO_CLEANUP_WUD (
  echo *** Skip cleanup %WINDIR%\SoftwareDistribution\Download
  goto after_cleanup_windows_update_downloads
)
echo.
echo *** Cleanup %WINDIR%\SoftwareDistribution\Download
net stop wuauserv >nul 2>&1
for /D %%I in (%WINDIR%\SoftwareDistribution\Download\*.*) do (
  echo Removing dir %%I...
  rmdir /q /s %%I
)
del /Q /F %WINDIR%\SoftwareDistribution\Download\*.* >nul 2>&1
:after_cleanup_windows_update_downloads

rem Disable Windows Updates
echo.
echo *** Disable Windows Updates
net stop wuauserv >nul 2>&1
reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v NoAutoUpdate /t REG_DWORD /d 1 /f || goto error

rem Remove page file
echo.
echo *** Remove page file
wmic computersystem where name="%computername%" set AutomaticManagedPagefile=False || goto error
wmic pagefileset where name="C:\\pagefile.sys" delete || goto error

rem Reboot and continue
echo.
echo *** Reboot and continue
set UPDATE_NEXT_ENTRY_POINT=cleanup_files
goto reboot_and_continue


rem Cleanup various files
:cleanup_files
echo.
if defined NO_CLEANUP_FILES (
  echo *** Skip cleanup various files
  goto after_cleanup_files
)
ech *** DEBUG Skipping cleanup files ***
goto after_cleanup_files
rem Cleanup user temp dir
echo *** Cleanup %TEMP%
for /D %%I in (%TEMP%\*.*) do (
  echo Removing dir %%I...
  rmdir /q /s %%I
)
del /Q /F %TEMP%\*.* >nul 2>&1

rem Cleanup windows temp dir
echo.
echo *** Cleanup %WINDIR%\Temp
for /D %%I in (%WINDIR%\Temp\*.*) do (
  echo Removing dir %%I...
  rmdir /q /s %%I
)
del /Q /F %WINDIR%\Temp\*.* >nul 2>&1

rem Cleanup log files
echo.
echo *** Cleanup log files
del /Q /F C:\*.log >nul 2>&1
del /Q /F C:\Windows\WindowsUpdate.log >nul 2>&1

:after_cleanup_files

rem Zero free diskspace to reduce VM disk file size
:zero_free_diskspace
echo.
if defined NO_ZERODISK (
  echo *** Skip zeroing free diskspace
  goto after_zero_free_diskspace
)
echo *** Zeroing free diskspace
"%MYDIR%\sdelete.exe" -z c: /accepteula || goto error
:after_zero_free_diskspace

rem Add page file again on next startup
echo.
echo *** Add pagefile
wmic computersystem where name="%computername%" set AutomaticManagedPagefile=True || goto error

rem Finished
:finished
set EXIT_CODE=0
echo.
echo ************************************************************
echo *** Finished updating VM
echo ************************************************************
goto end

rem Reboot and continue
:reboot_and_continue
rem Write next entry point to state file
echo.
echo *** Preparing reboot
echo *** Continue with entry point after reboot: %UPDATE_NEXT_ENTRY_POINT%
>>"%UPDATE_STATE_FILE%" echo set UPDATE_NEXT_ENTRY_POINT=%UPDATE_NEXT_ENTRY_POINT%
rem Initiate shutdown
echo.
echo *** Initiating shutdown. Continue with update script after restart
shutdown /a >nul 2>&1 & shutdown /s /f /t 10
set EXIT_CODE=2
echo.
echo ************************************************************
echo *** Shutting down, continue after restart (exit code: %EXIT_CODE%)
echo ************************************************************
goto end

rem Exit script and continue
:exit_and_continue
rem Write next entry point to state file
echo.
echo *** Exiting script and re-run
echo *** Continue with entry point on re-run: %UPDATE_NEXT_ENTRY_POINT%
>>"%UPDATE_STATE_FILE%" echo set UPDATE_NEXT_ENTRY_POINT=%UPDATE_NEXT_ENTRY_POINT%
set EXIT_CODE=3
echo.
echo ************************************************************
echo *** Exit script and re-run (exit code: %EXIT_CODE%)
echo ************************************************************
goto end

:error
set ERROR_OCCURRED=1
set EXIT_CODE=1
echo ************************************************************
echo *** ERROR while updating VM (exit code: %EXIT_CODE%)
echo ************************************************************

:end
cmd /c exit %EXIT_CODE%
