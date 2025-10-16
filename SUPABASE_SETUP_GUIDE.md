# Supabase Database Setup Guide

## Error Fixed: `relation "public.users" does not exist`

The error occurs because the Supabase database doesn't have the required `users` table yet. Here's how to fix it:

## 🚀 Quick Fix Options

### Option 1: Using Supabase Dashboard (Recommended)

1. **Go to your Supabase project dashboard**
   - Visit: https://supabase.com/dashboard
   - Select your RapidWarn project

2. **Open SQL Editor**
   - Click "SQL Editor" in the left sidebar
   - Click "New query"

3. **Run the Migration**
   - Copy the entire content from `supabase/migrations/001_create_users_table.sql`
   - Paste it into the SQL editor
   - Click "Run" button

### Option 2: Using Supabase CLI

```bash
# Install Supabase CLI (if not installed)
npm install -g supabase

# Navigate to your project
cd c:\flutter_projects\app\rapidwarn

# Login to Supabase
supabase login

# Link your project (replace with your project ID)
supabase link --project-ref YOUR_PROJECT_ID

# Apply migrations
supabase db push
```

### Option 3: Quick Fix for SQL Error

If you're getting `ERROR: 42601: syntax error at or near "DEFAULT NOW"`, use the simplified migration:

```sql
-- Quick fix - Create basic users table
CREATE TABLE public.users (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    firebase_uid TEXT UNIQUE NOT NULL,
    email TEXT NOT NULL,
    display_name TEXT,
    role TEXT DEFAULT 'user',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_firebase_uid ON public.users(firebase_uid);
```

**Or use the pre-fixed migration:** `supabase/migrations/002_simple_users_table.sql`

## 🔧 What the Migration Creates

The full migration (`001_create_users_table.sql`) creates:

1. **`users` table** - Main user data from Firebase Auth
2. **`user_analytics` table** - User activity tracking
3. **`incident_locations` table** - Geographic incident data
4. **Indexes** - For better query performance
5. **Row Level Security (RLS)** - Data access protection
6. **Policies** - User permissions and admin access

## ✅ Verify the Fix

After running the migration:

1. **Test the sync button** in Admin Dashboard
2. **Check console output** - should show:
   ```
   ✅ Synced user example@email.com from Supabase to Firestore
   ```
3. **Register a new user** - should sync to both databases
4. **No more PostgreSQL errors** in the console

## 🛡️ Security Features Included

- **Row Level Security**: Users can only access their own data
- **Admin Policies**: Admins can view all users and analytics
- **Secure Registration**: New users can create accounts safely
- **Data Isolation**: User analytics are private to each user

## 📊 Database Schema Overview

```
users (Main user table)
├── firebase_uid (Primary key from Firebase)
├── email
├── display_name
├── role (user/admin/moderator)
├── emergency_contacts (JSON)
└── notification_preferences (JSON)

user_analytics (Activity tracking)
├── user_id → users.firebase_uid
├── action_type (login, report, etc.)
├── incident_id
└── metadata (JSON)

incident_locations (Geographic data)
├── incident_id
├── user_id → users.firebase_uid
├── latitude, longitude
└── address information
```

## 🐛 Troubleshooting

**If you still see errors after migration:**

1. **Check project permissions** - Ensure you're the project owner
2. **Verify project ID** - Make sure you're connected to the right project
3. **Check RLS policies** - May need to temporarily disable for testing
4. **Clear app cache** - Restart the Flutter app

**For RLS issues during development:**
```sql
-- Temporarily disable RLS for testing (NOT for production)
ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;
```

## 📞 Support

If you encounter issues:
1. Check the Supabase dashboard logs
2. Verify your project API keys in `firebase_options.dart`
3. Ensure your Supabase URL is correct in the app configuration

The migration includes comprehensive error handling, so your app will continue working even if some features aren't available yet.