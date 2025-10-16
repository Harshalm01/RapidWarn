-- Create Supabase insights table for media uploads
-- Run this SQL in your Supabase SQL Editor: https://supabase.com/dashboard/project/YOUR_PROJECT/sql

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

-- Step 7: Create update trigger function
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 8: Create trigger to auto-update updated_at column
CREATE TRIGGER trigger_insights_updated_at
    BEFORE UPDATE ON public.insights
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- Step 9: Verify table creation (should return table info)
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns 
WHERE table_name = 'insights' 
AND table_schema = 'public'
ORDER BY ordinal_position;