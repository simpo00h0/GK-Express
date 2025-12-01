-- Add price and payment status columns to parcels table
ALTER TABLE parcels 
ADD COLUMN IF NOT EXISTS price DECIMAL(10, 2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS is_paid BOOLEAN DEFAULT false;

-- Create index on is_paid for faster filtering
CREATE INDEX IF NOT EXISTS parcels_is_paid_idx ON parcels(is_paid);
