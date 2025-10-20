@echo off
echo.
echo Creating desktop shortcuts for easy access...
echo.

set SCRIPT_DIR=%~dp0
set DESKTOP=%USERPROFILE%\Desktop

:: Create shortcut for quick_build.bat
powershell -Command "$ws = New-Object -ComObject WScript.Shell; $s = $ws.CreateShortcut('%DESKTOP%\RapidWarn - Build.lnk'); $s.TargetPath = '%SCRIPT_DIR%quick_build.bat'; $s.WorkingDirectory = '%SCRIPT_DIR%'; $s.IconLocation = 'shell32.dll,21'; $s.Save()"

:: Create shortcut for setup_google_signin.bat
powershell -Command "$ws = New-Object -ComObject WScript.Shell; $s = $ws.CreateShortcut('%DESKTOP%\RapidWarn - Google Setup.lnk'); $s.TargetPath = '%SCRIPT_DIR%setup_google_signin.bat'; $s.WorkingDirectory = '%SCRIPT_DIR%'; $s.IconLocation = 'shell32.dll,14'; $s.Save()"

:: Create shortcut for EASY_START.md
powershell -Command "$ws = New-Object -ComObject WScript.Shell; $s = $ws.CreateShortcut('%DESKTOP%\RapidWarn - Help.lnk'); $s.TargetPath = '%SCRIPT_DIR%EASY_START.md'; $s.WorkingDirectory = '%SCRIPT_DIR%'; $s.IconLocation = 'shell32.dll,23'; $s.Save()"

echo.
echo ============================================
echo  ✅ Desktop shortcuts created!
echo ============================================
echo.
echo You can now access RapidWarn tools from:
echo.
echo  📱 RapidWarn - Build
echo     (Build and install app)
echo.
echo  🔐 RapidWarn - Google Setup
echo     (Fix Google Sign-In)
echo.
echo  📖 RapidWarn - Help
echo     (Easy start guide)
echo.
echo Check your desktop!
echo.
pause
