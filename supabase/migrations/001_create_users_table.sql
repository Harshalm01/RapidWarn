-- Create users table for RapidWarn application
-- This table stores user information synced from Firebase Auth

CREATE TABLE IF NOT EXISTS public.users (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    firebase_uid TEXT UNIQUE NOT NULL,
    email TEXT NOT NULL,
    display_name TEXT,
    role TEXT DEFAULT 'user' CHECK (role IN ('user', 'admin', 'moderator')),
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'suspended')),
    phone TEXT,
    profile_image TEXT,
    email_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP WITH TIME ZONE,
    
    -- Additional emergency-related fields
    emergency_contacts JSONB DEFAULT '[]'::jsonb,
    notification_preferences JSONB DEFAULT '{
        "push_notifications": true,
        "email_notifications": true,
        "emergency_alerts": true,
        "incident_updates": true
    }'::jsonb,
    location_preferences JSONB DEFAULT '{
        "share_location": true,
        "auto_location": true,
        "location_radius_km": 50
    }'::jsonb
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_firebase_uid ON public.users(firebase_uid);
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON public.users(role);
CREATE INDEX IF NOT EXISTS idx_users_status ON public.users(status);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON public.users(created_at);

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON public.users 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Enable Row Level Security (RLS)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Create policies for RLS
-- Users can read their own data
CREATE POLICY "Users can view own profile" ON public.users
    FOR SELECT USING (auth.uid()::text = firebase_uid);

-- Users can update their own data
CREATE POLICY "Users can update own profile" ON public.users
    FOR UPDATE USING (auth.uid()::text = firebase_uid);

-- Admins can view all users
CREATE POLICY "Admins can view all users" ON public.users
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE firebase_uid = auth.uid()::text 
            AND role = 'admin'
        )
    );

-- Allow inserts for new user registration
CREATE POLICY "Allow user registration" ON public.users
    FOR INSERT WITH CHECK (true);

-- Create user analytics table for tracking user actions
CREATE TABLE IF NOT EXISTS public.user_analytics (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id TEXT REFERENCES public.users(firebase_uid) ON DELETE CASCADE,
    action_type TEXT NOT NULL, -- 'login', 'logout', 'report_incident', 'view_incident', 'share_incident'
    incident_id TEXT,
    metadata JSONB DEFAULT '{}'::jsonb,
    session_id TEXT,
    ip_address INET,
    user_agent TEXT,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for analytics
CREATE INDEX IF NOT EXISTS idx_user_analytics_user_id ON public.user_analytics(user_id);
CREATE INDEX IF NOT EXISTS idx_user_analytics_action_type ON public.user_analytics(action_type);
CREATE INDEX IF NOT EXISTS idx_user_analytics_timestamp ON public.user_analytics(timestamp);

-- Enable RLS for analytics
ALTER TABLE public.user_analytics ENABLE ROW LEVEL SECURITY;

-- Users can only see their own analytics
CREATE POLICY "Users can view own analytics" ON public.user_analytics
    FOR SELECT USING (user_id = auth.uid()::text);

-- Admins can view all analytics
CREATE POLICY "Admins can view all analytics" ON public.user_analytics
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE firebase_uid = auth.uid()::text 
            AND role = 'admin'
        )
    );

-- Allow inserts for analytics tracking
CREATE POLICY "Allow analytics tracking" ON public.user_analytics
    FOR INSERT WITH CHECK (true);

-- Create incident locations table for geographic analysis
CREATE TABLE IF NOT EXISTS public.incident_locations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    incident_id TEXT NOT NULL,
    user_id TEXT REFERENCES public.users(firebase_uid) ON DELETE CASCADE,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    accuracy REAL,
    altitude REAL,
    heading REAL,
    speed REAL,
    address TEXT,
    city TEXT,
    state TEXT,
    country TEXT,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create spatial indexes
CREATE INDEX IF NOT EXISTS idx_incident_locations_coordinates 
    ON public.incident_locations USING btree(latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_incident_locations_incident_id 
    ON public.incident_locations(incident_id);
CREATE INDEX IF NOT EXISTS idx_incident_locations_timestamp 
    ON public.incident_locations(timestamp);

-- Enable RLS for incident locations
ALTER TABLE public.incident_locations ENABLE ROW LEVEL SECURITY;

-- Public read access for incident locations (for emergency response)
CREATE POLICY "Public read access for incident locations" ON public.incident_locations
    FOR SELECT USING (true);

-- Users can insert their own incident locations
CREATE POLICY "Users can insert incident locations" ON public.incident_locations
    FOR INSERT WITH CHECK (user_id = auth.uid()::text);

-- Comment explaining the schema
COMMENT ON TABLE public.users IS 'User accounts synchronized from Firebase Auth with additional emergency app features';
COMMENT ON TABLE public.user_analytics IS 'User activity tracking for analytics and audit purposes';
COMMENT ON TABLE public.incident_locations IS 'Geographic data for incidents reported by users';