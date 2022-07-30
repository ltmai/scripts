::------------------------------------------------------------------------------
:: Find and edit
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

:: This script finds all files under the current directory whose name
:: can be found with the provided input (e.g. pom would result in all
:: pom.xml and pom.properties). The file found are listed with number
:: which you can choose to edit. The editor is specified by environment
:: variable MY_EDITOR (to avoid clashing with other programs). If only
:: one file is found, the file is directly opened by the editor.
:: Example: C:\projects\fly-to-moon-and-back> fedit pom
:: [1] C:\projects\fly-to-moon-and-back\fly\pom.xml
:: [2] C:\projects\fly-to-moon-and-back\fly-war\pom.xml
:: [3] C:\projects\fly-to-moon-and-back\fly-ear\pom.xml
:: [4] C:\projects\fly-to-moon-and-back\fly-war\target\maven-archiver\pom.properties
:: Choose file to edit: _

@ECHO off

SETLOCAL ENABLEDELAYEDEXPANSION

SET /a CNT=1

:FORLOOP

FOR /f "tokens=*" %%a IN ('dir /s /p /b /a-d *%1*') DO (
  ECHO [!CNT!] %%a
  SET XYZ_!CNT!=%%a
  SET /a CNT=CNT+1
)

IF !CNT! EQU 1 (
    GOTO :EOF 
) ELSE ( 
    IF !CNT! EQU 2 (
        SET /a SEL=1
    ) ELSE (
        SET /p SEL=Choose file to edit: 
    )
)

:: Validate input
IF "!SEL!" EQU "" GOTO :EOF
IF "!SEL!" GEQ "!CNT!" GOTO :EOF

:: Set SEL to smt like XYZ_3
SET SEL=XYZ_!SEL!
::echo !SEL!
::SET !SEL!

:: Set SEL to value of %SEL%
SET sel=!%SEL%!
::echo !SEL!

:: START interprets the first quoted argument it finds as the window title for a new console window.
IF EXIST "!SEL!" START "" "%MY_EDITOR%" "!SEL!"

ENDLOCAL
