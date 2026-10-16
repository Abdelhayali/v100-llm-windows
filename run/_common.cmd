@echo off
rem Shared settings for the run scripts. ROOT = repo folder. Override with environment variables:
rem   PORT (default 8899), HOST (default 127.0.0.1; use 0.0.0.0 for LAN access), MODELS_DIR (default ROOT\models)
for %%I in ("%~dp0..") do set "ROOT=%%~fI"
if not defined MODELS_DIR set "MODELS_DIR=%ROOT%\models"
set "M=%MODELS_DIR%"
set "PATH=%ROOT%\bin\runtime;%PATH%"
if not defined PORT set "PORT=8899"
if not defined HOST set "HOST=127.0.0.1"
if not exist "%ROOT%\bin\pxa\llama-server.exe" (
  echo Prebuilt binaries not found in %ROOT%\bin. Run setup.ps1 first.
  exit /b 1
)
