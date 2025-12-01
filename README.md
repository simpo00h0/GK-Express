# GK Express - Système de Gestion de Colis International

Application multiplateforme de gestion de transit international pour colis avec système multi-bureaux.

## 🌍 Bureaux
- 🇹🇷 Turquie (Istanbul)
- 🇫🇷 France (Paris)
- 🇺🇸 USA (New York)
- 🇨🇦 Canada (Toronto)
- 🇨🇳 Chine (Shanghai)

## 🚀 Technologies

### Frontend
- **Flutter** (Desktop Windows/Mac, Mobile iOS/Android)
- Material Design 3
- HTTP pour API calls

### Backend
- **Node.js** + Express
- **Supabase** (PostgreSQL)
- JWT Authentication
- Bcrypt pour les mots de passe

## 📦 Fonctionnalités Implémentées

### ✅ Gestion des Colis
- Création de colis avec QR code
- Suivi des statuts (Créé, En Transit, Arrivé, Livré, Problème)
- Recherche et filtrage
- Prix et statut de paiement

### ✅ Statistiques & Dashboard
- Vue d'ensemble des colis
- Chiffre d'affaires (total, payé, impayé)
- Filtres par période (aujourd'hui, semaine, mois, personnalisé)

### ✅ Système Multi-Bureaux (Backend)
- 5 bureaux internationaux
- Authentification JWT
- Rôles : Boss (PDG) et Agent
- Gestion des utilisateurs

## 🔧 Installation

### Backend
```bash
cd backend
npm install
# Créer un fichier .env avec :
# PORT=3000
# SUPABASE_URL=your_url
# SUPABASE_SERVICE_ROLE_KEY=your_key
# JWT_SECRET=your_secret
node server.js
```

### Frontend (Flutter)
```bash
cd app
flutter pub get
flutter run -d windows
```

## 📊 Base de Données

### Tables
- `offices` - Bureaux internationaux
- `users` - Utilisateurs (Boss/Agent)
- `parcels` - Colis avec origine/destination

Voir `backend/database/setup_multi_office.sql` pour le schéma complet.

## 🔐 API Endpoints

### Authentification
- `POST /api/auth/register` - Inscription
- `POST /api/auth/login` - Connexion
- `GET /api/auth/me` - Profil utilisateur
- `GET /api/auth/users` - Liste users (Boss only)

### Bureaux
- `GET /api/offices` - Liste des bureaux
- `GET /api/offices/:id` - Détails d'un bureau

### Colis
- `GET /api/parcels` - Liste des colis
- `POST /api/parcels` - Créer un colis
- `PATCH /api/parcels/:id/status` - Mettre à jour le statut

## 🎯 Prochaines Étapes

- [ ] Écrans d'authentification Flutter
- [ ] Sélection bureau origine/destination
- [ ] Dashboard avec filtres par bureau
- [ ] Gestion des utilisateurs (Boss)
- [ ] Application mobile iOS/Android
- [ ] Notifications en temps réel

## 👨‍💻 Développement

Projet développé pour GK Express - Transit International de Colis

---

**Note** : Ce projet est en cours de développement actif.
