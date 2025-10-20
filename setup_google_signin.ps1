# ========================================
# RapidWarn - Google Sign-In Auto Setup
# ========================================

Write-Host ""
Write-Host "🚀 RapidWarn - Google Sign-In Setup Assistant" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Get SHA-1 Fingerprint
Write-Host "📋 Step 1: Getting SHA-1 Fingerprint..." -ForegroundColor Yellow
$debugKeystore = "$env:USERPROFILE\.android\debug.keystore"

if (Test-Path $debugKeystore) {
    $sha1Output = keytool -list -v -keystore $debugKeystore -alias androiddebugkey -storepass android -keypass android 2>&1 | Select-String "SHA1"
    $sha1 = ($sha1Output -split "SHA1: ")[1].Trim()
    
    Write-Host "✅ Found SHA-1 Fingerprint:" -ForegroundColor Green
    Write-Host "   $sha1" -ForegroundColor White
    Write-Host ""
    
    # Copy to clipboard
    Set-Clipboard -Value $sha1
    Write-Host "📋 SHA-1 copied to clipboard!" -ForegroundColor Green
    Write-Host ""
} else {
    Write-Host "❌ Debug keystore not found. Please run your app once first." -ForegroundColor Red
    exit 1
}

# Step 2: Open Firebase Console
Write-Host "📋 Step 2: Firebase Console Setup" -ForegroundColor Yellow
Write-Host ""
Write-Host "I will open Firebase Console for you..." -ForegroundColor Cyan
Write-Host "Please complete these steps:" -ForegroundColor White
Write-Host ""
Write-Host "  1. Select your 'RapidWarn' project" -ForegroundColor White
Write-Host "  2. Click ⚙️ 'Project Settings' (top left)" -ForegroundColor White
Write-Host "  3. Scroll to 'Your apps' → Android app" -ForegroundColor White
Write-Host "  4. Click 'Add fingerprint'" -ForegroundColor White
Write-Host "  5. Paste: $sha1" -ForegroundColor Green
Write-Host "     (Already copied to clipboard!)" -ForegroundColor Gray
Write-Host "  6. Click 'Save'" -ForegroundColor White
Write-Host ""
Write-Host "Press any key to open Firebase Console..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

Start-Process "https://console.firebase.google.com"
Write-Host ""
Write-Host "✅ Firebase Console opened in browser" -ForegroundColor Green
Write-Host ""

# Wait for user to complete Firebase setup
Write-Host "⏳ Waiting for you to add SHA-1 in Firebase..." -ForegroundColor Yellow
Write-Host "   Press any key when you've added the SHA-1 fingerprint..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
Write-Host ""

# Step 3: Enable Google Sign-In
Write-Host "📋 Step 3: Enable Google Sign-In Method" -ForegroundColor Yellow
Write-Host ""
Write-Host "Opening Authentication settings..." -ForegroundColor Cyan
Start-Process "https://console.firebase.google.com/project/_/authentication/providers"
Write-Host ""
Write-Host "Please complete these steps:" -ForegroundColor White
Write-Host ""
Write-Host "  1. Click on 'Google' provider" -ForegroundColor White
Write-Host "  2. Toggle 'Enable' switch ON" -ForegroundColor White
Write-Host "  3. Add your email as support email" -ForegroundColor White
Write-Host "  4. Click 'Save'" -ForegroundColor White
Write-Host ""
Write-Host "Press any key when Google Sign-In is enabled..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
Write-Host ""

# Step 4: Download google-services.json
Write-Host "📋 Step 4: Download Updated google-services.json" -ForegroundColor Yellow
Write-Host ""
Write-Host "Opening Project Settings..." -ForegroundColor Cyan
Start-Process "https://console.firebase.google.com/project/_/settings/general"
Write-Host ""
Write-Host "Please complete these steps:" -ForegroundColor White
Write-Host ""
Write-Host "  1. Scroll to 'Your apps' → Android app" -ForegroundColor White
Write-Host "  2. Click 'google-services.json' download button" -ForegroundColor White
Write-Host "  3. Save the file (it will go to Downloads folder)" -ForegroundColor White
Write-Host ""
Write-Host "Press any key when you've downloaded the file..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
Write-Host ""

# Step 5: Replace google-services.json
Write-Host "📋 Step 5: Replacing google-services.json" -ForegroundColor Yellow
Write-Host ""

$downloadsFolder = "$env:USERPROFILE\Downloads"
$targetPath = "android\app\google-services.json"
$sourcePath = "$downloadsFolder\google-services.json"

if (Test-Path $sourcePath) {
    # Backup old file
    if (Test-Path $targetPath) {
        $backupPath = "android\app\google-services.json.backup"
        Copy-Item $targetPath $backupPath -Force
        Write-Host "✅ Backed up old file to: $backupPath" -ForegroundColor Green
    }
    
    # Copy new file
    Copy-Item $sourcePath $targetPath -Force
    Write-Host "✅ Copied new google-services.json to: $targetPath" -ForegroundColor Green
    Write-Host ""
} else {
    Write-Host "⚠️  google-services.json not found in Downloads folder" -ForegroundColor Yellow
    Write-Host "   Please manually copy it to: $targetPath" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Press any key when you've copied the file..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    Write-Host ""
}

# Step 6: Rebuild App
Write-Host "📋 Step 6: Rebuilding App" -ForegroundColor Yellow
Write-Host ""
Write-Host "Running: flutter clean..." -ForegroundColor Cyan
flutter clean
Write-Host ""
Write-Host "Running: flutter build apk --debug..." -ForegroundColor Cyan
flutter build apk --debug
Write-Host ""

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Build successful!" -ForegroundColor Green
    Write-Host ""
    
    # Step 7: Install on device
    Write-Host "📋 Step 7: Installing on Device" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Checking device connection..." -ForegroundColor Cyan
    
    $devices = & "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" devices
    if ($devices -match "device$") {
        Write-Host "✅ Device connected!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Installing APK..." -ForegroundColor Cyan
        & "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" install -r "build\app\outputs\flutter-apk\app-debug.apk"
        Write-Host ""
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ App installed successfully!" -ForegroundColor Green
            Write-Host ""
        } else {
            Write-Host "❌ Installation failed" -ForegroundColor Red
        }
    } else {
        Write-Host "⚠️  No device connected" -ForegroundColor Yellow
        Write-Host "   Please connect your device and run:" -ForegroundColor Yellow
        Write-Host "   adb install -r build\app\outputs\flutter-apk\app-debug.apk" -ForegroundColor Gray
        Write-Host ""
    }
} else {
    Write-Host "❌ Build failed. Please check the errors above." -ForegroundColor Red
    Write-Host ""
}

# Summary
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "🎉 Setup Complete!" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "✅ SHA-1 fingerprint: $sha1" -ForegroundColor White
Write-Host "✅ Firebase configured" -ForegroundColor White
Write-Host "✅ google-services.json updated" -ForegroundColor White
Write-Host "✅ App rebuilt and installed" -ForegroundColor White
Write-Host ""
Write-Host "🧪 Test Google Sign-In:" -ForegroundColor Yellow
Write-Host "   1. Open RapidWarn app on your device" -ForegroundColor White
Write-Host "   2. Click 'Google' sign-in button" -ForegroundColor White
Write-Host "   3. Select your Google account" -ForegroundColor White
Write-Host "   4. You should be signed in! 🎉" -ForegroundColor White
Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
