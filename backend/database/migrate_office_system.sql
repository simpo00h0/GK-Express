-- Step 1: Add office columns to parcels table
ALTER TABLE parcels
ADD COLUMN IF NOT EXISTS origin_office_id UUID REFERENCES offices(id),
ADD COLUMN IF NOT EXISTS destination_office_id UUID REFERENCES offices(id),
ADD COLUMN IF NOT EXISTS paid_at_office_id UUID REFERENCES offices(id),
ADD COLUMN IF NOT EXISTS created_by_user_id UUID REFERENCES users(id);

-- Step 2: For EXISTING parcels, assign them to a default office
-- Replace 'YOUR_DEFAULT_OFFICE_ID' with an actual office ID from your offices table
-- You can get an office ID by running: SELECT id FROM offices LIMIT 1;

-- Option A: Assign all existing parcels to first office
UPDATE parcels
SET origin_office_id = (SELECT id FROM offices LIMIT 1),
    destination_office_id = (SELECT id FROM offices OFFSET 1 LIMIT 1)
WHERE origin_office_id IS NULL;

-- Option B: Or delete all existing test parcels and start fresh
-- DELETE FROM parcels;

-- Step 3: Update paid parcels
UPDATE parcels
SET paid_at_office_id = origin_office_id
WHERE is_paid = true AND paid_at_office_id IS NULL;

-- Step 4: Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_parcels_origin_office ON parcels(origin_office_id);
CREATE INDEX IF NOT EXISTS idx_parcels_destination_office ON parcels(destination_office_id);
CREATE INDEX IF NOT EXISTS idx_parcels_paid_at_office ON parcels(paid_at_office_id);
CREATE INDEX IF NOT EXISTS idx_parcels_created_by_user ON parcels(created_by_user_id);

-- Step 5: Verify the migration
SELECT 
    id, 
    receiver_name, 
    origin_office_id, 
    destination_office_id,
    created_at
FROM parcels
ORDER BY created_at DESC
LIMIT 5;
