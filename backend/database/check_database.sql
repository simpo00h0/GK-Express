-- Vérifier l'état actuel de la base de données

-- 1. Vérifier les colonnes de la table parcels
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'parcels'
ORDER BY ordinal_position;

-- 2. Vérifier les colis existants et leurs bureaux
SELECT 
    id,
    receiver_name,
    destination,
    origin_office_id,
    destination_office_id,
    paid_at_office_id,
    created_at
FROM parcels
ORDER BY created_at DESC;

-- 3. Compter les colis par bureau d'origine
SELECT 
    o.name as office_name,
    COUNT(p.id) as total_parcels
FROM offices o
LEFT JOIN parcels p ON p.origin_office_id = o.id
GROUP BY o.id, o.name;

-- 4. Vérifier les utilisateurs et leurs bureaux
SELECT 
    u.id,
    u.full_name,
    u.email,
    u.role,
    o.name as office_name
FROM users u
LEFT JOIN offices o ON u.office_id = o.id;

-- 5. Compter les colis sans bureau assigné
SELECT 
    COUNT(*) as parcels_without_office
FROM parcels
WHERE origin_office_id IS NULL OR destination_office_id IS NULL;
