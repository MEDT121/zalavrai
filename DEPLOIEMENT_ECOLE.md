# SchoolSafe v3.0 — Guide de déploiement école
### Manuel opérateur · Lancement d'une nouvelle école abonnée

---

## Vue d'ensemble

SchoolSafe est une application multi-école où **chaque école possède son propre environnement isolé** :

```
┌─────────────────────────────────────────────────────────┐
│                   OPÉRATEUR (toi)                       │
│   admin.html  ←→  Supabase Central                      │
│                   ├── table schools  (toutes les écoles)│
│                   ├── table card_orders                 │
│                   └── table school_announcements        │
└─────────────────────────────────────────────────────────┘
         │                    │
   École A                  École B
   GitHub A                 GitHub B
   index.html               index.html
   Supabase A               Supabase B
   (données A)              (données B)
```

**Durée estimée d'un déploiement complet : 45 à 90 minutes**

---

## Prérequis opérateur

Avant de commencer, tu dois avoir accès à :

- [ ] Ton compte **GitHub** (organisateur — pour créer le fork de l'école)
- [ ] L'interface **admin.html** connectée (Supabase central configuré)
- [ ] Un compte **Supabase** (gratuit suffit pour une école moyenne)
- [ ] Le fichier `supabase_setup.sql` (disponible dans le repo SchoolSafe)
- [ ] Les informations de l'école : nom officiel, adresse, téléphone, email, année scolaire

---

## ÉTAPE 1 — Créer le projet Supabase de l'école

### 1.1 Créer le projet

1. Aller sur [supabase.com](https://supabase.com) → **New project**
2. Remplir :
   - **Organization** : ton organisation ou en créer une pour l'école
   - **Project name** : `schoolsafe-nom-ecole` (ex: `schoolsafe-le-sage`)
   - **Database password** : générer un mot de passe fort → **noter le**
   - **Region** : choisir la région la plus proche (ex: `eu-central-1` pour Afrique/Europe)
3. Cliquer **Create new project** → attendre 2 à 3 minutes

### 1.2 Récupérer les clés

Dans le projet Supabase créé :
- Aller dans **Settings → API**
- Copier et noter :
  - **Project URL** → `https://XXXXXXXX.supabase.co`
  - **anon / public key** → `eyJhbGci...` (longue chaîne)

> ⚠️ **Ne jamais utiliser la `service_role` key dans l'application.** Uniquement `anon`.

### 1.3 Configurer l'allowlist des domaines

Dans Supabase :
- **Settings → API → Allowed Origins (CORS)**
- Ajouter l'URL GitHub Pages de l'école :
  - Format : `https://NOM-GITHUB.github.io`
  - Si domaine personnalisé : `https://www.nom-ecole.com`

> Sans cette étape, l'application sera bloquée par le CORS.

---

## ÉTAPE 2 — Initialiser les tables (base de données)

### 2.1 Exécuter le script SQL

1. Dans le projet Supabase → **SQL Editor** → **New Query**
2. Coller **l'intégralité** du fichier `supabase_setup.sql`
3. Cliquer **Run**
4. Vérifier que la dernière ligne affiche :
   ```
   SchoolSafe v3.0 — 40 tables configurées ✅
   ```

Ce script crée les 40 tables nécessaires, active Row Level Security, configure les politiques d'accès (anon), et crée les index de performance. Il est **safe à relancer** en cas d'erreur (IF NOT EXISTS partout).

### 2.2 Créer la ligne de settings initiale

Dans le SQL Editor, exécuter :

```sql
INSERT INTO settings (id, data)
VALUES ('main', '{
  "school": {
    "name": "NOM OFFICIEL DE L ECOLE",
    "name_en": "ENGLISH NAME IF ANY",
    "address": "Adresse complète, Kinshasa",
    "phone": "+243 XXX XXX XXX",
    "email": "direction@ecole.cd"
  },
  "year": "2025-2026",
  "currentTrimestre": "T1",
  "fees": {"T1": 150, "T2": 150, "T3": 150},
  "license_key": ""
}')
ON CONFLICT (id) DO NOTHING;
```

> Remplacer les valeurs par les vraies informations de l'école.

### 2.3 Configurer le Storage (photos élèves)

1. Dans Supabase → **Storage** → **New bucket**
2. Nom du bucket : `photos`
3. Cocher **Public bucket** (les photos doivent être accessibles dans l'app)
4. Dans **Storage → Policies**, ajouter une politique anon :
   ```sql
   -- Autoriser upload et lecture pour anon
   CREATE POLICY "anon_storage" ON storage.objects
   FOR ALL TO anon USING (bucket_id = 'photos')
   WITH CHECK (bucket_id = 'photos');
   ```

---

## ÉTAPE 3 — Enregistrer l'école dans le Supabase central

Cette étape lie l'école au système central (licences, commandes de cartes).

### 3.1 Via admin.html

1. Ouvrir `admin.html` → onglet **Écoles** → **Ajouter une école**
2. Remplir :
   - **Nom de l'école** : nom officiel (doit correspondre exactement à celui dans settings)
   - **Supabase URL** : l'URL copiée à l'étape 1.2
   - **Supabase Anon Key** : la clé copiée à l'étape 1.2
   - **License Key** : générer une clé unique (voir format ci-dessous)
   - **Statut** : `active`
   - **Date d'expiration** : date de fin d'abonnement
   - **Fonctionnalités** : sélectionner les modules activés

### 3.2 Format de la license key

Utiliser ce format pour garder une cohérence :
```
SS-ANNEE-INITIALES-XXXX
Exemple : SS-2025-LS-4892
```
- `SS` = SchoolSafe
- `ANNEE` = année de souscription
- `INITIALES` = 2-3 lettres du nom de l'école
- `XXXX` = 4 chiffres aléatoires

### 3.3 Fonctionnalités disponibles (features JSON)

Dans le champ **features** de la fiche école, les modules activables :

| Clé | Module |
|-----|--------|
| `cards` | Système de cartes élèves |
| `cantine` | Gestion cantine |
| `medical` | Dossiers médicaux |
| `transport` | Gestion transport |
| `site` | Site web de l'école |

Exemple : `{"cards": true, "site": true}`

---

## ÉTAPE 4 — Créer le repo GitHub de l'école

### 4.1 Fork du repo principal

1. Aller sur le repo GitHub de SchoolSafe (ton repo principal)
2. Cliquer **Fork**
3. **Owner** : sélectionner le compte/organisation de l'école (ou ton compte)
4. **Repository name** : `schoolsafe` ou le nom que l'école préfère
5. Décocher "Copy only the main branch" si applicable
6. Cliquer **Create fork**

### 4.2 Mettre à jour les constantes dans index.html

Dans le fork créé, éditer `index.html` ligne ~1047 :

```javascript
// ── Central control ──
const CENTRAL_URL = 'https://vcifxatmlgzueavalfks.supabase.co';  // ← ne pas changer
const CENTRAL_KEY = 'sb_publishable_...';                         // ← ne pas changer
```

> Ces constantes pointent vers **ton** Supabase central. Elles restent identiques pour toutes les écoles.

---

## ÉTAPE 5 — Activer GitHub Pages

### 5.1 Configuration

Dans le repo forké de l'école :
1. **Settings** → **Pages**
2. **Source** : Deploy from a branch
3. **Branch** : `main` · **Folder** : `/ (root)`
4. Cliquer **Save**

L'application sera disponible après 1 à 3 minutes à :
```
https://NOM-GITHUB.github.io/schoolsafe/
```

### 5.2 Domaine personnalisé (optionnel)

Si l'école a son propre domaine :
1. Dans **Settings → Pages → Custom domain** : entrer le domaine
2. Chez le registrar DNS de l'école, ajouter un enregistrement CNAME :
   ```
   www  →  NOM-GITHUB.github.io
   ```
3. Cocher **Enforce HTTPS** une fois le certificat généré

> Penser à mettre à jour l'allowlist CORS dans Supabase avec ce nouveau domaine.

---

## ÉTAPE 6 — Premier lancement côté école

### 6.1 Ouvrir l'application

Aller sur l'URL GitHub Pages. L'écran de configuration Supabase apparaît automatiquement.

### 6.2 Entrer les identifiants Supabase

Dans le formulaire affiché :
- **URL Supabase** : `https://XXXXXXXX.supabase.co`
- **Clé anon** : `eyJhbGci...`
- Cliquer **Connexion**

Ces informations sont stockées dans le `localStorage` du navigateur de la Direction.

> ⚠️ Cette étape doit être faite sur l'appareil principal de la Direction (ordinateur ou tablette fixe). Sur mobile ou autre appareil, il faudra la refaire.

### 6.3 Entrer la licence

Sur l'écran de licence qui apparaît :
- Entrer la **license key** générée à l'étape 3.2
- Cliquer **Activer**

L'application se connecte au Supabase central, valide la licence, charge les fonctionnalités activées et démarre.

---

## ÉTAPE 7 — Configuration initiale dans l'application

### 7.1 Créer le compte Direction 1 (administrateur général)

Dans l'app (connectée) → Menu → **Comptes** → **Nouveau compte** :
- **Rôle** : Direction (administrateur général)
- **Nom** : Nom complet du directeur
- **PIN** : 4 à 6 chiffres (à communiquer en privé)
- **Téléphone** : numéro WhatsApp actif
- Cliquer **Enregistrer**

Se connecter avec ce compte.

### 7.2 Créer les autres comptes

Créer les comptes dans cet ordre :
1. **Direction 2** (pédagogie) — si applicable
2. **Caisse** (Direction 3) — si applicable
3. **Gardiens** — 1 compte par agent de sécurité
4. **Enseignants** — 1 compte par enseignant

### 7.3 Créer les classes

Menu → **Classes** → **Nouvelle classe** :

| Champ | Valeur |
|-------|--------|
| Nom | Ex: `CP1 A`, `6ème`, `Terminale` |
| Cycle | `maternelle`, `primaire`, `secondaire`, `humanités` |
| Enseignant FR | Enseignant titulaire section française |
| Enseignant EN | Enseignant titulaire section anglaise (si bilingue) |

Créer toutes les classes de l'école avant d'inscrire les élèves.

### 7.4 Configurer les frais scolaires

Menu → **Paramètres** → section **Frais scolaires** :
- Frais T1, T2, T3 en USD (ou devise locale)
- Trimestre actif

### 7.5 Inscrire les élèves

Menu → **Élèves** → **Nouvel élève** :
- Nom complet, matricule, classe, date de naissance
- Photo (recommandé dès l'inscription — obligatoire pour les cartes)
- Lier au compte parent si disponible

> **Conseil** : importer les élèves par classe, une classe à la fois. Pour les grandes écoles (+300 élèves), prévoir une demi-journée.

### 7.6 Créer les comptes Parents

Menu → **Parents** → **Nouveau compte** :
- Lier chaque parent à son/ses enfant(s)
- Les parents accèdent à leur espace via PIN + numéro de téléphone

---

## ÉTAPE 8 — Paramètres recommandés

### 8.1 Logo de l'école

Menu → **Paramètres** → **Logo** :
- Uploader le logo officiel (PNG ou JPG, min 200×200px)
- Ce logo apparaîtra sur les cartes élèves, les bulletins et les documents exportés

### 8.2 Signature de la Direction

Menu → **Paramètres** → **Signature** :
- Uploader une image de la signature du directeur
- Apparaîtra sur les documents officiels

### 8.3 Seuil de rattrapage automatique

Menu → **Paramètres** → **Détection automatique de rattrapage** :
- Valeur recommandée : `50%`
- L'application signalera automatiquement les élèves sous ce seuil après chaque saisie de notes

### 8.4 Configurer les matières

Menu → **Matières** :
- Ajouter les matières pour chaque classe
- Affecter les coefficients

---

## Checklist go-live

Cocher chaque point avant de remettre l'application à l'école :

### Infrastructure
- [ ] Projet Supabase créé et opérationnel
- [ ] Script SQL exécuté sans erreur (40 tables créées)
- [ ] Ligne `settings` initialisée avec les vraies informations de l'école
- [ ] Bucket `photos` créé avec politique anon
- [ ] Domaine allowlisté dans Supabase CORS
- [ ] Fiche école enregistrée dans admin.html (Supabase central)
- [ ] License key active avec bonne date d'expiration

### Application
- [ ] Fork GitHub Pages actif et accessible
- [ ] Configuration Supabase faite sur l'appareil Direction
- [ ] Licence activée et validée (badge vert dans l'app)
- [ ] Compte Direction 1 créé et testé
- [ ] Toutes les classes créées
- [ ] Au moins 3 élèves de test inscrits
- [ ] Paiement test enregistré
- [ ] Scan test effectué (entrée + sortie)
- [ ] Notification test envoyée

### Formation
- [ ] Direction formée sur : gestion élèves, notes, paiements, rapports
- [ ] Gardien formé sur : scan entrée/sortie, alerte urgence
- [ ] Enseignants formés sur : saisie notes, devoirs, rattrapage
- [ ] Parents informés de l'URL et de leur PIN

---

## Renouvellement d'abonnement

### Quand l'école renouvelle

Dans **admin.html** → **Écoles** → cliquer sur l'école → **Modifier** :
- Mettre à jour la **date d'expiration**
- Vérifier le **statut** : doit rester `active`

### Quand l'abonnement expire

L'application affiche un écran de licence expirée. L'école ne peut plus se connecter jusqu'au renouvellement. Les données restent intactes dans leur Supabase.

### Suspension d'un abonnement

Dans admin.html → Écoles → Modifier :
- **Statut** : passer à `suspended`
- L'app affiche un écran de compte suspendu immédiatement

---

## Dépannage courant

### "Erreur de connexion Supabase"
- Vérifier que l'URL et la clé anon sont correctes dans le localStorage
- Vérifier que le domaine est dans l'allowlist CORS du projet Supabase
- Essayer de vider le cache et relancer

### "Licence invalide"
- Vérifier que la license_key dans admin.html est exactement la même que celle saisie
- Vérifier que le statut est `active` et que la date d'expiration n'est pas dépassée
- Vérifier la connexion Internet (la validation nécessite d'atteindre le Supabase central)

### "Tables manquantes" / erreurs lors du premier lancement
- Réexécuter `supabase_setup.sql` en entier dans le SQL Editor
- Vérifier que la ligne `settings` (id = 'main') existe

### Photos d'élèves ne s'affichent pas
- Vérifier que le bucket `photos` est bien **public**
- Vérifier la politique Storage anon
- Vérifier que l'URL du Supabase dans la photo correspond au bon projet

### L'admin ne peut pas générer les cartes d'une école
- Vérifier que `supabase_url` et `supabase_anon_key` sont renseignés dans la fiche école (admin.html)
- Vérifier que la clé anon est bien la `anon/public` et non la `service_role`
- Vérifier les politiques RLS sur les tables `students`, `classes`, `users`, `settings`

### "CORS blocked" dans la console navigateur
- Ajouter l'URL complète de l'app dans **Supabase → Settings → API → Allowed Origins**
- Si en local (test) : ajouter `http://localhost:PORT` aussi

---

## Informations à remettre à l'école

À la remise, fournir un document avec :

```
╔══════════════════════════════════════════════════════════╗
║         SCHOOLSAFE — INFORMATIONS DE CONNEXION           ║
║                    [NOM DE L'ÉCOLE]                      ║
╠══════════════════════════════════════════════════════════╣
║ URL de l'application  : https://...github.io/schoolsafe  ║
║ License Key           : SS-2025-XX-XXXX                  ║
║ Année scolaire        : 2025-2026                        ║
║                                                          ║
║ Compte Direction      :                                  ║
║   PIN                 : (communiqué en privé)            ║
║                                                          ║
║ Abonnement valide jusqu'au : JJ/MM/AAAA                  ║
║ Support WhatsApp      : +243 XXX XXX XXX                 ║
╚══════════════════════════════════════════════════════════╝
```

> ⚠️ Ne jamais écrire les PIN dans un document électronique transmissible. Les communiquer en face à face ou par appel vocal.

---

## Récapitulatif des URLs importantes

| Ressource | URL |
|-----------|-----|
| Application école | `https://NOM-GITHUB.github.io/schoolsafe/` |
| Supabase école | `https://XXXXXXXX.supabase.co` |
| Supabase central | `https://vcifxatmlgzueavalfks.supabase.co` |
| Admin opérateur | `admin.html` (ton serveur/fichier local) |
| Guide gardien | `https://NOM-GITHUB.github.io/schoolsafe/guide_gardien.html` |

---

*SchoolSafe v3.0 — Document opérateur · Confidentiel*
