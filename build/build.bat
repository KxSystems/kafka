@echo off
echo.

IF "%KAFKA_NATIVE%"=="" SET /P KAFKA_NATIVE="Please add full path to location of 'librdkafka.redist.1.0.0/build/native/include/': "

:: Standalone build
curl -fsSL -o ../k.h   https://github.com/KxSystems/kdb/raw/master/c/c/k.h      || goto :error
curl -fsSL -o ../q.lib https://github.com/KxSystems/kdb/raw/master/w64/q.lib    || goto :error

::keep original PATH, PATH may get too long otherwise
set OP=%PATH%
call "C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvars64.bat"
cl /LD /DKXVER=3 /I%KAFKA_NATIVE% /Felibkfk.dll /O2 ../kfk.c ../q.lib
set PATH=%OP%

exit /b 0
:error
exit /b %errorLevel%