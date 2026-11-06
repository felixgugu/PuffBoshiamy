@echo off
call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat" >nul
cd /d "%~dp0.."
cl /nologo /EHsc /std:c++17 /utf-8 /I tools /Fo:tools\ /Fe:tools\rime_harness.exe tools\rime_harness.cpp
