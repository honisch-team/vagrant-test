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

rem Cleanup Windows Update
echo.
echo *** Cleanup Windows Update
dism /Online /Cleanup-Image /spsuperseded || goto error

rem Remove page file
echo.
echo *** Remove page file
wmic computersystem where name="%computername%" set AutomaticManagedPagefile=False || goto error
wmic pagefileset where name="C:\\pagefile.sys" delete || goto error

rem Shutdown VM
echo.
echo *** Initiating shutdown. Continue with next update script
shutdown /a >nul 2>&1 & shutdown /s /f /t 10 
rem Indicate next script must be called after shutdown
set EXIT_CODE=2


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
  set EXIT_CODE=1
) 
echo Script will return %EXIT_CODE%
cmd /c exit %EXIT_CODE%
