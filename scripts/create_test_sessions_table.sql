-- Create test_sessions table to track user attempts and results
CREATE TABLE IF NOT EXISTS public.test_sessions (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID REFERENCES auth.users NOT NULL,
  start_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  score INTEGER NOT NULL,
  total_questions INTEGER NOT NULL,
  category_scores JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create index for faster user-specific queries
CREATE INDEX IF NOT EXISTS test_sessions_user_id_idx ON public.test_sessions (user_id);

-- Enable Row Level Security
ALTER TABLE public.test_sessions ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view their own test sessions" 
ON public.test_sessions
FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own test sessions"
ON public.test_sessions
FOR INSERT WITH CHECK (auth.uid() = user_id);