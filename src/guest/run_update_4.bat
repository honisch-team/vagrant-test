@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
set MYDIR=%~dp0
set MYDIR=%MYDIR:~0,-1%

echo *****************************
echo *** Updating VM: Script 4
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

rem Zero unused diskspace to reduce VM disk file size
if defined OPT_DEBUG goto skip_sdelete
echo.
echo *** Zero unused diskspace
"%MYDIR%\sdelete.exe" -z c: /accepteula || goto error
:skip_sdelete

rem Add page file again on next startup
echo.
echo *** Add pagefile
wmic computersystem where name="%computername%" set AutomaticManagedPagefile=True || goto error

rem Finished
:finished
if %EXIT_CODE% equ 2 (
  echo.
  echo *** Initiating shutdown. Continue with next update script
  shutdown /a >nul 2>&1 & shutdown /s /f /t 10
)
echo ************************************************************
echo *** Finished updating VM: Script 4 (%EXIT_CODE%)
echo ************************************************************
goto end

:error
set ERROR_OCCURRED=1
set EXIT_CODE=1
echo ************************************************************
echo *** ERROR while updating VM: Script 4 (%EXIT_CODE%)
echo ************************************************************

:end
cmd /c exit %EXIT_CODE%
