:: Wrapper to setup environment for running SQL script that write text with special characters (German)

@echo off

setlocal

:: set console display codepage to Windows-1252 (single byte character encoding for Western European languages)
chcp 1252

:: set Oracle client encoding to the same codepage Windows-1252
set NLS_LANG=.WE8MSWIN1252

sqlplus scott/tiger@SALE @generateInsertScript

:: Todo remove trailing spaces and the line PL/SQL procedure successfully completed.
endlocal