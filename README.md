# 🏆 ZALAVRAI SYSTÈME — v10.0 Production

> **PWA de gestion commerciale complète** — 4 rôles, 21 panels, sync Google Sheets, cartes clients HD, système anti-mauvais-clients, QR scanner, mode offline.

---

## 📁 Fichiers du dépôt

```
zalavrai-systeme/
├── index.html      ← Application complète (PWA, ~544KB)
├── sw.js           ← Service Worker (cache offline, sync background)
├── Code.gs         ← Google Apps Script (backend Sheets)
└── README.md       ← Ce fichier
```

---

## 🚀 DÉPLOIEMENT GITHUB PAGES (étapes)

### 1. Créer le dépôt GitHub

1. Aller sur **github.com** → **New repository**
2. Nom : `zalavrai-systeme`
3. Visibilité : **Public** (requis pour GitHub Pages gratuit)
4. ✅ Add README : **NON** (on a le nôtre)
5. Cliquer **Create repository**

### 2. Uploader les fichiers

**Option A — Interface web (plus simple) :**
1. Dans le dépôt créé → cliquer **uploading an existing file**
2. Glisser-déposer : `index.html`, `sw.js`, `Code.gs`, `README.md`
3. Commit message : `🚀 ZALAVRAI v10 — Production`
4. Cliquer **Commit changes**

**Option B — Git en ligne de commande :**
```bash
git init
git add index.html sw.js Code.gs README.md
git commit -m "🚀 ZALAVRAI v10 — Production"
git remote add origin https://github.com/TON_USERNAME/zalavrai-systeme.git
git branch -M main
git push -u origin main
```

### 3. Activer GitHub Pages

1. Aller dans **Settings** du dépôt
2. Sidebar gauche → **Pages**
3. Source : **Deploy from a branch**
4. Branch : `main` / `/ (root)`
5. Cliquer **Save**
6. Attendre 2-3 minutes → URL disponible :  
   `https://TON_USERNAME.github.io/zalavrai-systeme/`

---

## ☁️ CONNEXION GOOGLE SHEETS

### Étape 1 — Créer la feuille Google Sheets

1. Aller sur **sheets.google.com** → **Nouveau**
2. Renommer : `ZALAVRAI-DB`
3. Cliquer **Partager** (coin supérieur droit)
4. → **Toute personne disposant du lien** → **Lecteur**
5. Copier l'URL de la feuille (ex: `https://docs.google.com/spreadsheets/d/1ABC.../edit`)

### Étape 2 — Déployer le script Apps Script (Code.gs)

1. Dans Google Sheets → **Extensions** → **Apps Script**
2. Supprimer tout le code par défaut dans `Code.gs`
3. Coller le contenu du fichier `Code.gs` fourni
4. Cliquer 💾 **Enregistrer**
5. Cliquer ▶️ **Exécuter** → choisir `initSheets` → **Autoriser**
   > ⚠️ Cliquer "Paramètres avancés" si Google avertit → "Accéder à ZALAVRAI (non sécurisé)"
6. Menu **Déployer** → **Nouveau déploiement**
   - Type : **Application Web**
   - Exécuter en tant que : **Moi**
   - Qui peut accéder : **Tout le monde**
7. Cliquer **Déployer** → Copier l'URL (commence par `https://script.google.com/macros/s/...`)

### Étape 3 — Connecter l'app ZALAVRAI

1. Ouvrir l'app : `https://TON_USERNAME.github.io/zalavrai-systeme/`
2. Se connecter : `admin` / `admin123`
3. Aller dans **⚙️ Réglages**
4. **Champ bleu** (URL Google Sheets) → coller l'URL de la feuille Sheets
5. **Champ doré** (URL Apps Script) → coller l'URL GAS
6. Cliquer **☁️ Connecter**
7. Cliquer **🗂️ Initialiser les 7 feuilles**
8. Tester avec **🔄 Sync manuel**

### Structure des feuilles créées automatiquement

| Feuille | Contenu |
|---------|---------|
| `utilisateurs` | Comptes Admin/Manager/Agent/CréateurCarte |
| `clients` | Fiches clients + score risque |
| `ventes` | Historique des ventes |
| `paiements` | Versements quotidiens |
| `stock` | Mouvements de stock |
| `signalements` | Corrections/suggestions |
| `_sync_log` | Journal de synchronisation |

---

## 🔐 CONNEXION PAR DÉFAUT

```
Rôle     : Admin
Username : admin
Password : admin123
```
> ⚠️ **CHANGER CE MOT DE PASSE IMMÉDIATEMENT** après la première connexion.

---

## 👥 RÔLES ET DROITS

| Rôle | Accès |
|------|-------|
| **Admin** | Tout : utilisateurs, stock, clients, ventes, rapports, cartes, archives, risques |
| **Manager** | Ses agents + leurs clients, stock équipe, encaissement, signalement risques |
| **Agent** | Ses clients, ses ventes, sa récolte, son rapport + stock |
| **CréateurCarte** | Génération cartes clients PNG HD uniquement |

---

## 🚨 SYSTÈME MAUVAIS CLIENTS (Nouveauté v10)

### Score automatique 0–100

| Score | Niveau | Action |
|-------|--------|--------|
| 0–21 | ✅ Bon client | Aucune |
| 22–44 | ⚠️ À surveiller | Badge jaune visible |
| 45–74 | 🔶 Mauvais payeur | Alerte à la vente |
| 75–99 | 🔴 Client à risque | Alerte forte + confirmation |
| 100 | ⛔ Blacklisté | Vente bloquée (optionnel) |

### Accès
- **Panel 🚨 Risques** dans la navigation Admin et Manager
- **Bouton "Signaler"** sur chaque fiche client
- **Badge coloré** visible sur toutes les listes de clients

---

## ⚙️ ARCHITECTURE TECHNIQUE

```
localStorage chiffré (XOR + base64)
    ↓
Queue persistante (debounce 2s, batch 20 ops)
    ↓
Google Apps Script (LockService anti-collision)
    ↓
Google Sheets (7 feuilles normalisées)
```

- **Mode offline** : toutes les données en local, sync à la reconnexion
- **Service Worker v11** : cache offline complet
- **SHA-256** : hashage des mots de passe
- **Auto-logout** : 8h d'inactivité

---

## 🛠️ RÉSOLUTION DES PROBLÈMES COURANTS

| Problème | Solution |
|----------|----------|
| "Erreur de connexion Sheets" | Vérifier que le GAS est bien déployé "Tout le monde" |
| "Sync échoue en boucle" | Extensions → Apps Script → Réessayer `initSheets()` |
| QR scanner ne s'ouvre pas | Autoriser l'accès caméra dans le navigateur |
| App ne s'installe pas (PWA) | Vérifier HTTPS (GitHub Pages = OK, HTTP local = non) |
| Photo client ne s'affiche pas | Utiliser Google Drive + partage public |

---

## 📱 INSTALLATION PWA (optionnel)

Sur mobile Android :
1. Ouvrir l'URL dans Chrome
2. Menu ⋮ → "Ajouter à l'écran d'accueil"
3. L'app se lance comme une vraie appli native

Sur iOS (Safari) :
1. Ouvrir l'URL dans Safari
2. Bouton partage → "Sur l'écran d'accueil"

---

## 📞 GROUPE WHATSAPP

Lien d'invitation : `https://chat.whatsapp.com/DZnzL0uRSTKKfdDBndieRt`

---

*ZALAVRAI SYSTÈME COMMERCIAL — v10.0 — Build Production*
