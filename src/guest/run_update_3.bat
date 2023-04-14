@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
set MYDIR=%~dp0
set MYDIR=%MYDIR:~0,-1%

echo *****************************
echo *** Updating VM: Script 3
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

rem Disable Windows Updates
echo.
echo *** Disable Windows Updates
net stop wuauserv >nul 2>&1
reg add "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" /v NoAutoUpdate /t REG_DWORD /d 1 /f || goto error


rem Cleanup Windows Update
echo.
echo *** Cleanup Windows Update
dism /Online /Cleanup-Image /spsuperseded || goto error

rem Cleanup SoftwareDistribution\Download folder
echo.
echo *** Cleanup %WINDIR%\SoftwareDistribution\Download
net stop wuauserv >nul 2>&1
for /D %I in (%WINDIR%\SoftwareDistribution\Download\*.*) do (rmdir /q /s %I)
del /Q /F %WINDIR%\SoftwareDistribution\Download\*.* >nul 2>&1

rem Remove page file
echo.
echo *** Remove page file
wmic computersystem where name="%computername%" set AutomaticManagedPagefile=False || goto error
wmic pagefileset where name="C:\\pagefile.sys" delete || goto error

rem Indicate next script must be called after shutdown
set EXIT_CODE=2

rem Finished
:finished
if %EXIT_CODE% equ 2 (
  echo.
  echo *** Initiating shutdown. Continue with next update script
  shutdown /a >nul 2>&1 & shutdown /s /f /t 10
)
echo ************************************************************
echo *** Finished updating VM: Script 3 (%EXIT_CODE%)
echo ************************************************************
goto end

:error
set ERROR_OCCURRED=1
set EXIT_CODE=1
echo ************************************************************
echo *** ERROR while updating VM: Script 3 (%EXIT_CODE%)
echo ************************************************************

:end
cmd /c exit %EXIT_CODE%
