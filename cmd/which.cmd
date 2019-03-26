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

SETLOCAL ENABLEDELAYEDEXPANSION

SET /a cnt=1

:forloop
FOR /f "delims=; tokens=%cnt%" %%a in ("%PATH%") DO (
  SET /a cnt=cnt+1 
  
  IF EXIST %%a\%1.exe ECHO %%a\%1.exe
  IF EXIST %%a\%1.cmd ECHO %%a\%1.cmd
  IF EXIST %%a\%1.bat ECHO %%a\%1.bat
  
  :: Within a FOR loop the visibility of FOR variables 
  :: is controlled via SETLOCAL EnableDelayedExpansion 
  :: ECHO !cnt!
  IF %ERRORLEVEL% NEQ 0 (
     GOTO:done
  )
  GOTO:forloop
)

:done
ENDLOCAL