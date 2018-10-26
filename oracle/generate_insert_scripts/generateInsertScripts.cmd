
:: Generate INSERT script
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

:: set console display codepage to Windows-1252 (single byte character 
:: encoding for Western European languages)
CHCP 1252

:: set Oracle client encoding to the same codepage Windows-1252
SET NLS_LANG=.WE8MSWIN1252

sqlplus scott/tiger@ORCL @generateInsertScripts.sql

powershell -file TrimTrailingSpacesInFile.ps1 INSERTscript.LST INSERTscript.sql

DEL INSERTscript.LST

ENDLOCAL