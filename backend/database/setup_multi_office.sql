-- ============================================
-- GK EXPRESS - Multi-Office System Setup
-- ============================================

-- 1. Create Offices Table
CREATE TABLE IF NOT EXISTS offices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  country TEXT NOT NULL,
  country_code TEXT NOT NULL,
  address TEXT,
  phone TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Create Users Table
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  full_name TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('boss', 'agent')),
  office_id UUID REFERENCES offices(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. Update Parcels Table
ALTER TABLE parcels
ADD COLUMN IF NOT EXISTS origin_office_id UUID REFERENCES offices(id),
ADD COLUMN IF NOT EXISTS destination_office_id UUID REFERENCES offices(id),
ADD COLUMN IF NOT EXISTS created_by_user_id UUID REFERENCES users(id);

-- 4. Insert Default Offices
INSERT INTO offices (id, name, country, country_code, address, phone) VALUES
  ('11111111-1111-1111-1111-111111111111', 'Bureau Turquie', 'Turquie', 'TR', 'Istanbul', '+90-XXX-XXX-XXXX'),
  ('22222222-2222-2222-2222-222222222222', 'Bureau France', 'France', 'FR', 'Paris', '+33-X-XX-XX-XX-XX'),
  ('33333333-3333-3333-3333-333333333333', 'Bureau USA', 'États-Unis', 'US', 'New York', '+1-XXX-XXX-XXXX'),
  ('44444444-4444-4444-4444-444444444444', 'Bureau Canada', 'Canada', 'CA', 'Toronto', '+1-XXX-XXX-XXXX'),
  ('55555555-5555-5555-5555-555555555555', 'Bureau Chine', 'Chine', 'CN', 'Shanghai', '+86-XXX-XXXX-XXXX')
ON CONFLICT (id) DO NOTHING;

-- 5. Create Indexes
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_office ON users(office_id);
CREATE INDEX IF NOT EXISTS idx_parcels_origin_office ON parcels(origin_office_id);
CREATE INDEX IF NOT EXISTS idx_parcels_destination_office ON parcels(destination_office_id);
CREATE INDEX IF NOT EXISTS idx_parcels_created_by ON parcels(created_by_user_id);

-- 6. Enable Row Level Security (Optional - for future)
-- ALTER TABLE users ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE offices ENABLE ROW LEVEL SECURITY;
