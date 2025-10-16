-- Simplified users table creation for RapidWarn
-- This is a minimal version to fix the immediate error

-- Drop existing table if it exists (for clean restart)
DROP TABLE IF EXISTS public.users CASCADE;

-- Create users table
CREATE TABLE public.users (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    firebase_uid TEXT UNIQUE NOT NULL,
    email TEXT NOT NULL,
    display_name TEXT,
    role TEXT DEFAULT 'user',
    status TEXT DEFAULT 'active',
    phone TEXT,
    profile_image TEXT,
    email_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP WITH TIME ZONE,
    
    -- JSON fields for preferences
    emergency_contacts JSONB DEFAULT '[]'::jsonb,
    notification_preferences JSONB DEFAULT '{
        "push_notifications": true,
        "email_notifications": true,
        "emergency_alerts": true,
        "incident_updates": true
    }'::jsonb
);

-- Create basic indexes
CREATE INDEX idx_users_firebase_uid ON public.users(firebase_uid);
CREATE INDEX idx_users_email ON public.users(email);

-- Enable Row Level Security
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Basic policies
CREATE POLICY "Users can view own profile" ON public.users
    FOR SELECT USING (auth.uid()::text = firebase_uid);

CREATE POLICY "Users can update own profile" ON public.users
    FOR UPDATE USING (auth.uid()::text = firebase_uid);

CREATE POLICY "Allow user registration" ON public.users
    FOR INSERT WITH CHECK (true);

-- Create simple trigger for updated_at
CREATE OR REPLACE FUNCTION trigger_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_timestamp
    BEFORE UPDATE ON public.users
    FOR EACH ROW
    EXECUTE FUNCTION trigger_set_timestamp();