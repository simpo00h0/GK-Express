-- ============================================
-- GK EXPRESS - Parcel Status History Table
-- ============================================
-- Table pour l'historique des changements de statut des colis
-- Permet la traçabilité complète de tous les changements

-- 1. Create Parcel Status History Table
CREATE TABLE IF NOT EXISTS parcel_status_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  parcel_id UUID NOT NULL REFERENCES parcels(id) ON DELETE CASCADE,
  old_status TEXT,
  new_status TEXT NOT NULL,
  changed_by_user_id UUID REFERENCES users(id),
  changed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  notes TEXT,
  office_id UUID REFERENCES offices(id) -- Bureau où le changement a été effectué
);

-- 2. Create Indexes for Performance
CREATE INDEX IF NOT EXISTS idx_status_history_parcel ON parcel_status_history(parcel_id);
CREATE INDEX IF NOT EXISTS idx_status_history_changed_at ON parcel_status_history(changed_at DESC);
CREATE INDEX IF NOT EXISTS idx_status_history_user ON parcel_status_history(changed_by_user_id);
CREATE INDEX IF NOT EXISTS idx_status_history_office ON parcel_status_history(office_id);

-- 3. Add comment for documentation
COMMENT ON TABLE parcel_status_history IS 'Historique complet de tous les changements de statut des colis pour audit et traçabilité';

-- 4. Create a function to automatically log status changes (optional - can be called from application)
-- This is a helper function, but we'll handle it in the application code for more control
COMMENT ON COLUMN parcel_status_history.old_status IS 'Statut précédent (NULL pour le premier statut)';
COMMENT ON COLUMN parcel_status_history.new_status IS 'Nouveau statut';
COMMENT ON COLUMN parcel_status_history.changed_by_user_id IS 'Utilisateur qui a effectué le changement';
COMMENT ON COLUMN parcel_status_history.notes IS 'Notes optionnelles sur le changement';
COMMENT ON COLUMN parcel_status_history.office_id IS 'Bureau où le changement a été effectué';

