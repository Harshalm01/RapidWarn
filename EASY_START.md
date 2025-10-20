# 🚀 RapidWarn - Simplified Development Guide

Welcome! I've created several helper tools to make your work super simple. Just double-click and follow the prompts!

---

## 🎯 Quick Start (3 Easy Steps)

### Step 1: Fix Google Sign-In (One-Time Setup)
**Double-click: `setup_google_signin.bat`**

This will:
- ✅ Automatically get your SHA-1 fingerprint
- ✅ Copy it to clipboard
- ✅ Open Firebase Console for you
- ✅ Guide you through adding the fingerprint
- ✅ Update google-services.json
- ✅ Rebuild and install the app

**Takes 3 minutes!**

---

### Step 2: Daily Development
**Double-click: `quick_build.bat`**

Choose from menu:
1. **Build Debug APK** - Just build
2. **Build + Install** - Build and put on phone
3. **Clean + Build + Install** - Fresh build from scratch
4. **Run with Hot Reload** - Live coding!
5. **Check Device** - Is phone connected?
6. **View Logs** - See app debug info
7. **Setup Google Sign-In** - Run setup again

**Most common: Option 2 (Build + Install)**

---

### Step 3: Test on Phone

**Login Credentials:**

**Regular User:**
- Email: `anything@example.com`
- Password: `password123`
- Or use Google Sign-In

**Admin:**
- Phone: `+919324476116`
- OTP: `011107`

**Rescuer:**
- Phone: `+919324476117`
- OTP: `999999`

---

## 📚 Cheat Sheet

### Want to Build & Install Quickly?
```powershell
# Just run this:
quick_build.bat

# Select option 2
```

### Google Sign-In Not Working?
```powershell
# Just run this:
setup_google_signin.bat

# Follow the on-screen steps (takes 3 minutes)
```

### Need SHA-1 Fingerprint Only?
```powershell
# Run this:
get_sha1.ps1
```

---

## 🎨 App Features

### ✅ User Features
- 📍 Real-time disaster map
- 📸 Upload disaster photos
- 🤖 AI disaster classification (Fire, Accident, Stampede, etc.)
- 🔔 Get notified of nearby disasters
- 💬 Report and comment
- 👍 Like/dislike reports

### ✅ Admin Features
- 📊 Analytics dashboard
- 👥 User management
- 🗺️ Full disaster map
- 📝 Report moderation
- 📈 Statistics

### ✅ Rescuer Features
- 🗺️ Active disaster map
- 🚨 Real-time notifications
- 📋 Disaster details view
- ✅ Mark as rescued button
- 🔔 Notify users when resolved

---

## 📱 App Structure

```
User Login → Main App
    ├── Home (Map with disasters)
    ├── Alerts (Notifications)
    ├── Community Feed
    └── More (Settings, Profile)

Admin Login → Admin Dashboard
    ├── Map View
    ├── User Management
    ├── Analytics
    └── Reports

Rescuer Login → Rescuer Dashboard
    ├── Map (Active disasters)
    └── Details (Disaster info + Rescue button)
```

---

## 🎨 Color Themes

- **User App**: Green (`#7CA183`)
- **Admin**: Purple (`#9575CD`)
- **Rescuer**: Teal Green (`#16A085`)

---

## 🐛 Common Problems & Solutions

### Problem: "Google Sign-In Failed"
**Solution:** Run `setup_google_signin.bat`

### Problem: "Device Not Found"
**Solution:** 
1. Enable USB Debugging on phone
2. Run `adb devices`
3. Allow USB debugging prompt on phone

### Problem: "Build Failed"
**Solution:** 
1. Run `quick_build.bat`
2. Select option 3 (Clean + Build + Install)

### Problem: "App Crashes"
**Solution:**
1. Run `quick_build.bat`
2. Select option 6 (View Logs)
3. Look for error messages

---

## 📂 Important Files (Don't Delete!)

### Helper Scripts
- `setup_google_signin.bat` - Google Sign-In wizard
- `quick_build.bat` - Build menu
- `get_sha1.ps1` - Get SHA-1 fingerprint
- `QUICK_REFERENCE.md` - Detailed commands

### Config Files
- `android/app/google-services.json` - Firebase config
- `lib/firebase_options.dart` - Firebase settings
- `pubspec.yaml` - App dependencies

---

## 🎓 Tutorial: Your First Build

**1. Connect your phone:**
   - Enable USB Debugging
   - Connect USB cable
   - Allow debugging on phone

**2. Build the app:**
   - Double-click `quick_build.bat`
   - Press `2` (Build + Install)
   - Wait 30-60 seconds

**3. Test on phone:**
   - Open RapidWarn app
   - Login with test credentials
   - Explore! 🎉

**That's it!**

---

## 📞 Need Help?

### Quick Commands
```powershell
# See all available commands
.\quick_build.bat

# Fix Google Sign-In
.\setup_google_signin.bat

# View detailed reference
notepad QUICK_REFERENCE.md
```

### Useful Links
- Firebase Console: https://console.firebase.google.com
- Flutter Docs: https://docs.flutter.dev

---

## 🎉 Tips for Success

1. **Always use `quick_build.bat`** - It's faster!
2. **Run Google Sign-In setup once** - Then forget about it
3. **Use Hot Reload (option 4)** - For quick UI changes
4. **Check device first** - Before building
5. **View logs if stuck** - Option 6 shows errors

---

## 📝 Daily Workflow

**Morning:**
1. Connect phone
2. Run `quick_build.bat` → Option 2
3. Test changes

**Making changes:**
1. Edit code
2. Run `quick_build.bat` → Option 2
3. Test on phone

**Google Sign-In issue?**
1. Run `setup_google_signin.bat`
2. Follow the steps
3. Done!

---

**That's all you need to know! 🚀**

*Keep `quick_build.bat` on your desktop for easy access!*
