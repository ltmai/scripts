::------------------------------------------------------------------------------
:: Locate executables
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

:: This script searches for executable of types .EXE, .CMD and .BAT 
:: in environment variable %PATH%.
:: Syntax: which <executable without extension>
:: Example: which grep

@ECHO off

:: see https://ss64.com/nt/delayedexpansion.html
SETLOCAL ENABLEDELAYEDEXPANSION

SET /a cnt=1

:FORLOOP

FOR /f "delims=; tokens=%cnt%" %%a in ("%PATH%") DO (
  SET /a cnt+=1   
  IF EXIST "%%a\%1.exe" ECHO %%a\%1.exe
  IF EXIST "%%a\%1.cmd" ECHO %%a\%1.cmd
  IF EXIST "%%a\%1.bat" ECHO %%a\%1.bat 
  rem Do not use double colon (::) inside a parenthesis
  rem block, which will cause the error message:
  rem "The system cannot find the drive specified."
  rem   
  rem Within a FOR loop the visibility of FOR variables 
  rem is controlled via SETLOCAL ENABLEDELAYEDEXPANSION.
  rem When ENABLEDELAYEDEXPANSION is on, variables can
  rem be immediately read using !variable_name!
  rem ECHO !cnt!
  
  IF %ERRORLEVEL% NEQ 0 (
     GOTO :EOF
  )
  GOTO :FORLOOP
)

ENDLOCAL
