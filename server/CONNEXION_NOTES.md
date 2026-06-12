# SchoolSafe — Notes de connexion future

## À faire quand le VPS + PocketBase est prêt

### 1. PocketBase
- Lancer `bash server/setup.sh TON_DOMAINE.COM TON_EMAIL`
- Ouvrir `https://TON_DOMAINE/_/` → créer le compte superadmin
- Importer le schéma : `server/pb-schema.json` (17 collections)
- Configurer rclone R2 : `rclone config` avec `server/rclone-r2.conf`
- Récupérer : URL du projet + clé admin

### 2. OpenWA (WhatsApp Gateway)
- Installé dans : `/home/user/openwa/`
- API URL : `http://localhost:2785/api`
- Clé API : `owa_k1_9d47a6ed92dccca377d1cb472ae9cee46d5bf2cac20e3efe680b29d5d4f2bd41`
- Clé maître .env : `ff6952fbf25285fbca43eabcca964322955286afe1cc6c88c7fb62bda4048ea4`
- Session à créer : `schoolsafe`
- Scanner le QR avec le téléphone WhatsApp de l'école

### 3. Connexion SchoolSafe → PocketBase (à coder)
Dans `index.html` :
- Remplacer `pushSync()` (no-op) par appels PocketBase SDK
- Remplacer `loadUsers` par fetch PocketBase `/api/collections/users/records`
- Auth : `/api/collections/users/auth-with-password`
- Temps réel : PocketBase SSE `subscribe` pour live updates

### 4. Connexion SchoolSafe → OpenWA (à coder)
- Notifications WhatsApp parents : `POST /api/sessions/schoolsafe/messages/send`
- Header : `x-api-key: owa_k1_9d47a6ed92dccca377d1cb472ae9cee46d5bf2cac20e3efe680b29d5d4f2bd41`
- Corps : `{ "to": "243XXXXXXXXX@c.us", "text": "..." }`

### 5. Variables à remplacer dans index.html
```js
const PB_URL  = 'https://TON_DOMAINE.COM';   // URL PocketBase
const PB_KEY  = 'TON_TOKEN_ADMIN';            // token superadmin
const OWA_URL = 'http://localhost:2785/api';  // ou URL publique si VPS
const OWA_KEY = 'owa_k1_9d47a6ed92dccca377d1cb472ae9cee46d5bf2cac20e3efe680b29d5d4f2bd41';
```
