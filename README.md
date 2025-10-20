# 🚨 RapidWarn - Emergency Alert System

A Flutter-based disaster alert and management system with AI-powered disaster classification.

---

## 🎯 **Super Simple Start (For Beginners)**

### **Step 1: Create Desktop Shortcuts** (One-Time)
**Double-click:** `create_shortcuts.bat`

This creates 3 shortcuts on your desktop:
- 📱 **RapidWarn - Build** (Build & install app)
- 🔐 **RapidWarn - Google Setup** (Fix Google Sign-In)
- 📖 **RapidWarn - Help** (Complete guide)

### **Step 2: Fix Google Sign-In** (One-Time)
**Double-click desktop shortcut:** `RapidWarn - Google Setup`

Follow the on-screen wizard (takes 3 minutes):
- ✅ Auto-gets SHA-1 fingerprint
- ✅ Opens Firebase Console
- ✅ Guides you through setup
- ✅ Updates app automatically

### **Step 3: Build & Install**
**Double-click desktop shortcut:** `RapidWarn - Build`

Select option 2: **Build + Install**

**Done! App is on your phone! 🎉**

---

## 📚 **Documentation**

- **[EASY_START.md](EASY_START.md)** - Beginner-friendly guide with pictures
- **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** - All commands and credentials
- **[Firebase Setup Guide](docs/firebase_setup.md)** - Detailed Firebase configuration

---

## 🛠️ **Helper Tools**

| Tool | Purpose | Usage |
|------|---------|-------|
| `quick_build.bat` | Build menu with 7 options | Double-click |
| `setup_google_signin.bat` | Auto-setup Google Sign-In | Double-click |
| `create_shortcuts.bat` | Create desktop shortcuts | Double-click once |
| `get_sha1.ps1` | Get SHA-1 fingerprint only | Right-click → Run with PowerShell |

---

## 🔑 **Test Credentials**

### User Login
- **Email:** `test@example.com`
- **Password:** `password123`
- **Or:** Use Google Sign-In

### Admin Login
- **Phone:** `+919324476116`
- **OTP:** `011107`

### Rescuer Login
- **Phone:** `+919324476117`
- **OTP:** `999999`

---

## ✨ **Features**

### 👤 User App
- 📍 Real-time disaster map
- 📸 AI-powered disaster detection
- 🔔 Location-based alerts
- 💬 Community reporting
- 🗺️ Interactive map with markers

### 👨‍💼 Admin Dashboard
- 📊 Analytics & statistics
- 👥 User management
- 🗺️ Full disaster monitoring
- 📝 Report moderation
- 🎨 Purple theme

### 🚑 Rescuer Dashboard
- 🗺️ Active disaster map
- 🚨 Real-time notifications
- 📋 Detailed disaster info
- ✅ Mark as rescued button
- 🎨 Green theme

---

## 🚀 **Quick Commands**

### Build & Install (Easy Way)
```cmd
quick_build.bat
```
Select option 2

### Manual Build & Install
```powershell
flutter build apk --debug
adb install -r build\app\outputs\flutter-apk\app-debug.apk
```

### Clean Build
```cmd
quick_build.bat
```
Select option 3

### Run with Hot Reload
```cmd
quick_build.bat
```
Select option 4

---

## 📱 **Technology Stack**

- **Framework:** Flutter 3.27+
- **Backend:** Firebase (Auth, Firestore) + Supabase
- **ML:** TensorFlow Lite (Disaster Classification)
- **Maps:** Flutter Map (OpenStreetMap)
- **Notifications:** Firebase Cloud Messaging
- **State:** Provider / setState

---

## 🎨 **Color Themes**

- **User:** Green `#7CA183`
- **Admin:** Purple `#5E35B1 → #7E57C2 → #9575CD`
- **Rescuer:** Teal Green `#16A085 → #2ECC71`

---

## 🐛 **Troubleshooting**

### Google Sign-In Not Working?
```cmd
setup_google_signin.bat
```

### Build Errors?
```cmd
quick_build.bat → Option 3 (Clean Build)
```

### Device Not Detected?
```powershell
adb devices
# Then authorize on phone
```

### More Help?
Check `EASY_START.md` for detailed troubleshooting

---

## 📂 **Project Structure**

```
RapidWarn/
├── lib/
│   ├── screens/          # UI screens
│   ├── services/         # Business logic
│   ├── widgets/          # Reusable widgets
│   └── main.dart         # App entry point
├── android/              # Android config
├── assets/               # Images, icons, animations
├── quick_build.bat       # 🔥 Build menu
├── setup_google_signin.bat  # 🔥 Google Sign-In setup
├── EASY_START.md         # 🔥 Beginner guide
└── QUICK_REFERENCE.md    # 🔥 Command reference
```

---

## 🎓 **For Developers**

### Setup Development Environment
1. Install Flutter SDK
2. Install Android Studio
3. Clone repository
4. Run `flutter pub get`
5. Double-click `create_shortcuts.bat`

### Daily Workflow
1. Connect phone
2. Double-click `RapidWarn - Build` (desktop)
3. Select option 2
4. Test changes

### Release Build
```powershell
flutter build apk --release
```

---

## 📞 **Support & Links**

- **Firebase Console:** https://console.firebase.google.com
- **Flutter Docs:** https://docs.flutter.dev
- **GitHub:** https://github.com/Harshalm01/RapidWarn

---

## 📝 **License**

MIT License - See LICENSE file

---

## 🎉 **Quick Start Summary**

1. **Run once:** `create_shortcuts.bat`
2. **Run once:** Desktop → `RapidWarn - Google Setup`
3. **Daily use:** Desktop → `RapidWarn - Build` → Option 2

**That's it! You're a developer now! 🚀**

---

*Made with ❤️ by Harshal*
*Last updated: October 20, 2025*
