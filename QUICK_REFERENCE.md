# 🚀 RapidWarn - Quick Commands Reference

## 📱 Build & Install Commands

### Build Debug APK
```powershell
flutter build apk --debug
```

### Build Release APK
```powershell
flutter build apk --release
```

### Install on Device
```powershell
adb install -r build\app\outputs\flutter-apk\app-debug.apk
```

### Clean Build
```powershell
flutter clean
flutter pub get
flutter build apk --debug
```

### Run on Device (Hot Reload)
```powershell
flutter run
```

---

## 🔧 Development Commands

### Check Connected Devices
```powershell
adb devices
```

### View App Logs
```powershell
adb logcat -s flutter
```

### Clear App Data
```powershell
adb shell pm clear com.example.rapidwarn
```

### Restart ADB
```powershell
adb kill-server
adb start-server
```

---

## 🔐 Google Sign-In Setup

### Auto Setup (Recommended)
```powershell
.\setup_google_signin.bat
```

### Manual Setup
1. Get SHA-1:
```powershell
.\get_sha1.ps1
```

2. Add SHA-1 to Firebase Console:
   - https://console.firebase.google.com
   - Project Settings → Your apps → Add fingerprint

3. Enable Google Sign-In:
   - Authentication → Sign-in method → Google → Enable

4. Download new google-services.json
   - Replace in: android/app/google-services.json

5. Rebuild:
```powershell
flutter clean
flutter build apk --debug
```

---

## 🧪 Testing Credentials

### Admin Login
- Phone: `+919324476116`
- OTP: `011107`

### Rescuer Login
- Phone: `+919324476117`
- OTP: `999999`

### User Login
- Email: (any email)
- Password: (any password - will auto-register)
- Google Sign-In: (your Google account)

---

## 🗂️ Important Files

### Android
- `android/app/build.gradle.kts` - Build configuration
- `android/app/google-services.json` - Firebase config
- `android/app/src/main/AndroidManifest.xml` - Permissions

### Firebase
- `lib/firebase_options.dart` - Firebase initialization
- `lib/services/notification_service.dart` - Push notifications

### Screens
- `lib/screens/login_screen.dart` - User login
- `lib/screens/admin_login_screen.dart` - Admin login
- `lib/screens/rescuer_login_screen.dart` - Rescuer login
- `lib/screens/rescuer_dashboard_screen.dart` - Rescuer dashboard

---

## 🎨 Color Scheme

### User Theme
- Primary: `#7CA183` (Green)
- Background: `#181A20` (Dark)

### Admin Theme
- Primary: `#9575CD` (Purple)
- Gradient: `#5E35B1 → #7E57C2 → #9575CD`

### Rescuer Theme
- Primary: `#16A085` (Teal Green)
- Gradient: `#16A085 → #2ECC71`

---

## 📦 Dependencies

### Core
- `firebase_core`
- `firebase_auth`
- `cloud_firestore`
- `supabase_flutter`

### Maps & Location
- `flutter_map`
- `latlong2`
- `geolocator`

### UI
- `lottie` - Animations
- `image_picker` - Camera/Gallery
- `cached_network_image` - Image caching

### ML
- `tflite_flutter` - TensorFlow Lite
- `image` - Image processing

---

## 🐛 Common Issues & Fixes

### Google Sign-In Error
```powershell
# Run auto setup
.\setup_google_signin.bat
```

### Build Errors
```powershell
# Clean and rebuild
flutter clean
flutter pub get
flutter build apk --debug
```

### Device Not Detected
```powershell
# Enable USB debugging on device
# Restart ADB
adb kill-server
adb start-server
adb devices
```

### Hot Reload Not Working
```powershell
# Stop and restart
flutter run
# Press 'r' for hot reload
# Press 'R' for hot restart
```

---

## 📞 Support

### Firebase Console
https://console.firebase.google.com

### Flutter Docs
https://docs.flutter.dev

### GitHub Repository
https://github.com/Harshalm01/RapidWarn

---

## 🎯 Quick Start Workflow

1. **Connect device**: `adb devices`
2. **Build**: `flutter build apk --debug`
3. **Install**: `adb install -r build\app\outputs\flutter-apk\app-debug.apk`
4. **Test Google Sign-In**: Run `.\setup_google_signin.bat` if needed
5. **Done!** 🎉

---

*Last updated: October 20, 2025*
