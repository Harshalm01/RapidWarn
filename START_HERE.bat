@echo off
color 0A
cls
echo.
echo  ╔══════════════════════════════════════════════════════════════╗
echo  ║                                                              ║
echo  ║           🚨 WELCOME TO RAPIDWARN DEVELOPMENT 🚨             ║
echo  ║                                                              ║
echo  ╚══════════════════════════════════════════════════════════════╝
echo.
echo.
echo  👋 Hi! I've made everything SUPER SIMPLE for you!
echo.
echo  ════════════════════════════════════════════════════════════════
echo.
echo  ✅ STEP 1: Check Your Desktop
echo     You should see 3 new shortcuts:
echo       📱 RapidWarn - Build
echo       🔐 RapidWarn - Google Setup  
echo       📖 RapidWarn - Help
echo.
echo  ════════════════════════════════════════════════════════════════
echo.
echo  ✅ STEP 2: Fix Google Sign-In (One-Time, 3 minutes)
echo     Double-click: "RapidWarn - Google Setup"
echo     Follow the wizard - it does everything for you!
echo.
echo  ════════════════════════════════════════════════════════════════
echo.
echo  ✅ STEP 3: Build Your App (Daily Use)
echo     Double-click: "RapidWarn - Build"
echo     Select option 2 (Build + Install)
echo     Wait 30 seconds - Done!
echo.
echo  ════════════════════════════════════════════════════════════════
echo.
echo  📝 QUICK TIPS:
echo.
echo     • Always connect your phone BEFORE building
echo     • Use "RapidWarn - Build" for everything
echo     • Check "RapidWarn - Help" if stuck
echo     • Test credentials are in QUICK_REFERENCE.md
echo.
echo  ════════════════════════════════════════════════════════════════
echo.
echo  🎯 WHAT TO DO NOW:
echo.
echo     1. Press ENTER to open the Quick Build menu
echo     2. Or close this and use desktop shortcuts
echo.
echo  ════════════════════════════════════════════════════════════════
echo.
pause
cls

:: Show the quick build menu
call quick_build.bat
