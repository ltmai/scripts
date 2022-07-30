::------------------------------------------------------------------------------
:: Bookmarks for CMD
:: Copyright (C) 2019  - Linh Mai
:: 
:: This program is free software: you can redistribute it and/or modify
:: it under the terms of the GNU General Public License as published by
:: the Free Software Foundation, either version 3 of the License, or
:: (at your option) any later version.
:: 
:: This program is distributed in the hope that it will be useful,
:: but WITHOUT ANY WARRANTY; without even the implied warranty of
:: MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
:: GNU General Public License for more details.
:: 
:: You should have received a copy of the GNU General Public License
:: along with this program.  If not, see <http://www.gnu.org/licenses/>.
::----------------------------------------------------------------------------

:: This scripts interprets a BOOKMARKS environment variable and lists
:: the paths defined in it as a numbered list, for which you can 
:: choose to navigate to. Example:
:: set BOOKMARKS=%USERPROFILE%;C:\bin;C:\projects;C:\workspace
::
:: Running this script without parameter would show the following:
:: asking you to choose the target directory by number:
:: C:\> fav
:: [1] C:\Users\mai
:: [2] C:\bin
:: [3] C:\projects
:: [4] C:\workspace
:: Change to: 3
:: C:\projects> _
:: Running this script with a parameter would bring you directly to
:: the target directory:
:: C:> fav 1
:: C:\Users\mai> _
:: Invalid number are rejected.
::
:: This script can also be used together with a macro:
:: doskey bm=SET BOOKMARKS=%%BOOKMARKS%%;%%CD%%
:: to add current directory into BOOKMAKRS environment variable when
:: you want to dynamically add a new directory.

@ECHO off

SETLOCAL ENABLEDELAYEDEXPANSION

:: Number of elements in bookmark
SET /a CNT=1

:FORLOOP

FOR /f "delims=; tokens=%CNT%" %%a IN ("%BOOKMARKS%") DO (
  IF "%1" EQU "" ECHO [!CNT!] %%a
  SET XYZ_!CNT!=%%a
  SET /a CNT+=1

  IF %ERRORLEVEL% NEQ 0 GOTO :EOF
  GOTO :FORLOOP
)


IF "%1" EQU "" (
    SET /p SEL=Change to: 
) ELSE (
    SET /a INP=%1
    IF !INP! GEQ !CNT! GOTO :EOF
    SET /a SEL=%1
)

:: Validate input
IF "!SEL!" EQU "" GOTO :EOF
IF "!SEL!" GEQ "!CNT!" GOTO :EOF
:: Set SEL to smt like XYZ_3
SET SEL=XYZ_!SEL!
:: Set SEL to value of %SEL%
SET sel=!%SEL%!

:: Save value of local variable
ENDLOCAL & SET FAV="%SEL%"

CD %FAV%