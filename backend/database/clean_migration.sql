-- MIGRATION COMPLÈTE : Système Multi-Bureaux
-- ATTENTION : Ce script supprime TOUS les colis existants !

-- Step 1: Supprimer tous les anciens colis
DELETE FROM parcels;

-- Step 2: Ajouter les colonnes office au tableau parcels
ALTER TABLE parcels
ADD COLUMN IF NOT EXISTS origin_office_id UUID REFERENCES offices(id),
ADD COLUMN IF NOT EXISTS destination_office_id UUID REFERENCES offices(id),
ADD COLUMN IF NOT EXISTS paid_at_office_id UUID REFERENCES offices(id),
ADD COLUMN IF NOT EXISTS created_by_user_id UUID REFERENCES users(id);

-- Step 3: Rendre les colonnes office obligatoires pour les nouveaux colis
-- (On ne peut pas les rendre NOT NULL car il pourrait y avoir des anciens colis)

-- Step 4: Créer des index pour la performance
CREATE INDEX IF NOT EXISTS idx_parcels_origin_office ON parcels(origin_office_id);
CREATE INDEX IF NOT EXISTS idx_parcels_destination_office ON parcels(destination_office_id);
CREATE INDEX IF NOT EXISTS idx_parcels_paid_at_office ON parcels(paid_at_office_id);
CREATE INDEX IF NOT EXISTS idx_parcels_created_by_user ON parcels(created_by_user_id);

-- Step 5: Vérifier que les tables sont prêtes
SELECT 'Migration terminée !' as status;
SELECT COUNT(*) as total_parcels FROM parcels;
SELECT COUNT(*) as total_offices FROM offices;
SELECT COUNT(*) as total_users FROM users;
