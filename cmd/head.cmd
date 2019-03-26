::------------------------------------------------------------------------------
:: Show first lines in file
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

:: This script shows the first n lines in text file (default 5).
:: Syntax: head <file> [n]

@echo off

setlocal ENABLEDELAYEDEXPANSION

set /a cl=0

if [%2]==[] (
    set /a nr=5
) else (
    set /a nr=%2
)

::echo Show first %nr% lines

for /f "delims=" %%l in (%1) do (
    set /a cl+=1
    
    if !cl! equ !nr! (
        echo !cl!: %%l
        exit /b
    ) 
    echo !cl!: %%l
)

endlocal