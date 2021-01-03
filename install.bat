@echo off

Rem @file install.bat
Rem @fileoverview Install shared object to `%QHOME%\w64` and q scripts to `%QHOME%`.


Rem check destination directory exists
IF "%QHOME%"=="" (
    ECHO ERROR: Enviroment variable QHOME is NOT defined 
    EXIT /B
)

IF NOT EXIST %QHOME%\w64 (
    ECHO ERROR: Installation destination %QHOME%\w64 does not exist
    EXIT /B
)

IF NOT EXIST lib (
    ECHO ERROR: Directory 'lib' does not exist. Please run from release package
    EXIT /B
)

IF NOT EXIST q (
    ECHO ERROR: Directory 'q' does not exist. Please run from release package
    EXIT /B
)

Rem Copy q script to `%QHOME%`
ECHO Copying q script to %QHOME%
COPY q\* %QHOME%
IF %ERRORLEVEL% NEQ 0 (
    ECHO ERROR: Copy failed
    EXIT /B %ERRORLEVEL%
)

Rem Copy shared object to `%QHOME%\w64`
ECHO Copying DLL to %QHOME%\w64
COPY lib\* %QHOME%\w64\
IF %ERRORLEVEL% NEQ 0 (
    ECHO ERROR: Copy failed
    EXIT /B %ERRORLEVEL%
)

ECHO Installation complete