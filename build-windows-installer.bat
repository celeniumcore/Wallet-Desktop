@echo off
setlocal
cd /d %~dp0

echo [1/4] Flutter clean...
call C:\flutter\bin\flutter.bat clean
if errorlevel 1 goto :err

echo [2/4] Flutter pub get...
call C:\flutter\bin\flutter.bat pub get
if errorlevel 1 goto :err

echo [3/4] Flutter build windows --release...
call C:\flutter\bin\flutter.bat build windows --release
if errorlevel 1 goto :err

echo [4/4] Build installer (Inno Setup 6)...
set ISCC="%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe"
if not exist %ISCC% set ISCC="%ProgramFiles%\Inno Setup 6\ISCC.exe"
if not exist %ISCC% (
  echo ERROR: Inno Setup 6 not found. Install from https://jrsoftware.org/isdl.php
  echo Portable build is ready at build\windows\x64\runner\Release\
  goto :err
)
%ISCC% "windows\installer.iss"
if errorlevel 1 goto :err

echo.
echo DONE. Installer: installer-out\Celenium-Wallet-Setup-1.0.3.exe
echo Portable:      build\windows\x64\runner\Release\celenium_wallet.exe
goto :eof

:err
echo Build failed with error %errorlevel%.
exit /b %errorlevel%
