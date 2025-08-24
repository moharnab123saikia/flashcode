-- Create flashcards table
CREATE TABLE IF NOT EXISTS flashcards (
  id TEXT PRIMARY KEY,
  json JSONB NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_flashcards_created_at ON flashcards(created_at);

-- Add RLS policies
ALTER TABLE flashcards ENABLE ROW LEVEL SECURITY;

-- Allow anonymous users to read flashcards
CREATE POLICY "Allow anonymous read" ON flashcards
  FOR SELECT
  USING (true);

-- Allow anonymous users to insert/update flashcards (for development)
CREATE POLICY "Allow anonymous write" ON flashcards
  FOR ALL
  USING (true);

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_flashcards_updated_at BEFORE UPDATE
  ON flashcards FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
