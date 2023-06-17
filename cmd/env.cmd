::----------------------------------------------------------------------------
:: Example environment settings
::----------------------------------------------------------------------------

@echo off
@echo Welcome back!
title %USERNAME%@%COMPUTERNAME%

:: ORACLE environment NLS setting (for SQL*Plus)
:: overwrites HKEY_LOCAL_MACHINE\SOFTWARE\ORACLE
:: ENGLISH 
:: Windows Terminal codepage 850 (Multilingual - Latin 1)
:: chcp 850
:: set NLS_LANG=american_america.WE8MSWIN1252
:: GERMAN
:: Windows Terminal codepage 1252 (West European Latin)
:: chcp 1252
:: set NLS_LANG=german_germany.WE8MSWIN1252
:: Windows Terminal codepage 65001 (UTF-8)
chcp 65001

:: See https://ss64.com/nt/prompt.html
:: $A  &           (Ampersand) 
:: $B  |           (pipe) 
:: $C  (           (Left parenthesis) 
:: $D Current date 
:: $E Escape code  (ASCII code 27) 
:: $F  )           (Right parenthesis) 
:: $G  >           (greater-than sign) 
:: $H  Backspace   (erases previous character) 
:: $L  <           (less-than sign) 
:: $M  Display the remote name for Network drives
:: $N  Current drive 
:: $P  Current drive and path 
:: $Q  =           (equal sign) 
:: $S              (space) 
:: $T  Current time 
:: $V  Windows version number 
:: $_  Carriage return and linefeed 
:: $$  $           (dollar sign)
:: $+  Will display plus signs (+) one for each level of the PUSHD directory stack
:: Fancy command prompt!
set prompt=$_┌$s$E[0;1;32m$p$E[37m$_└$G$S

:: Avoid clashing with other application
set MY_EDITOR=C:\Program Files (x86)\Notepad++\notepad++.exe

doskey /MACROFILE=doskey.macro