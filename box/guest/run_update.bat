@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
set MYDIR=%~dp0
set MYDIR=%MYDIR:~0,-1%

echo *****************************
echo *** Updating VM (%DATE% %TIME:~0,-3%)
echo *****************************

rem Set default values
set EXIT_CODE=0

rem Parse options
if "%~1"=="" goto skip_getopts
:getopts
if /I "%~1"=="NO_INSTALL_WU" set NO_INSTALL_WU=1 & echo Skip installing Windows Updates Online & goto next_opt
if /I "%~1"=="NO_INSTALL_WU_OFF" set NO_INSTALL_WU_OFF=1 & echo Skip installing Windows Updates Offline & goto next_opt
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

rem Disable automatic Windows Updates
echo.
echo *** Disable Windows Updates
net stop wuauserv >nul 2>&1
reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v NoAutoUpdate /t REG_DWORD /d 1 /f || goto error

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
rem Modify firewall to enable WinRM on private and public networks
netsh advfirewall firewall set rule name="Windows Remote Management (HTTP-In)" profile=private new profile="private,public"

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
echo *** Disable password expiration
net accounts /MAXPWAGE:UNLIMITED || goto error

rem Disable automatic Windows activation
echo.
echo *** Disable automatic Windows activation
reg add "HKLM\SOFTWARE\Microsoft\Windows NT \CurrentVersion\SoftwareProtectionPlatform\Activation" /v Manual /t REG_DWORD /d 1 /f || goto error

rem Tell Windows that BIOS RTC is UTC
rem echo.
rem echo *** Tell Windows that BIOS RTC is UTC
rem reg add "HKLM\SYSTEM\CurrentControlSet\Control\TimeZoneInformation" /v RealTimeIsUniversal /t REG_DWORD /d 1 /f || goto error

rem Configure Windows Explorer
echo.
echo *** Configure Windows Explorer settings
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Hidden /t REG_DWORD /d 1 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v HideFileExt /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v NavPaneShowAllFolders /t REG_DWORD /d 1 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v NavPaneExpandToCurrentFolder /t REG_DWORD /d 1 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowEncryptCompressedColor /t REG_DWORD /d 1 /f

rem Install Windows Updates Offline
:install_windows_updates_offline
echo.
if defined NO_INSTALL_WU_OFF (
  echo *** Skip installing Windows Updates Offline
  goto after_install_windows_updates_offline
)

rem Install KB 3020369: April 2015 servicing stack update for Windows 7
echo *** Installing KB 3020369: April 2015 servicing stack update for Windows 7
wusa "%MYDIR%\windows6.1-kb3020369-x86_82e168117c23f7c479a97ee96c82af788d07452e.msu" /quiet /norestart
if %ERRORLEVEL% equ 3010 (
  echo Return code %ERRORLEVEL% indicates success + reboot required
  set REBOOT_PENDING=1
) else (
  if %ERRORLEVEL% neq 0 goto error
)

rem Install KB 2670838: Platform update for Windows 7 SP1
echo.
echo *** Installing KB 2670838: Platform update for Windows 7 SP1
wusa "%MYDIR%\windows6.1-kb2670838-x86_984b8d122a688d917f81c04155225b3ef31f012e.msu" /quiet /norestart
if %ERRORLEVEL% equ 3010 (
  echo Return code %ERRORLEVEL% indicates success + reboot required
  set REBOOT_PENDING=1
) else (
  if %ERRORLEVEL% neq 0 goto error
)

rem KB 3125574: Convenience rollup update for Windows 7 SP1
echo.
echo *** Installing KB 3125574: Convenience rollup update for Windows 7 SP1
wusa "%MYDIR%\windows6.1-kb3125574-v4-x86_ba1ff5537312561795cc04db0b02fbb0a74b2cbd.msu" /quiet /norestart
if %ERRORLEVEL% equ 3010 (
  echo Return code %ERRORLEVEL% indicates success + reboot required
  set REBOOT_PENDING=1
) else (
  if %ERRORLEVEL% neq 0 goto error
)

rem Install KB 2729094: IE11 prerequisite: Update for the Segoe UI symbol font
echo.
echo *** Installing KB 2729094: IE11 prerequisite: Update for the Segoe UI symbol font
wusa "%MYDIR%\windows6.1-kb2729094-v2-x86.msu" /quiet /norestart
if %ERRORLEVEL% equ 3010 (
  echo Return code %ERRORLEVEL% indicates success + reboot required
  set REBOOT_PENDING=1
) else (
  if %ERRORLEVEL% neq 0 goto error
)

rem Reboot if required
if "%REBOOT_PENDING%"=="1" (
  set UPDATE_NEXT_ENTRY_POINT=install_windows_updates_offline_2
  goto reboot_and_continue
)

rem Install KB 2841134: Internet Explorer 11
:install_windows_updates_offline_2
echo.
echo *** Installing KB 2841134: Internet Explorer 11
"%MYDIR%\ie11-windows6.1-x86-en-us_fefdcdde83725e393d59f89bb5855686824d474e.exe" /quiet /norestart /update-no
if %ERRORLEVEL% equ 3010 (
  echo Return code %ERRORLEVEL% indicates success + reboot required
  set REBOOT_PENDING=1
) else (
  if %ERRORLEVEL% neq 0 goto error
)

rem KB 4490628: March 2019 servicing stack update for Windows 7
echo.
echo *** Installing KB 4490628: March 2019 servicing stack update for Windows 7
wusa "%MYDIR%\windows6.1-kb4490628-x86_3cdb3df55b9cd7ef7fcb24fc4e237ea287ad0992.msu" /quiet /norestart
if %ERRORLEVEL% equ 3010 (
  echo Return code %ERRORLEVEL% indicates success + reboot required
  set REBOOT_PENDING=1
) else (
  if %ERRORLEVEL% neq 0 goto error
)

rem KB 4474419: SHA-2 code signing support update for Windows 7
echo.
echo *** Installing KB 4474419: SHA-2 code signing support update for Windows 7
wusa "%MYDIR%\windows6.1-kb4474419-v3-x86_0f687d50402790f340087c576886501b3223bec6.msu" /quiet /norestart
if %ERRORLEVEL% equ 3010 (
  echo Return code %ERRORLEVEL% indicates success + reboot required
  set REBOOT_PENDING=1
) else (
  if %ERRORLEVEL% neq 0 goto error
)

rem Reboot if required
if "%REBOOT_PENDING%"=="1" (
  set UPDATE_NEXT_ENTRY_POINT=install_windows_updates_offline_3
  goto reboot_and_continue
)

rem KB 4534310: January 2020 Security Monthly Quality Rollup for Windows 7
:install_windows_updates_offline_3
echo.
echo *** Installing KB 4534310: January 2020 Security Monthly Quality Rollup for Windows 7
wusa "%MYDIR%\windows6.1-kb4534310-x86_887a5caab59437e8f23aa5a4608950455bb37537.msu" /quiet /norestart
if %ERRORLEVEL% equ 3010 (
  echo Return code %ERRORLEVEL% indicates success + reboot required
  set REBOOT_PENDING=1
) else (
  if %ERRORLEVEL% neq 0 goto error
)

rem KB 4534251: January 2020 Cumulative Security Update for Internet Explorer 11 for Windows 7
echo.
echo *** Installing KB 4534251: January 2020 Cumulative Security Update for Internet Explorer 11 for Windows 7
wusa "%MYDIR%\ie11-windows6.1-kb4534251-x86_6841cf7fda1f2b47d237fa66837c155ffa45c688.msu" /quiet /norestart
if %ERRORLEVEL% equ 3010 (
  echo Return code %ERRORLEVEL% indicates success + reboot required
  set REBOOT_PENDING=1
) else (
  if %ERRORLEVEL% neq 0 goto error
)

rem KB 4536952: January 2020 Servicing Stack Update for Windows 7
echo.
echo *** Installing KB 4536952: January 2020 Servicing Stack Update for Windows 7
wusa "%MYDIR%\windows6.1-kb4536952-x86_f3b49481187651f64f13a0369c86ad7caa83b190.msu" /quiet /norestart
if %ERRORLEVEL% equ 3010 (
  echo Return code %ERRORLEVEL% indicates success + reboot required
  set REBOOT_PENDING=1
) else (
  if %ERRORLEVEL% neq 0 goto error
)

:after_install_windows_updates_offline
rem Reboot if required
if "%REBOOT_PENDING%"=="1" (
  set UPDATE_NEXT_ENTRY_POINT=install_windows_updates_online
  goto reboot_and_continue
)

rem Install Windows updates online
:install_windows_updates_online
echo.
if defined NO_INSTALL_WU (
  echo *** Skip installing Windows Updates Online
  goto after_install_windows_updates_online
)
echo *** Installing Windows Updates Online
CScript //NoLogo "%MYDIR%\toolbox.wsf" /cmd:installwindowsupdates /maxUpdates:50
rem Script indicates success
if %ERRORLEVEL% equ 0 (
  echo Update script indicates success
  set UPDATE_NEXT_ENTRY_POINT=install_windows_updates_online
  goto exit_and_continue
)
rem Script indicates success + reboot required
if %ERRORLEVEL% equ 2 (
  echo Update script indicates success + reboot required
  set UPDATE_NEXT_ENTRY_POINT=install_windows_updates_online
  goto reboot_and_continue
)
rem Script indicates no updates found
if %ERRORLEVEL% equ 3 (
  echo Update script indicates "no updates found"
  goto cleanup_windows_update
)
rem Treat other exit codes as error
goto error
:after_install_windows_updates_online

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
cleanmgr /sagerun:64 || goto error

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
  if /I not "%%I"=="%WINDIR%\Temp\exec_cmd" (
    echo Removing dir %%I...
    rmdir /q /s %%I
  )
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

rem Clear network connection profile list
echo.
echo ** Clearing network connection profiles
CScript //NoLogo "%MYDIR%\toolbox.wsf" /cmd:clearnetconnectionprofiles || goto error

rem Rearm Windows activation counter
echo.
echo ** Rearm Windows activation counter
cscript //NoLogo C:\Windows\System32\slmgr.vbs /rearm

rem Add page file again on next startup
echo.
echo *** Add pagefile
wmic computersystem where name="%computername%" set AutomaticManagedPagefile=True || goto error

rem Finished
:finished
set EXIT_CODE=0
echo.
echo ************************************************************
echo *** Finished updating VM (%DATE% %TIME:~0,-3%)
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
echo *** Shutting down, continue after restart. Exit code: %EXIT_CODE% (%DATE% %TIME:~0,-3%)
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
echo *** Exit script and re-run. Exit code: %EXIT_CODE% (%DATE% %TIME:~0,-3%)
echo ************************************************************
goto end

:error
set ERROR_OCCURRED=1
set EXIT_CODE=1
echo ************************************************************
echo *** ERROR while updating VM. Exit code: %EXIT_CODE% (%DATE% %TIME:~0,-3%)
echo ************************************************************

:end
cmd /c exit %EXIT_CODE%
