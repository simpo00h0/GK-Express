-- ============================================
-- GK EXPRESS - Système de Messagerie Inter-Bureaux
-- ============================================

-- Créer la table messages
CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  from_office_id UUID NOT NULL REFERENCES offices(id) ON DELETE CASCADE,
  to_office_id UUID NOT NULL REFERENCES offices(id) ON DELETE CASCADE,
  from_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  subject TEXT NOT NULL,
  content TEXT NOT NULL,
  related_parcel_id UUID REFERENCES parcels(id) ON DELETE SET NULL,
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Créer les index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_messages_from_office ON messages(from_office_id);
CREATE INDEX IF NOT EXISTS idx_messages_to_office ON messages(to_office_id);
CREATE INDEX IF NOT EXISTS idx_messages_from_user ON messages(from_user_id);
CREATE INDEX IF NOT EXISTS idx_messages_related_parcel ON messages(related_parcel_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_read_at ON messages(read_at);

-- Index composite pour les requêtes de conversation
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON messages(from_office_id, to_office_id, created_at DESC);

-- Fonction pour mettre à jour updated_at automatiquement
CREATE OR REPLACE FUNCTION update_messages_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour mettre à jour updated_at
CREATE TRIGGER trigger_update_messages_updated_at
  BEFORE UPDATE ON messages
  FOR EACH ROW
  EXECUTE FUNCTION update_messages_updated_at();

-- Commentaires pour la documentation
COMMENT ON TABLE messages IS 'Messages entre bureaux pour la communication inter-bureaux';
COMMENT ON COLUMN messages.from_office_id IS 'Bureau expéditeur du message';
COMMENT ON COLUMN messages.to_office_id IS 'Bureau destinataire du message';
COMMENT ON COLUMN messages.from_user_id IS 'Utilisateur qui a envoyé le message';
COMMENT ON COLUMN messages.related_parcel_id IS 'Colis lié au message (optionnel)';
COMMENT ON COLUMN messages.read_at IS 'Date de lecture du message (NULL si non lu)';

