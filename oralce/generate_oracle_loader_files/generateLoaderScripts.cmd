:: generate loader scripts

@echo off

setlocal

del output\*.dat

set dbconn=scott/tiger@ORCL

:: change table name, add tables as 
sqlplus %dbconn% @generateLoaderScript dept
sqlplus %dbconn% @generateLoaderScript emp
sqlplus %dbconn% @generateLoaderScript bonus
sqlplus %dbconn% @generateLoaderScript salgrade

:: remove trailing spaces
@for %%a in (output\*.LST) do ( 
    powershell -file TrimTrailingSpacesInFile.ps1 %%a output\%%~na.dat
)

:: remove .LST files
del output\*.LST

endlocal