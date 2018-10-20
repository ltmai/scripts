:: generate loader scripts

@echo off

setlocal

del output\*.dat

set dbconn=username/password@ORACLE

:: change table name, add tables as 
sqlplus %dbconn% @generateLoaderScript table1
sqlplus %dbconn% @generateLoaderScript table2
sqlplus %dbconn% @generateLoaderScript table3

:: remove trailing spaces
@for %%a in (output\*.LST) do ( 
    powershell -file TrimTrailingSpacesInFile.ps1 %%a output\%%~na.dat
)

:: remove .LST files
del output\*.LST

endlocal