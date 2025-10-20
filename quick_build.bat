@echo off
cls
echo.
echo ==========================================
echo      RapidWarn - Quick Build Menu
echo ==========================================
echo.
echo  1. Build Debug APK
echo  2. Build + Install on Device
echo  3. Clean + Build + Install
echo  4. Run with Hot Reload
echo  5. Check Device Connection
echo  6. View App Logs
echo  7. Setup Google Sign-In
echo  8. Exit
echo.
echo ==========================================
echo.

set /p choice="Select option (1-8): "

if "%choice%"=="1" goto build
if "%choice%"=="2" goto buildinstall
if "%choice%"=="3" goto cleanbuildinstall
if "%choice%"=="4" goto run
if "%choice%"=="5" goto checkdevice
if "%choice%"=="6" goto logs
if "%choice%"=="7" goto googlesignin
if "%choice%"=="8" goto exit

echo Invalid choice!
pause
goto menu

:build
echo.
echo Building Debug APK...
flutter build apk --debug
echo.
echo Done! APK location: build\app\outputs\flutter-apk\app-debug.apk
pause
exit

:buildinstall
echo.
echo Building Debug APK...
flutter build apk --debug
if %errorlevel% neq 0 (
    echo Build failed!
    pause
    exit
)
echo.
echo Installing on device...
adb install -r build\app\outputs\flutter-apk\app-debug.apk
echo.
echo Done!
pause
exit

:cleanbuildinstall
echo.
echo Cleaning project...
flutter clean
echo.
echo Getting dependencies...
flutter pub get
echo.
echo Building Debug APK...
flutter build apk --debug
if %errorlevel% neq 0 (
    echo Build failed!
    pause
    exit
)
echo.
echo Installing on device...
adb install -r build\app\outputs\flutter-apk\app-debug.apk
echo.
echo Done!
pause
exit

:run
echo.
echo Starting Flutter with Hot Reload...
echo Press 'r' for hot reload, 'R' for hot restart, 'q' to quit
echo.
flutter run
pause
exit

:checkdevice
echo.
echo Checking connected devices...
echo.
adb devices
echo.
pause
exit

:logs
echo.
echo Viewing app logs (Press Ctrl+C to stop)...
echo.
adb logcat -s flutter
pause
exit

:googlesignin
echo.
echo Starting Google Sign-In setup...
powershell -ExecutionPolicy Bypass -File "%~dp0setup_google_signin.ps1"
pause
exit

:exit
exit
