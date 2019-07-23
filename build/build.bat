@echo off
echo.
echo This script is used to build the 64 bit interface between kafka and kdb+
echo.
echo Please ensure you have followed the instructions outlined in the README.md file on github.
echo In particular add the modifications to the include ("/I")in this script must be completed as outlined
echo.
:PROMPT
SET /P AREYOUSURE=Are you happy this has all been completed (Y/[N])?
IF /I "%AREYOUSURE%" NEQ "Y" GOTO END

:: Standalone build
curl -fsSL -o k.h          https://github.com/KxSystems/kdb/raw/master/c/c/k.h                   || goto :error
curl -fsSL -o q.lib        https://github.com/KxSystems/kdb/raw/master/w64/q.lib                 || goto :error

::keep original PATH, PATH may get too long otherwise
set OP=%PATH%
call "C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvars64.bat"
cl /LD /DKXVER=3 /I"C:/Users/jkandola/librdkafka.redist.1.0.0/build/native/include/" /Felibkfk.dll /O2 kfk.c q.lib
set PATH=%OP%

exit /b 0
:error
exit /b %errorLevel%
