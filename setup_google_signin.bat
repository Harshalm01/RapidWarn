@echo off
echo.
echo ====================================
echo   RapidWarn Google Sign-In Setup
echo ====================================
echo.
echo Starting setup wizard...
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0setup_google_signin.ps1"
pause
