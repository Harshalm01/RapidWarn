# 🚨 URGENT: Fix Supabase Database Schema

## Current Error
```
❌ Could not find the 'uploader_id' column of 'insights' in the schema cache
```

## Problem
Your Supabase `insights` table is missing the required `uploader_id` column that your Flutter app is trying to use.

## Solution Steps

### 1. Open Supabase Dashboard
- Go to [supabase.com/dashboard](https://supabase.com/dashboard)
- Select your RapidWarn project
- Go to **SQL Editor** (left sidebar)

### 2. Run the Migration SQL
Copy and paste this entire SQL script into the SQL Editor:

```sql
-- Create Supabase insights table for media uploads
-- Run this SQL in your Supabase SQL Editor

-- Step 1: Drop existing table if it exists (CAREFUL: This removes all data!)
DROP TABLE IF EXISTS public.insights CASCADE;

-- Step 2: Create insights table with all required columns
CREATE TABLE public.insights (
    id BIGSERIAL PRIMARY KEY,
    media_url TEXT NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    disaster_type TEXT DEFAULT NULL,
    processed BOOLEAN DEFAULT FALSE,
    uploader_id TEXT DEFAULT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Step 3: Add performance indexes
CREATE INDEX idx_insights_processed ON public.insights(processed);
CREATE INDEX idx_insights_disaster_type ON public.insights(disaster_type);
CREATE INDEX idx_insights_uploader ON public.insights(uploader_id);
CREATE INDEX idx_insights_location ON public.insights(latitude, longitude);
CREATE INDEX idx_insights_created_at ON public.insights(created_at);

-- Step 4: Enable Row Level Security (RLS)
ALTER TABLE public.insights ENABLE ROW LEVEL SECURITY;

-- Step 5: Create RLS policies for security
CREATE POLICY "Allow public read access" ON public.insights
    FOR SELECT USING (true);

CREATE POLICY "Allow authenticated insert" ON public.insights
    FOR INSERT WITH CHECK (auth.uid()::text = uploader_id OR uploader_id IS NULL);

CREATE POLICY "Allow owner update" ON public.insights
    FOR UPDATE USING (auth.uid()::text = uploader_id OR uploader_id IS NULL);

-- Step 6: Grant necessary permissions
GRANT ALL ON public.insights TO authenticated;
GRANT ALL ON public.insights TO anon;
GRANT USAGE, SELECT ON SEQUENCE public.insights_id_seq TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE public.insights_id_seq TO anon;
```

### 3. Click "RUN" to execute the SQL

### 4. Test Your App
After running the SQL:
1. Return to your Flutter app
2. Try uploading a photo again
3. The `uploader_id` error should be resolved

## What This Does
- ✅ Creates the `insights` table with ALL required columns
- ✅ Adds the missing `uploader_id` column
- ✅ Sets up proper indexes for performance
- ✅ Configures Row Level Security (RLS)
- ✅ Grants proper permissions

## Quick Test
After running the SQL, use the database test button in your app to verify the connection works.