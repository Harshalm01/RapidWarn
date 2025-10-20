# Get SHA-1 fingerprint for Firebase Google Sign-In setup
Write-Host "🔑 Getting SHA-1 fingerprints for Firebase..." -ForegroundColor Cyan
Write-Host ""

# Check if keytool is available
$keytoolPath = "$env:JAVA_HOME\bin\keytool.exe"
if (-not (Test-Path $keytoolPath)) {
    # Try finding keytool in PATH
    $keytoolPath = (Get-Command keytool -ErrorAction SilentlyContinue).Path
}

if (-not $keytoolPath) {
    Write-Host "❌ keytool not found. Please install Java JDK." -ForegroundColor Red
    Write-Host "   Download from: https://www.oracle.com/java/technologies/downloads/" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Found keytool at: $keytoolPath" -ForegroundColor Green
Write-Host ""

# Get debug keystore SHA-1
$debugKeystore = "$env:USERPROFILE\.android\debug.keystore"
Write-Host "📋 DEBUG Keystore SHA-1 (for development):" -ForegroundColor Yellow
Write-Host "   Keystore: $debugKeystore" -ForegroundColor Gray

if (Test-Path $debugKeystore) {
    & $keytoolPath -list -v -keystore $debugKeystore -alias androiddebugkey -storepass android -keypass android 2>&1 | Select-String "SHA1"
    Write-Host ""
} else {
    Write-Host "   ⚠️ Debug keystore not found. Run your app once to generate it." -ForegroundColor Yellow
    Write-Host ""
}

# Get release keystore SHA-1
$releaseKeystore = "keys\rapidwarn_release.jks"
Write-Host "📋 RELEASE Keystore SHA-1 (for production):" -ForegroundColor Yellow
Write-Host "   Keystore: $releaseKeystore" -ForegroundColor Gray

if (Test-Path $releaseKeystore) {
    $storepass = Read-Host "Enter release keystore password (or press Enter to skip)" -AsSecureString
    if ($storepass.Length -gt 0) {
        $plainPass = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($storepass))
        & $keytoolPath -list -v -keystore $releaseKeystore -alias rapidwarn -storepass $plainPass -keypass $plainPass 2>&1 | Select-String "SHA1"
    }
    Write-Host ""
} else {
    Write-Host "   ⚠️ Release keystore not found at $releaseKeystore" -ForegroundColor Yellow
    Write-Host ""
}

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "📝 NEXT STEPS:" -ForegroundColor Green
Write-Host "1. Copy the SHA1 fingerprint from above" -ForegroundColor White
Write-Host "2. Go to Firebase Console: https://console.firebase.google.com" -ForegroundColor White
Write-Host "3. Select your project (RapidWarn)" -ForegroundColor White
Write-Host "4. Go to Project Settings > Your apps > Android app" -ForegroundColor White
Write-Host "5. Click 'Add fingerprint' and paste the SHA1" -ForegroundColor White
Write-Host "6. Download the updated google-services.json" -ForegroundColor White
Write-Host "7. Replace android/app/google-services.json with the new file" -ForegroundColor White
Write-Host "8. Rebuild your app: flutter clean && flutter build apk --debug" -ForegroundColor White
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
