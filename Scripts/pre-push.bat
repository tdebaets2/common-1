@echo off

rem **************************************************************************
rem *
rem * Copyright 2016 Tim De Baets
rem *
rem * Licensed under the Apache License, Version 2.0 (the "License");
rem * you may not use this file except in compliance with the License.
rem * You may obtain a copy of the License at
rem *
rem *     http://www.apache.org/licenses/LICENSE-2.0
rem *
rem * Unless required by applicable law or agreed to in writing, software
rem * distributed under the License is distributed on an "AS IS" BASIS,
rem * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
rem * See the License for the specific language governing permissions and
rem * limitations under the License.
rem *
rem **************************************************************************
rem *
rem * Git pre-push hook
rem *
rem **************************************************************************

setlocal enabledelayedexpansion

rem Strange effects can occur if this script is updated while it is being
rem executed. Therefore, we first create a temporary copy of ourselves and
rem then transfer execution to that copy.
set BATCHNAME=%~nx0
set BATCHSUFFIX=%BATCHNAME:~-8%
set BATCHTMPNAME=
if not "%BATCHSUFFIX%"==".tmp.bat" (
    set BATCHTMPNAME=%~dpn0.tmp.bat
    call "%~dp0\mycopy.bat" "%~f0" "!BATCHTMPNAME%!"
    if errorlevel 1 goto failed
    rem Transfer execution to temporary copy
    "!BATCHTMPNAME!" %*
    if errorlevel 1 goto failed
)

if exist userprefs.bat call .\userprefs.bat

rem Run project-specific hook if it exists
if exist Hooks\pre-push.bat (
    call .\Hooks\pre-push.bat %*
    if errorlevel 1 goto failed
)

rem Check for files that were probably forgotten to be committed
if not "%PUSH_CHECK_FORGOTTEN_FILES%"=="0" (
    for /f %%i in ('git status --porcelain --untracked-files') do (
        echo Uncommitted local changes found; cannot continue
        goto failed
    )
)

rem Possibly update the common submodule from upstream
call "%~dp0\autoupdcommon.bat"
if errorlevel 1 goto failed

goto exit

:failed
echo *** pre-push FAILED ***
set ERRCODE=1
if "%BATCHSUFFIX%"==".tmp.bat" "%~dp0\deleteselfandexit.bat" "%~f0" %ERRCODE%
exit /b %ERRCODE%

:exit
if "%BATCHSUFFIX%"==".tmp.bat" "%~dp0\deleteselfandexit.bat" "%~f0"
