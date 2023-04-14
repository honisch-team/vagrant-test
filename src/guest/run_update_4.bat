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


rem TODO
rem Disable Windows Update

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
