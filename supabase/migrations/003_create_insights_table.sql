-- Create insights table for media uploads and disaster reports
-- This table stores user-submitted media and location data for ML classification

CREATE TABLE public.insights (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    media_url TEXT NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    processed BOOLEAN DEFAULT false,
    disaster_type TEXT,
    intensity TEXT,
    description TEXT,
    uploader_id TEXT,
    upload_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better query performance
CREATE INDEX idx_insights_uploader_id ON public.insights(uploader_id);
CREATE INDEX idx_insights_location ON public.insights(latitude, longitude);
CREATE INDEX idx_insights_disaster_type ON public.insights(disaster_type);
CREATE INDEX idx_insights_processed ON public.insights(processed);
CREATE INDEX idx_insights_created_at ON public.insights(created_at);

-- Enable Row Level Security
ALTER TABLE public.insights ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Allow users to insert their own data
CREATE POLICY "Users can insert own insights" ON public.insights
    FOR INSERT WITH CHECK (auth.uid()::text = uploader_id);

-- Allow users to view their own insights
CREATE POLICY "Users can view own insights" ON public.insights
    FOR SELECT USING (auth.uid()::text = uploader_id);

-- Allow users to update their own insights
CREATE POLICY "Users can update own insights" ON public.insights
    FOR UPDATE USING (auth.uid()::text = uploader_id);

-- Allow admins to view all insights (for admin dashboard)
CREATE POLICY "Admins can view all insights" ON public.insights
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE firebase_uid = auth.uid()::text 
            AND role = 'admin'
        )
    );

-- Allow public read access for emergency services (adjust as needed)
CREATE POLICY "Public can view processed insights" ON public.insights
    FOR SELECT USING (processed = true);

-- Create trigger for updated_at
CREATE OR REPLACE FUNCTION trigger_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_timestamp_insights
    BEFORE UPDATE ON public.insights
    FOR EACH ROW
    EXECUTE FUNCTION trigger_set_timestamp();

-- Create storage bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('media', 'media', true)
ON CONFLICT (id) DO NOTHING;

-- Storage RLS policies for media bucket
CREATE POLICY "Users can upload media" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'media' AND auth.role() = 'authenticated');

CREATE POLICY "Anyone can view media" ON storage.objects
    FOR SELECT USING (bucket_id = 'media');

CREATE POLICY "Users can update own media" ON storage.objects
    FOR UPDATE USING (bucket_id = 'media' AND auth.uid()::text = owner);

CREATE POLICY "Users can delete own media" ON storage.objects
    FOR DELETE USING (bucket_id = 'media' AND auth.uid()::text = owner);