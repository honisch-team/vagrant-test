@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
set MYDIR=%~dp0
set MYDIR=%MYDIR:~0,-1%

echo *****************************
echo *** Updating VM
echo *****************************

rem Set network connection profile to private
rem echo.
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
powercfg.exe /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c || goto error
powercfg.exe /change monitor-timeout-ac 0 || goto error
powercfg.exe /change disk-timeout-ac 0 || goto error

rem Turn off system restore
echo.
echo *** Turn off system restore
wmic.exe /namespace:\\root\default Path SystemRestore Call enable "C:\" || goto error
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
echo *** Disable password expiration for user %USERNAME
wmic USERACCOUNT WHERE Name='%USERNAME%' SET PasswordExpires=FALSE || goto

rem Disable automatic Windows activation
echo.
echo *** Disable automatic Windows activation
reg add "HKLM\SOFTWARE\Microsoft\Windows NT \CurrentVersion\SoftwareProtectionPlatform\Activation" /v Manual /t REG_DWORD /d 1 /f || goto error


rem TODO
rem Clean disk
rem Delete pagefile
rem Install Windows Updates
rem Zero disk sysinternals sdelete


rem Shutdown
echo.
shutdown /a >nul 2>&1 
shutdown /s /f /t 10 


rem Finished
echo ************************************************************
echo *** Success
echo ************************************************************

goto end

:error
set ERROR_OCCURRED=1

echo ************************************************************
echo *** ERROR 
echo ************************************************************

:end
if "%ERROR_OCCURRED%"=="1" (
  cmd /c exit 1
) else (
  cmd /c exit 0
)
