-- Migration V2: Clean Architecture for Cross-Device Persistence
-- Separates static flashcard content from user progress

-- ============================================
-- 1. CLEAN FLASHCARDS TABLE (Static Content Only)
-- ============================================

-- Create new clean flashcards table
CREATE TABLE IF NOT EXISTS flashcards_clean (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  question TEXT NOT NULL,
  hint TEXT,
  solutions JSONB NOT NULL,
  data_structure_category TEXT NOT NULL,
  algorithm_pattern TEXT,
  predefined_difficulty TEXT NOT NULL,
  leetcode_number TEXT NOT NULL,
  tags TEXT[] DEFAULT '{}',
  companies TEXT[] DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_flashcards_clean_category ON flashcards_clean(data_structure_category);
CREATE INDEX IF NOT EXISTS idx_flashcards_clean_difficulty ON flashcards_clean(predefined_difficulty);
CREATE INDEX IF NOT EXISTS idx_flashcards_clean_leetcode ON flashcards_clean(leetcode_number);

-- ============================================
-- 2. USER PROGRESS TABLES
-- ============================================

-- User profiles and overall progress
CREATE TABLE IF NOT EXISTS user_profiles (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id),
  display_name TEXT,
  current_streak INTEGER DEFAULT 0,
  longest_streak INTEGER DEFAULT 0,
  total_cards_studied INTEGER DEFAULT 0,
  last_study_date TIMESTAMPTZ,
  settings JSONB DEFAULT '{
    "dailyGoal": 15,
    "sessionDuration": 30,
    "notificationTime": "09:00",
    "notificationsEnabled": true,
    "theme": "auto",
    "defaultLanguage": "python",
    "codeFontSize": 14,
    "cloudSyncEnabled": true,
    "spacedRepetitionAlgorithm": "SM-2"
  }'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  last_synced_at TIMESTAMPTZ DEFAULT NOW()
);

-- Individual flashcard progress per user
CREATE TABLE IF NOT EXISTS user_flashcard_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
  flashcard_id TEXT REFERENCES flashcards_clean(id),
  personal_difficulty INTEGER DEFAULT 2,
  review_count INTEGER DEFAULT 0,
  ease_factor DECIMAL(3,2) DEFAULT 2.5,
  interval_days INTEGER DEFAULT 1,
  next_review TIMESTAMPTZ,
  last_reviewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, flashcard_id)
);

-- Study sessions for history tracking
CREATE TABLE IF NOT EXISTS study_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
  mode TEXT NOT NULL,
  target_tags TEXT[],
  target_categories TEXT[],
  total_cards INTEGER DEFAULT 0,
  completed_cards INTEGER DEFAULT 0,
  duration_seconds INTEGER DEFAULT 0,
  started_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  session_results JSONB DEFAULT '{}'::jsonb
);

-- Sync metadata for conflict resolution
CREATE TABLE IF NOT EXISTS sync_metadata (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id),
  last_sync_timestamp TIMESTAMPTZ DEFAULT NOW(),
  device_id TEXT,
  sync_version INTEGER DEFAULT 1,
  conflict_resolution_needed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 3. INDEXES FOR PERFORMANCE
-- ============================================

-- User progress indexes
CREATE INDEX IF NOT EXISTS idx_user_flashcard_progress_user_id ON user_flashcard_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_user_flashcard_progress_flashcard_id ON user_flashcard_progress(flashcard_id);
CREATE INDEX IF NOT EXISTS idx_user_flashcard_progress_next_review ON user_flashcard_progress(next_review);
CREATE INDEX IF NOT EXISTS idx_user_flashcard_progress_last_reviewed ON user_flashcard_progress(last_reviewed_at);

-- Study sessions indexes
CREATE INDEX IF NOT EXISTS idx_study_sessions_user_id ON study_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_study_sessions_started_at ON study_sessions(started_at);

-- User profiles indexes
CREATE INDEX IF NOT EXISTS idx_user_profiles_last_study_date ON user_profiles(last_study_date);
CREATE INDEX IF NOT EXISTS idx_user_profiles_updated_at ON user_profiles(updated_at);

-- ============================================
-- 4. ROW LEVEL SECURITY (RLS)
-- ============================================

-- Enable RLS on all user tables
ALTER TABLE flashcards_clean ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_flashcard_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE study_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE sync_metadata ENABLE ROW LEVEL SECURITY;

-- Flashcards: Allow all users to read (static content)
CREATE POLICY "Allow all users to read flashcards" ON flashcards_clean
  FOR SELECT USING (true);

-- User profiles: Users can only access their own data
CREATE POLICY "Users can manage their own profile" ON user_profiles
  FOR ALL USING (auth.uid() = user_id);

-- User progress: Users can only access their own progress
CREATE POLICY "Users can manage their own progress" ON user_flashcard_progress
  FOR ALL USING (auth.uid() = user_id);

-- Study sessions: Users can only access their own sessions
CREATE POLICY "Users can manage their own sessions" ON study_sessions
  FOR ALL USING (auth.uid() = user_id);

-- Sync metadata: Users can only access their own sync data
CREATE POLICY "Users can manage their own sync metadata" ON sync_metadata
  FOR ALL USING (auth.uid() = user_id);

-- ============================================
-- 5. TRIGGERS FOR AUTOMATIC TIMESTAMPS
-- ============================================

-- Create or replace the timestamp update function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Add triggers for automatic timestamp updates
CREATE TRIGGER update_user_profiles_updated_at 
  BEFORE UPDATE ON user_profiles 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_flashcard_progress_updated_at 
  BEFORE UPDATE ON user_flashcard_progress 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_sync_metadata_updated_at 
  BEFORE UPDATE ON sync_metadata 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 6. DATA MIGRATION FROM OLD SCHEMA
-- ============================================

-- Extract clean flashcard content from existing flashcards table
-- NOTE: This should be run after validating the structure
/*
INSERT INTO flashcards_clean (
  id, title, question, hint, solutions, 
  data_structure_category, algorithm_pattern, 
  predefined_difficulty, leetcode_number, tags, companies
)
SELECT 
  id,
  json->>'title' as title,
  json->>'question' as question,
  json->>'hint' as hint,
  json->'solutions' as solutions,
  json->>'dataStructureCategory' as data_structure_category,
  json->>'algorithmPattern' as algorithm_pattern,
  json->>'predefinedDifficulty' as predefined_difficulty,
  json->>'leetcodeNumber' as leetcode_number,
  CASE 
    WHEN json->'tags' IS NOT NULL THEN 
      ARRAY(SELECT jsonb_array_elements_text(json->'tags'))
    ELSE ARRAY[]::TEXT[]
  END as tags,
  CASE 
    WHEN json->'companies' IS NOT NULL THEN 
      ARRAY(SELECT jsonb_array_elements_text(json->'companies'))
    ELSE ARRAY[]::TEXT[]
  END as companies
FROM flashcards
WHERE json IS NOT NULL;
*/

-- ============================================
-- 7. VIEWS FOR EASY QUERYING
-- ============================================

-- View to combine flashcard content with user progress
CREATE OR REPLACE VIEW user_flashcards AS
SELECT 
  fc.id,
  fc.title,
  fc.question,
  fc.hint,
  fc.solutions,
  fc.data_structure_category,
  fc.algorithm_pattern,
  fc.predefined_difficulty,
  fc.leetcode_number,
  fc.tags,
  fc.companies,
  fc.created_at,
  ufp.user_id,
  COALESCE(ufp.personal_difficulty, 2) as personal_difficulty,
  COALESCE(ufp.review_count, 0) as review_count,
  COALESCE(ufp.ease_factor, 2.5) as ease_factor,
  COALESCE(ufp.interval_days, 1) as interval_days,
  ufp.next_review,
  ufp.last_reviewed_at,
  ufp.updated_at as progress_updated_at
FROM flashcards_clean fc
LEFT JOIN user_flashcard_progress ufp ON fc.id = ufp.flashcard_id
WHERE ufp.user_id = auth.uid() OR ufp.user_id IS NULL;

-- View for cards due for review
CREATE OR REPLACE VIEW cards_due_for_review AS
SELECT *
FROM user_flashcards
WHERE user_id = auth.uid()
  AND (next_review IS NULL OR next_review <= NOW());

-- GRANTS (if needed for service role access)
-- GRANT ALL ON ALL TABLES IN SCHEMA public TO service_role;
-- GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO service_role;
