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
rem * Script to initially set up a repository
rem *
rem **************************************************************************

setlocal enabledelayedexpansion

set SCRIPTPATH=%~dp0
set LF=^


rem Two empty lines above are required

echo Setting up repository...

git config pull.rebase preserve
if errorlevel 1 goto failed

rem Check that all submodule commits to push are available on a remote
git config push.recurseSubmodules check
if errorlevel 1 goto failed

echo Installing hooks...

set GITHOOKPATH=.git\hooks

if exist common (
    set COMMONPATH=common\
) else (
    set COMMONPATH=
)

for /f %%i in ("post-checkout!LF!pre-push!LF!post-rewrite!LF!post-merge") do (
    rem Create backup of possible existing hook
    if exist %GITHOOKPATH%\%%i (
        call "%SCRIPTPATH%\mymove.bat" ^
            "%GITHOOKPATH%\%%i" "%GITHOOKPATH%\%%i.bak"
        if errorlevel 1 goto failed
    )
    
    rem Generate the new hook file
    rem Double slash is to prevent MSYS from applying automatic Posix path
    rem conversion, otherwise "/c" would turn into "C:\"
    rem NOTE: any changes being made here won't have effect on already checked-
    rem out repositories! Modify the .bat hook scripts in \Scripts instead!
    set HOOKFILE=^
#^^!/bin/sh!LF!!LF!^
# Hook file generated by %COMMONPATH%Scripts\%~nx0!LF!!LF!^
cmd.exe //c "%COMMONPATH%Scripts\%%i.bat $@"

    rem "|| rem" is required to set errorlevel here
    echo !HOOKFILE! > "%GITHOOKPATH%\%%i" || rem do_not_remove
    if errorlevel 1 goto failed
)

goto exit

:failed
exit /b 1

:exit
