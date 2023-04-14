@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
set MYDIR=%~dp0
set MYDIR=%MYDIR:~0,-1%

echo *****************************
echo *** Updating VM: Script 1
echo *****************************

rem Set default values
set OPT_DEBUG=
set EXIT_CODE=0

rem Parse options
if "%~1"=="" goto skip_getopts
:getopts
if /I "%~1"=="DEBUG" set OPT_DEBUG=1
shift
if not "%~1"=="" goto getopts
:skip_getopts

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
if %ERRORLEVEL% equ 0 (
  echo Returncode %ERRORLEVEL% indicates success
  goto after_kb3138612
)
if %ERRORLEVEL% equ 3010 (
  echo Returncode %ERRORLEVEL% indicates success + reboot required
  set EXIT_CODE=2
  goto after_kb3138612
)
echo *** Error installing KB3138612 (%ERRORLEVEL%)
goto error
:after_kb3138612

rem Finished
:finished
if %EXIT_CODE% equ 2 (
  echo.
  echo *** Initiating shutdown. Continue with next update script
  shutdown /a >nul 2>&1 & shutdown /s /f /t 10
)
echo ************************************************************
echo *** Finished updating VM: Script 1 (%EXIT_CODE%)
echo ************************************************************
goto end

:error
set ERROR_OCCURRED=1
set EXIT_CODE=1
echo ************************************************************
echo *** ERROR while updating VM: Script 1 (%EXIT_CODE%)
echo ************************************************************

:end
cmd /c exit %EXIT_CODE%
