-- Create parcels table in Supabase
CREATE TABLE IF NOT EXISTS parcels (
  id UUID PRIMARY KEY,
  sender_name TEXT NOT NULL,
  sender_phone TEXT,
  receiver_name TEXT NOT NULL,
  receiver_phone TEXT,
  destination TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'created',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create index on created_at for faster sorting
CREATE INDEX IF NOT EXISTS parcels_created_at_idx ON parcels(created_at DESC);

-- Create index on status for faster filtering
CREATE INDEX IF NOT EXISTS parcels_status_idx ON parcels(status);
