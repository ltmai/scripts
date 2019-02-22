:: Generate Oracle LOADER script
:: Copyright (C) 2018  - Linh Mai
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

:: The following is an example wrapper script to setup environment for 
:: running SQL script that write text with special characters (German)

@ECHO OFF

SETLOCAL

DEL output\*.dat

SET dbconn=scott/tiger@ORACLE

:: change table name, add tables as 
sqlplus %dbconn% @generateLoaderScript dept
sqlplus %dbconn% @generateLoaderScript emp
sqlplus %dbconn% @generateLoaderScript bonus
sqlplus %dbconn% @generateLoaderScript salgrade

:: remove trailing spaces
@FOR %%a IN (output\*.LST) DO ( 
    powershell -file TrimTrailingSpacesInFile.ps1 %%a output\%%~na.dat
)

:: remove .LST files
DEL output\*.LST

ENDLOCAL