-- Add payment tracking field to parcels table
ALTER TABLE parcels
ADD COLUMN IF NOT EXISTS paid_at_office_id UUID REFERENCES offices(id);

-- Update existing paid parcels to set paid_at_office_id = origin_office_id
UPDATE parcels
SET paid_at_office_id = origin_office_id
WHERE is_paid = true AND paid_at_office_id IS NULL;

-- Create index for performance
CREATE INDEX IF NOT EXISTS idx_parcels_paid_at_office ON parcels(paid_at_office_id);
