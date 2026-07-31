# SchoolSafe v3.0 — Code Map

**Fichier unique :** `index.html` (~10 600 lignes)  
**École :** Complexe Scolaire Le Sage / The Wise School International (Kinshasa, DRC)  
**Backend :** Supabase — projet unique de l'école (URL + clé publiable ~ligne 1563)

**Deux noms à ne pas confondre :**

| | Nom | Où il paraît |
|---|---|---|
| Le **logiciel** | SchoolSafe | titre, écran de démarrage, icône du téléphone, manifest |
| L'**école branchée** | Complexe Scolaire Le Sage | bulletins, reçus, convocations, en-têtes de documents |

`ECOLE_NOM` / `ECOLE_NOM_EN` (~ligne 1576) sont le repli de l'ÉCOLE, pas du
produit. Ils servent partout où `DB.settings.school` n'est pas encore
descendu du serveur — un reçu imprimé avant la première synchronisation doit
porter le nom de l'école qui encaisse, jamais celui du logiciel.

Les réglages enregistrés dans la base les remplacent dès leur arrivée : la
Direction garde le dernier mot sur le nom de son école. Une colonne `school`
nulle n'efface pas le repli, sinon un vide venu du serveur écraserait
l'identité.

**Ne jamais changer :** `SchoolSafe_v2` (sel des mots de passe — tout compte
deviendrait inaccessible) et `SchoolSafe2026!TWSI` (clé du cache chiffré —
les données hors ligne deviendraient illisibles).

---

## Patterns essentiels

```js
$(id)               // document.getElementById
esc(s)              // XSS escape — TOUJOURS utiliser pour afficher données utilisateur
ini(name)           // initiales (ex: "Jean Kabongo" → "JK")
today()             // date ISO YYYY-MM-DD
nowTime()           // heure HH:MM
gc(id)              // DB.classes.find(c => c.id === id)
gu(id)              // DB.users.find(u => u.id === id)
t(fr, en)           // bilinguisme (fr si section FR, en si enseignant EN)
getLang()           // 'en' si section anglaise, 'fr' sinon
toast(msg, type)    // notification ('success'|'error'|'info'|'warning')
openM(title, body, footer)  // modal
closeModal()        // ferme modal
showC(title, msg, cb)       // dialog de confirmation
go(page)            // naviguer vers une page
render()            // re-rend la page courante
saveToCrypt()       // sauvegarde locale AES-256-GCM
pushSync(table, op, data, query)  // sync Supabase ('post'|'patch'|'upsert'|'delete')
```

---

## État global

```js
S.user      // utilisateur connecté (role, id, name, initials, phone, ...)
S.page      // page courante
S.lockdown  // boolean lockdown
DB.xxx      // base de données locale (voir section DB)
```

---

## Base de données locale (DB)

| Clé | Contenu |
|-----|---------|
| `DB.users` | Tous les comptes (role: direction/direction2/direction3/enseignant/parent/gardien) |
| `DB.students` | Élèves (id, name, mat, cid, pid, photo, blocked, ...) |
| `DB.classes` | Classes (id, name, cycle, teacher_id, teacher_id_en, titulaire_id, ...) |
| `DB.grades` | Notes (sid, matiere, note, type, trimestre, by, ...) |
| `DB.payments` | Paiements (sid, t:"T1/T2/T3", paid, ...) |
| `DB.attendance` | Présences (sid, cid, date, status, arr_time, ...) |
| `DB.scan_log` | Scans portail (sid, type:"entry/exit", status, date, time, ...) |
| `DB.devoirs` | Devoirs (cid, title, category, ...) |
| `DB.rattrapages` | Rattrapages (sid, teacher_id, status, validated_by, d2_validated, ...) |
| `DB.notifs` | Notifications (uid, msg, date, read, type, ...) |
| `DB.aps` | Personnes autorisées sortie (sid, name, relation, photo, active, phone) |
| `DB.settings` | Config école (fees:{T1,T2,T3}, currentTrimestre, toggles, _lastCleanup, ...) |
| `DB.audit_log` | Journal audit (action, detail, date, ...) |
| `DB.conduct` | Conduite élèves (sid, score:"Excellent/Bien/Moyen/Mauvais", ...) |
| `DB.cahier_texte` | Cahier de texte enseignants |
| `DB.daily_records` | Recettes caisse (date, amount, ...) |
| `DB.daily_expenses` | Dépenses caisse (date, amount, ...) |

---

## Rôles

```
direction   → Direction 1 (administrateur général)
direction2  → Direction 2 (pédagogie)
direction3  → Caisse (finances)
enseignant  → Professeur
parent      → Parent/tuteur
gardien     → Gardien de sécurité
```

---

## Pages renderers (R.xxx)

### Dashboards
| Renderer | Ligne | Rôle |
|----------|-------|------|
| `R.dashboard` | 1410 | dispatcher (appelle dashboard par rôle) |
| `dashboardDirection()` | 1421 | Direction 1 |
| `dashboardEnseignant()` | 1633 | Enseignant |
| `dashboardDirection2()` | 1771 | Direction 2 |
| `dashboardDirection3()` | 1876 | Caisse |
| `dashboardGardien()` | 1934 | Gardien |
| `dashboardParent()` | 1981 | Parent |

### Profils (système pt-glass/pt-light-card, tous en onglets)
Tous les profils partagent : header gradient animé · `.pt-tabbar` · `#profileScreenWrap.pt-mode-dark/light` (basculé par `_setProfileTab()` via `data-ptab-mode`) · onglets sombres en `.pt-glass` · onglets clairs en `.pt-light-card` · onglet Sécurité standard (PIN/mdp + déconnexion `.pt-btn-glow-red`).

| Renderer | Ligne | Onglets (défaut en gras, mode entre parenthèses) |
|----------|-------|---------------------------------------------------|
| `R.profil_direction` | 15649 | **stats**(dark) · profil(light) · donnees(light) · securite(dark) |
| `R.profil_direction2` | 15809 | **stats**(dark) · profil(light) · securite(dark) |
| `R.profil_enseignant` | 14439 | **classe**(dark) · profil(light) · finances(light) · securite(dark) |
| `R.profil_parent` | 14686 | **enfants**(dark) · ecole(dark) · compte(light) |
| `R.profil_gardien` | 15289 | **activite**(dark) · profil(light) · securite(dark) |
| `R.profil_caisse` | 15437 | **caisse**(dark) · profil(light) · securite(dark) |

Profil Parent : couche additive de classes `pp-*` (`pp-bt`, `pp-card`, `pp-btn`, `kid-tile`, CSS lignes 206-213/851-853) pour les cartes enfant/podium/anneau de paiement — vient compléter, pas remplacer, le système pt-.

Fonctions save profil :
- `saveDir1Profile()` / `saveDir2Profile()` — appelées directement ; l'enveloppe
  `saveDirProfile` a été retirée, plus aucun écran ne s'en servait
- `saveTeacherProfile()` → ligne 14621
- `saveParentProfile()` → ligne 15051
- `saveGardienProfile()` → ligne 15419
- `saveCaisseProfile()` → ligne 15575

Onglets : `window._setProfileTab(id)` ligne ~7002 · état dans `window._pTab`

### Élèves / Utilisateurs
| Renderer | Ligne |
|----------|-------|
| `R.students` | 3041 |
| `R.teachers` | 3368 |
| `R.parents` | 3370 |
| `R.guardians` | 3369 |
| `R.classes` | 3470 |
| `R.accounts` | 10154 |
| `R.acces_parents` | 10568 |

CRUD utilisateurs : `openUserForm(role, uid)` 3230 · `saveUser()` 3274 · `deleteUser(uid)` 3354  
CRUD élèves : `openStudentForm(sid)` 3092 · `saveStudent()` 3145 · `deleteStudent(sid)` 3174

### Pédagogie
| Renderer | Ligne |
|----------|-------|
| `R.palmares` | 4892 |
| `R.palmares_parent` | 4988 |
| `R.attendance` | 4492 |
| `R.devoirs` | 5444 |
| `R.devoirs_parent` | 5522 |
| `R.cahier_texte` | 6347 |
| `R.matieres` | 5371 |
| `R.approbations` | 3596 |
| `R.timetable` | 9731 |

Notes : `openGradePanel(cid)` 5204 · `saveGradePanel(cid)` 5267  
Moyennes : `matAvgPct(sid, matiere, trim)` 5142 · `studentAvgPct(sid, matieres, trim)` 5152  
Top 10 : `getSchoolTop10()` 5159  
Matières d'une classe : `getClassMatieres(cid)` 4477  
Classe d'un enseignant : `getMyClass()` → `{cl, lang}` ligne 4460

### Portail / Scans
| Renderer | Ligne |
|----------|-------|
| `R.scanner` | 6694 |
| `R.scanner_exit` | 6829 |
| `R.scan_log` | 7021 |

Entrée : `processScanEntry(code)` 6721  
Sortie : `scanExit()` 6848 · `selectExitPerson(idx)` 6892 · `zoomAuthPhoto(idx)` 6913  
Personnes autorisées : `DB.aps` filtrées par `sid`

### Finances
| Renderer | Ligne |
|----------|-------|
| `R.payments` | 3975 |
| `R.caisse_paiement` | 7551 |
| `R.export` | 8757 |

Frais : `getFees()` 3966 → `{T1, T2, T3}` depuis `DB.settings.fees`  
Balance : `getStudentBalance(sid)` 3967

### Communication / Admin
| Renderer | Ligne |
|----------|-------|
| `R.notifications` | 2947 |
| `R.authorized` | 7075 |
| `R.absences` | 7448 |
| `R.convocations` | 8402 |
| `R.calendar` | 9299 |
| `R.settings` | 9104 |
| `R.audit_log` | 9952 |
| `R.year_mgmt` | 8574 |
| `R.lockdown` | 2871 |
| `R.cards` | 2779 |

---

## Fonctions clés par domaine

### Rattrapages
```
signalerRattrapage(sid)    6680   enseignant signale
validerRattrapage(rid)     4721   direction valide
approveApr(id, status)     3749   approbation générale
pendingRats D2 = filter(!validated_by && !d2_validated)
```

### Notifications
```
pushNotif(uid, msg)        → pushSync('notifs', 'post', ...)
clearAllNotifs()           2982
getPendingCount()          1167   badge count nav
```

### Nettoyage / Archive
```
runAutoCleanup(force)      469    supprime >60j de scan_log/audit_log/notifs/approbations done
_maybeAutoCleanup()        498    appel hebdo silencieux (Direction 1 login)
archiverAnnee()            10371  confirm → PDF → cleanup
exportArchivePDF()         10385  PDF année complète avec logo école
```

### Cartes élèves
```
fillCardAsync(sid)         2528
exportAllCardsZip()        2538
```

### Logo école
```
window.SCHOOL_LOGO         467    data:image/jpeg;base64,...
```

---

## Navigation

```js
window.NAV = {
  direction:  { bn:[...], nav:[...] },   // 673+
  direction2: { bn:[...], nav:[...] },
  enseignant: { bn:[...], nav:[...] },
  gardien:    { bn:[...], nav:[...] },
  parent:     { bn:[...], nav:[...] },
}
```

`buildUI()` ligne 1334 — construit sidebar + bottom nav + topbar  
`goToMyProfile()` ligne 1329 — redirige selon rôle vers profil_xxx

---

## Conventions importantes

- **Jamais** `phone || u.phone` dans les save → utiliser `phone || null` (pour permettre suppression)
- **`DB.xxx || []`** : garde de confort, pas une nécessité. `DB.<table>` est un
  tableau par construction — voir « L'invariant » plus bas. Ce qui compte,
  c'est que toute table lue soit **déclarée** dans `window.DB`.
- **Syntaxe** : vérifier avant commit → `node -e "new Function(scriptBody)"`
- **Push** : toujours `git push -u origin claude/integrate-external-map-system-kCSm6 && git push origin HEAD:main`
- **Onglets profil** : ne pas appeler `render()` pour changer d'onglet — utiliser `_setProfileTab(id)`
- Les `t(fr, en)` ne s'appliquent qu'aux enseignants (getLang). Les autres rôles voient toujours le français.
- **Identifiants** : toujours `_uid('prefix_')`, jamais `'x'+Date.now()`. Deux
  écritures de la même milliseconde partageaient une clé primaire ; une seule
  survivait côté serveur. C'est ce qui privait les autres directions de leurs
  notifications dans toutes les boucles `forEach`.
- **Argent** : toujours `lireMontant()`, jamais `parseFloat()`. `parseFloat('12,50')`
  vaut **12** — la virgule est le séparateur décimal ici. De même `lireNote()`
  pour les notes.
- **Écritures partielles** : `pushSync(t,'patch',{champs modifiés},query)`, jamais
  l'objet entier. Un seul champ local sans colonne fait rejeter toute la ligne.
- **Schéma** : après toute nouvelle écriture, `node tools/audit-schema.mjs`.
  Toute colonne manquante va dans `supabase_migration_finale.sql`.
- **SQL** : ne jamais livrer une migration sans l'avoir exécutée. Voir
  « Éprouver une migration » plus bas — c'est ainsi qu'a été trouvée une
  apostrophe qui aurait fait échouer les 78 colonnes d'un bloc.

---

## Architecture : une école, une base, rien d'autre

L'application sert **une seule école** et parle **directement** à sa base
Supabase. Il n'y a plus de service intermédiaire.

```
index.html  ──►  projet Supabase de l'école  (PostgREST + Storage)
```

- `SCHOOL_SUPA_URL` / `SCHOOL_SUPA_KEY` (~ligne 1586) : l'URL et la clé
  **publiable** du projet. La clé `sb_secret_…` ne doit jamais y figurer —
  la protection vient des policies, pas de la discrétion de la chaîne.
- Clé absente → l'écran de configuration s'ouvre seul, la saisie est
  mémorisée dans `localStorage`. La clé du code prime toujours sur la saisie
  manuelle. Trois cas de démarrage vérifiés.
- `LOGIN_FN_URL = ''` et `CENTRAL_URL`/`CENTRAL_KEY = ''` : vidées, pas
  supprimées. Trois écrans secondaires — habillage du login, site vitrine,
  annonces — les testent en tête de fonction et se taisent d'eux-mêmes.

### Pourquoi le central a été abandonné

L'empreinte du code de connexion était calculée par **deux programmes** —
l'application et une Edge Function — qui devaient rester d'accord :

```
application     SHA-256(uid + '|SchoolSafe_v2|' + code)
Edge Function   SHA-256(code)
```

L'un a évolué, l'autre non. **Tous les comptes se sont fermés**, sans autre
message que « Nom ou code incorrect ». La vérification du code est désormais
faite en un seul endroit ; cette classe de panne ne peut plus revenir.

Tout ce qui s'y rapportait a été supprimé du dépôt : la console
d'administration, ses quatre migrations SQL, l'éditeur de site vitrine et
ses auxiliaires, la publication d'actualités, et le bloc de connexion
centrale. L'historique git les conserve — mais rien dans le code n'y
renvoie plus.

### Ce que l'école a perdu, sciemment

Le multi-école · le verrou de licence à distance · la production physique
des cartes par un tiers · le stockage R2 mutualisé.

**Dette assumée** : en connexion directe, les policies laissent `anon` tout
lire. Le contrôle du nom et du code ne tient que côté client. C'était l'état
antérieur au multi-tenant, mais c'est une régression par rapport au JWT.

### Cartes élèves : générées et imprimées sur place

`submitCardOrder(sid)` — le nom est hérité — rend la carte, attend le QR,
capture recto et verso par `html2canvas`, les assemble, puis :

- `imprimerCarte()` — fenêtre d'impression, `@page size: 86mm 110mm`. Sans
  cette règle le navigateur étire la carte sur une A4 entière.
- `telechargerCarte()` — le PNG sur l'appareil.

Chaque tirage écrit `card_printed`, `card_print_date`, `card_print_count` —
premier tirage ou duplicata numéroté. Une copie part dans le bucket `cards`
quand le stockage répond, pour rééditer depuis un autre poste.

### Installer l'app (PWA + limites)

- Bouton « Installer l'application » sur l'écran de login (`#btnInstallApp`) :
  écoute `beforeinstallprompt`, fonctionne sur Android/Desktop Chrome/Edge.
  Reste caché sur iOS Safari (l'événement n'existe pas) — seule voie là-bas :
  « Sur l'écran d'accueil » via le partage Safari, pas automatisable.
- Pas d'outil de packaging natif dans ce dépôt. Pour un `.apk` réel :
  passer l'URL déployée dans [PWABuilder](https://www.pwabuilder.com/), le
  manifest et le service worker existants suffisent.

---

## Enseignants et parents ne se parlent pas directement

Règle de l'école : un enseignant n'écrit pas aux familles, une famille
n'écrit pas à un enseignant. Tout échange humain passe par la Direction,
qui répond de ce qui est dit au nom de l'établissement.

Ce que la règle **ne vise pas** : devoirs, cahier de texte, notes,
appréciation du bulletin. Ce n'est pas un enseignant qui écrit à un parent,
c'est l'école qui publie son travail — et c'est le cœur de l'application.
Ces notifications restent, au nombre de dix.

Trois canaux ont été fermés : le réglage `direct_teacher_msg`
(parent→enseignant), le mode `teacher_broadcast` (enseignant→parents de sa
classe, même avec accord de la Direction), et `sendMessageToTeacher`. Les
absences d'enseignants ne sont pas notifiées aux familles non plus — elles
regardent l'école.

Le canal fermé ne l'est pas par interrupteur : un réglage invite à être
basculé, et cette règle n'est pas négociable.

---

## CSS classes utiles

```css
.premium-section          carte principale avec shadow
.premium-section-title    titre de section (bold, couleur)
.premium-item             ligne item (icône + texte + action)
.pi-icon / .pi-title / .pi-sub   sous-éléments de premium-item
.btn .btn-primary .btn-outline .btn-danger .btn-sm
.pill .pill-green .pill-blue .pill-orange .pill-red .pill-gray
.form-group .form-row .form-label .form-input
.ww-toolbar .ww-search    barre de recherche/filtre
.scan-result .green .orange .red .blue   résultat scan
```

---

## Workflow Claude Code (Boris Cherny tips)

### 1. Paralléliser les sessions
- Lancer 3–5 sessions Claude simultanément, une par tâche
- Utiliser `git worktree` pour que chaque session ait son propre répertoire isolé
- Garder un worktree dédié à l'analyse de logs / débogage

### 2. Plan d'abord pour les tâches complexes
- Toujours démarrer en **Plan mode** (Shift+Tab deux fois) pour les changements non-triviaux
- Une session rédige le plan → une autre session le review comme "staff engineer"
- Si ça part en vrille, repasser en plan mode et re-planifier avec des étapes de vérification

### 3. CLAUDE.md vivant
- Après chaque correction, demander à Claude de **mettre à jour CLAUDE.md** pour éviter la répétition
- Maintenir un dossier `notes/` par tâche mis à jour après chaque PR
- Itérer sans pitié sur ce fichier jusqu'à ce que le taux d'erreurs chute

### 4. Skills et commandes réutilisables
- Toute action répétée plus d'une fois par jour → transformer en skill ou slash command
- Committer les skills dans git pour les partager

### 5. Fix end-to-end
- Donner à Claude le contexte complet (logs Docker, threads, CI) et le laisser déboguer en autonomie
- Ne pas micro-manager la méthode : "Fixe les tests CI qui échouent" plutôt que step-by-step
- Pour SchoolSafe : pointer Claude vers les logs Supabase + messages d'erreur console

### 6. Prompting de qualité
- Challenger Claude : lui faire **justifier** ses changements avant d'appliquer
- Si la correction est médiocre : "Recommence et implémente la solution élégante"
- Écrire des specs détaillées sans ambiguïté avant de déléguer

### 7. Sous-agents
- Pour plus de "compute" sur une tâche, demander explicitement d'utiliser des sous-agents
- Déléguer les sous-tâches pour garder le contexte du main agent propre et focalisé
- Router les vérifications sensibles de permissions vers un modèle plus fort via hooks

### 8. Environnement terminal
- Utiliser `/statusline` pour voir l'usage de contexte et la branche git courante
- Nommer/colorer les onglets (un onglet par tâche/worktree)
- Dicter les prompts longs à la voix pour aller plus vite

### 9. Mode apprentissage
- Demander des explications : "Explique-moi pourquoi cette approche"
- Demander des diagrammes ASCII ou présentations HTML pour comprendre l'architecture
- Utiliser les sous-agents pour l'analyse sans polluer le contexte principal

---

## Infrastructure réelle

| Nom | Identifiant | Contenu |
|-----|-------------|---------|
| **Le Sage** | `loggezdryupyyuifzxky` | Les 49 tables scolaires, le stockage des photos |

C'est tout. Le projet central PRODELI et le bucket R2 ont été abandonnés —
voir « Architecture » plus haut, et `archive/central-supprime/`.

### Clés API : les legacy sont désactivées

Supabase a coupé les anciennes clés `anon`/`service_role` sur les projets
récents. Utiliser `sb_publishable_…` côté client. Le message
`Legacy API keys are disabled` signale ce cas ; il n'a rien à voir avec une
clé mal copiée.

### Stockage des photos

Bucket `photos` du projet de l'école, **public en lecture**. `_uploadFile()`
y dépose et renvoie l'URL publique ; en cas d'échec l'appelant garde sa copie
en base64 — l'application continue de fonctionner, la base s'alourdit.

Seule la photo d'un **parent** circule (`_photoIsShared`) : le gardien doit
pouvoir la confronter à qui se présente au portail. Les autres rôles gardent
la leur sur l'appareil, dans `localStorage`.

---

## Synchronisation

### Règle absolue : POUSSER avant de TIRER

`loadFromSupabase()` remplace `DB` par l'instantané du serveur puis l'écrit
dans le cache chiffré. Tirer alors qu'une écriture attend en file **efface
cette écriture** — la donnée semble disparaître d'elle-même. C'était la cause
du « ça se perd automatiquement » : le rechargement périodique tirait toutes
les trois minutes sans avoir poussé.

`autoSync({pull})` applique cet invariant : il ne tire que si la file est
vide. Une file non vide signifie que le serveur est en retard sur l'appareil.

### La connexion ne doit jamais attendre la file

Vider la file avant d'ouvrir l'application faisait patienter des dizaines de
secondes — une requête par élément. Si la file n'est pas vide, on part du
cache local et elle s'écoule en arrière-plan.

### Aucun message à l'écran

Une synchronisation qui se déclenche seule n'interrompt personne. Tout part
dans `console`. La pastille d'en-tête est **masquée** tant que rien ne réclame
une décision humaine — elle n'apparaît que hors ligne, sur échec répété, ou si
des opérations sont mises de côté.

### Une opération n'est jamais jetée

Après quatre tentatives, `syncQueue.park()` la met de côté dans
`localStorage._schoolsafe_sync_parked` au lieu de la supprimer : elle porte une
saisie humaine. `syncQueue.retryParked()` la réinjecte depuis la file
d'attente.

Repères : lots de 20 par passage · battement 45 s · cycle complet 3 min ·
enchaînement 2 s tant qu'il reste du travail.

---

## Schéma de base : auditer, ne jamais supposer

`supabase_setup.sql` avait pris du retard sur l'application : **8 tables et
55 colonnes manquaient**. PostgREST rejette la requête entière dès qu'une
seule colonne est inconnue — donc une note corrigée, une absence excusée ou
une fiche de préparation était perdue en silence, et l'opération s'accumulait
sans jamais aboutir.

Migrations : `supabase_missing_tables.sql` puis `supabase_fix_columns.sql`.

### Auditer le schéma après toute nouvelle écriture

```bash
# Tables écrites par le code mais absentes du SQL
python3 -c "
import re
src=open('index.html').read(); sql=open('supabase_setup.sql').read()
used=set(re.findall(r\"pushSync\(\s*'([a-z_0-9]+)'\", src))
print(sorted(used - set(re.findall(r'CREATE TABLE IF NOT EXISTS\s+([a-z_0-9]+)', sql, re.I))))"
```

Un audit par objet littéral **ne suffit pas** : `pushSync('settings','upsert',DB.settings)`
envoie l'objet entier. Pour ces cas, comparer les affectations
`DB.settings.X = …` aux colonnes déclarées.

### Un garde-fou ne doit pas dépendre de ce qu'il protège

`_seedFeeTypes()` se gardait par `if (DB.fee_types.length) return`, or ce
tableau se remplit en **lisant** la table — absente. Le garde-fou ne se
déclenchait donc jamais et neuf écritures vouées à l'échec repartaient à
chaque cycle. L'amorçage est désormais verrouillé par école dans
`localStorage`, indépendamment de ce que répond le serveur.

### Deux orthographes coexistent volontairement

`inscriptions.statut` / `.status` et `grades.trimester` / `.trimestre` : le
site public et l'application n'emploient pas le même mot. Les deux colonnes
existent. Les unifier demanderait de reprendre une vingtaine de lectures sur
une application en service — le risque dépasse le bénéfice.

---

## Diagnostic

`diagnostic.html` — 7 tests indépendants, hors du cache du service worker.
Un tampon de version figure sous le titre : sans lui, « rien ne se passe »
reste indécidable.

Ce qu'il vérifie : base joignable · lecture des tables · les neuf colonnes
témoins de la migration · une écriture réelle · le droit d'enregistrer les
réglages · le stockage des photos · la version de `index.html` réellement
servie, avec l'état de la clé et de la passerelle.

Leçons de conception, apprises en le cassant :

- **Un délai d'expiration sur chaque requête.** Sans lui, un appel suspendu
  laisse son test sur « en cours… » et bloque tous les suivants.
- **Jamais `catch {}` sans variable** ni syntaxe postérieure à 2018 : une
  erreur d'analyse rend le bouton inerte sur les WebView Android anciennes.
- **Une sonde ne laisse aucune trace.** La première écrivait dans `audit_log`,
  table volontairement inaltérable — chaque exécution polluait le journal réel
  de l'école. Elle passe par `notifs` et supprime sa ligne.
- **Un dépôt réussi ne prouve pas une lecture possible.** Un bucket privé
  accepte l'écriture et refuse l'affichage : les photos partiraient sans
  jamais apparaître. La sonde relit l'objet par son URL publique.

---

## Compression

`COMPRESS` est la seule référence — modifier un profil suffit à changer le
comportement partout. `_fitImage()` et `_fitDataURL()` remplacent six
implémentations dispersées, dont deux appliquaient `Math.min` séparément à la
largeur et à la hauteur, ce qui **déformait les photos**.

`dlPDF()` alimente tous les documents : compression Flate active, JPEG à 0,82,
et échelle réduite sur les documents longs — à 2×, dix pages produisent un
canvas de plusieurs dizaines de mégapixels qui échoue sur téléphone.

---

## Identité de l'école : une seule source

Neuf documents dupliquaient leur bloc d'identité et **tous oubliaient le
numéro d'agrément DGEP**. `_schoolLine()` est désormais l'unique source ;
`_schoolInfo()` réconcilie les vocabulaires (`motto`/`slogan`,
`name_en`/`sub`, `website`/`site`) car les gabarits de carte et le formulaire
de paramètres n'employaient pas les mêmes noms — des emplacements restaient
vides en permanence.

Avant d'ajouter un champ dans Paramètres, vérifier **où il aboutit**.


---

## Audit page par page (30/07/2026) — normaliseurs nés de l'audit

Quatorze domaines relus un à un, ~145 défauts corrigés. Ce qu'il faut en
retenir pour la suite.

### Les cinq pannes silencieuses les plus coûteuses

| Domaine | Ce qui se passait |
|---------|-------------------|
| Caisse | `parseFloat('12,50')` → **12**. 31 saisies d'argent concernées. |
| Devoirs | `expires_at` écrit en millisecondes, comparé en ISO sur colonne TEXT : le nettoyage hebdomadaire **effaçait tous les devoirs**, serveur compris. |
| Portail | `${JSON.stringify(nom)}` dans un attribut `onclick` en guillemets doubles → la puce d'accompagnant **n'a jamais fonctionné**. |
| Messages | Le destinataire était mis à `null` avant approbation → **aucun message d'enseignant n'atteignait les parents**. |
| Caisse | `year_locked` (année en texte) dans une colonne BOOLEAN → archiver une année **bloquait tout enregistrement de réglages**. |

### Normaliseurs de lecture — le motif à réutiliser

Quand deux générations de code emploient des noms différents, on **réconcilie
à la lecture** plutôt que de reprendre les écritures d'une application en
service :

```js
gTrim(g)                     // grades.trimester | trimestre
_schoolInfo()                // motto|slogan, name_en|sub, website|site
_estBloque(s)                // students.access_blocked | blocked  (blocked jamais écrit)
_msgPourMoi(m,uid,role,cids) // messages : to_class_cid | "class:x" | "role:parent"
_estIncident(l)              // scan_log : tout statut commençant par refused
_cibleFrais(ftId,trim)       // settings.fees fait foi, pas fee_types.montant_defaut
_estExpire(v)                // expires_at : millisecondes héritées ou ISO
_msExpiration(v)             // idem, en millisecondes
```

### Champs morts trouvés — jamais écrits, seulement lus

`students.blocked` (6 lectures) · `messages.to_class` seul · `settings.currentYear`
(cartes de classe). Avant de lire un champ, vérifier qu'**une écriture le
renseigne**.

### Helpers financiers

```js
lireMontant(raw, max)   // « 12,50 » « 1 200 » « 1.200,50 » ; refuse « 1O0 »
_recettes()             // daily_records sans les annulées
_salairesVerses()       // la masse salariale ne passe PAS par daily_expenses
_primesRatDues()        // au tarif enseignant, pas au montant facturé aux familles
_enregistrerMouvement() // SEULE porte d'entrée de l'argent : reçu + recette + OHADA
```

Tout encaissement passe par `_enregistrerMouvement`. Les rattrapages ne le
faisaient pas : l'argent n'apparaissait dans aucun total.

### Gardes de rôle

Toute fonction exposée sur `window` qui écrit doit vérifier `S.user.role`.
Un contrôle dans le *rendu* (`const canModify = …`) n'est pas une sécurité.
L'audit a trouvé une vingtaine de mutations sans garde, dont trois sur les
présences et deux qui manipulaient de l'argent.

---

## Clôture d'année : purger par identifiants, borner par exercice

Dernier domaine audité. Deux principes en sont sortis, valables au-delà.

### On ne purge jamais sur un champ, toujours sur des identifiants

La clôture supprimait les notes du serveur par `year=eq.<année>`. La colonne
existait, mais **seul le panneau de notes la renseignait** : une cote saisie
en corrigeant un devoir avait `year` à NULL. La requête réussissait donc en
ne supprimant rien, et toutes les cotes de devoirs et d'interros revenaient au
premier `loadFromSupabase`, mêlées à celles de la nouvelle année. Mesuré sur
une réplique : **60 notes sur 100 survivaient**. `payments` et `versements`
n'étaient même pas purgées.

L'application détient la liste de ce qu'elle vient d'archiver. Supprimer par
`id=in.(…)`, en lots de 80, supprime exactement cela — ni une ligne de plus,
ni une de moins, et sans dépendre de l'historique d'une colonne.

Conséquence sur `_reappliquerFile` : il ne savait relire que `id=eq.x`. Une
purge en lot n'était pas rejouée, donc un `pull` en pleine clôture ressuscitait
localement ce qui venait d'être supprimé. Il lit désormais les deux formes, et
accepte un `post` dont le corps est un tableau.

### Ce qui ne se supprime pas se borne

`versements`, `daily_reports` et `salaries` survivent volontairement à la
clôture — un reçu remis à une famille, un rapport de caisse validé, une fiche
de paie doivent rester consultables des années après. La table interdit
d'ailleurs la suppression des deux premières.

Ce qui empêche alors l'argent de l'an dernier de reparaître dans la caisse de
septembre n'est pas une purge, c'est **la borne d'exercice** :

```js
_moisExercice(annee)        // « 2025-2026 » → {debut:'2025-09', fin:'2026-08'}
_versementsExercice(annee)  // versements de l'exercice, annulations exclues
_salairesVerses(annee)      // masse salariale de l'exercice
_soldeCaisse(annee)         // {ouverture, recettes, courantes, salaires, depenses, solde}
```

L'année scolaire congolaise court de septembre à août.

### Une seule formule de solde

L'écran de la caisse totalisait les versements **par type de frais actif** ;
la clôture les totalisait tous. Désactiver un type de frais faisait donc
disparaître de l'état financier des recettes bel et bien encaissées, et le
solde reporté ne correspondait à aucun montant jamais affiché. Le classement
par catégorie est désormais une *présentation* du total — jamais son calcul —
avec un panier « Autres » pour ce qui ne se rattache à rien.

Les versements annulés y étaient comptés comme de l'argent ; `_recettes()`
les excluait pourtant déjà pour `daily_records`.

### Archiver n'ouvre pas d'exercice

Deux chemins de clôture coexistaient, chacun à moitié :

| | archive | verrou | purge | report du solde | année suivante |
|---|---|---|---|---|---|
| `archiverAnnee` | oui | oui | non | oui *(à tort)* | non |
| `confirmNewYear` | oui | non | oui | **non** | oui |

`archiverAnnee` reportait le solde sans changer l'année : l'à-nouveau
s'ajoutait à des recettes toujours présentes, et le solde **doublait à chaque
archivage**. `confirmNewYear` ne le reportait pas du tout : toute la trésorerie
accumulée disparaissait des livres au 1er septembre.

Le report appartient à la seule opération qui remet les compteurs à zéro.
`archiverAnnee` archive et verrouille, sans aucun mouvement comptable.

### Diplômé = archivé

`students.diplome` était écrit et **lu nulle part** : l'élève sorti restait
dans sa classe, dans les listes, dans le palmarès et dans les rôles de
paiement de l'année suivante. `archived` est le drapeau que toute
l'application filtre déjà, et l'écran des archives permet de consulter ou de
rétablir. `diplome` en reste le motif, `archived` l'état.

Même famille que les « champs morts » plus haut : **avant de lire un champ,
vérifier qu'une écriture le renseigne ; avant d'en écrire un, vérifier qu'une
lecture s'en sert.**

---

## Le site public et le tableau d'honneur

Cinq pages statiques — `site.html`, `ecole.html`, `programmes.html`,
`galerie.html`, `contact.html` — plus `palmares.html`, déployées sur GitHub
Pages par `.github/workflows/pages.yml`.

### La palette de l'école : gris · blanc · émeraude

Tout est dans `assets/site.css`. **Aucune couleur nouvelle** dans une page
ajoutée : une valeur écrite en dur échappe au prochain réaccord.

```
--emerald #0b5c42  --emerald-deep #063c2b  --emerald-soft #14785a   fonds sombres
--white   #ffffff  --surface      #f4f6f5  --surface-2    #e8ecea   surfaces claires
--accent  #0e7a56  --accent-deep  #095c41  --accent-light #83debc   accents
--ink     #14201c  --muted        #5c6a66  --line rgba(20,32,28,.13)
```

Le site était en **laiton doré sur crème**, et sa variable `--emerald` valait
`#211d17` — un brun sombre, pas un émeraude. Les noms mentaient : `--brass`,
`--cream`, `--paper` sont devenus `--accent`, `--surface`, `--white`, et les
classes `.btn-brass`/`.brass-rule` sont `.btn-accent`/`.accent-rule`.

**Changer les variables ne suffisait pas** : 57 couleurs chaudes étaient
écrites en dur dans le CSS et les pages — elles seraient restées dorées.
La section maternelle avait sa propre palette corail/orange/violet ; elle
tourne désormais autour de l'émeraude, car une section pour enfants a besoin
de variété, pas de discordance.

Contrastes vérifiés : blanc sur émeraude **8,0:1**, accent foncé sur blanc
**8,0:1**, boutons **5,3:1**, texte secondaire **5,7:1**. `--accent-light`
sur `--emerald` était à 4,42:1 — sous le seuil AA — d'où `#83debc` et non
`#6fd3ac`.

Le gris n'est pas neutre pur : une pointe de vert le rattache à l'émeraude,
sans quoi il paraîtrait sale à son contact.

### Une seule adresse

Trois variantes coexistaient — « Kabambare A4, Ndolo », « Kabambare A4,
Quartier Ndolo » — dont aucune n'était la bonne. L'école est au
**Kabambare 4367, Quartier Bon Marché, Commune de Barumbu**. Corrigé en
13 endroits.

Les effectifs de la page d'accueil (« 450+ élèves ») sont désormais un
**repli** : ils sont remplacés par les chiffres réels dès qu'un palmarès est
publié. Deux pages du même site annonçant des nombres différents, une famille
ne sait plus lequel croire.

### La page ne parle pas à la base

`palmares.html` lit **un seul fichier** déposé dans le stockage public quand
la Direction appuie sur « Publier ». Elle n'embarque donc aucune clé et ne
peut rien révéler d'autre que ce que ce fichier contient.

C'est aussi pourquoi la publication est un **acte** et non un flux : les cotes
bougent pendant un trimestre, et un classement en direct montrerait un enfant
premier lundi et quatrième vendredi. On publie après délibération.

```js
_construirePalmaresPublic(trim)  // → l'objet publié, et rien de plus
publierPalmares(trim)            // dépose site/palmares.json
retirerPalmares()                // remplace par {retire:true}
PALMARES_HONNEUR = 3             // lauréats par classe
PALMARES_MARGE   = 3             // élèves qui doivent rester hors du tableau
```

### Un tableau d'honneur n'est pas un classement

Un classement affiché au mur se repeint ; une page publiée est indexée et
suit l'enfant des années. Publier « complet » reviendrait à publier qui est
dernier. Les trois premiers célèbrent sans exposer.

**`PALMARES_MARGE` est la garde qui rend cela vrai.** À trois élèves, « les
trois premiers » EST le classement complet — mesuré sur un jeu d'essai : une
classe de 3 publiait ses 3 élèves, dernier compris. En deçà de
`HONNEUR + MARGE` inscrits, la classe paraît avec ses chiffres et **aucun
nom**. Sur 54 élèves d'essai, 48 ne sont pas nommés.

### Deux pièges éprouvés en l'exécutant

- `/reussi/i` ne reconnaît pas « **Ré**ussi » : le taux ENAFEP tombait à 0 %
  alors que 23 sur 24 avaient réussi. Dépouiller les accents avant de comparer.
- `site.js` observe `.stat .num` et `.reveal` **au chargement**. Les éléments
  nés d'un `fetch` sont ignorés : cette page seule aurait affiché des chiffres
  figés au milieu d'un site animé. Elle rejoue les observateurs sur ce qu'elle
  vient d'insérer, et respecte `prefers-reduced-motion`.

### Le barème de mention, source unique

`_MENTIONS` et `_mention(pct)`. Le même barème était recopié **quatre fois**,
deux rendant `{l,c}` et deux une chaîne. Une cinquième copie subsiste
volontairement, ligne ~15070 : registre plus doux pour UN devoir vu par
l'enfant — « Passable » plutôt qu'« Insuffisant ». Ne pas l'uniformiser.

---

## L'invariant : `DB.<table>` est toujours un tableau

`node tools/audit-invariant.mjs`

Un audit signalait 498 accès « non gardés » à `DB.<table>`. Aucun n'était un
défaut, et poser 498 `|| []` n'aurait rien protégé. La bonne question n'est pas
« chaque accès porte-t-il sa garde ? » mais **« la valeur peut-elle seulement
être autre chose qu'un tableau ? »** Elle ne le peut pas, à trois conditions :

1. Toute table lue est **déclarée** dans `window.DB = { … }`, donc initialisée
   à `[]` au chargement du script.
2. `loadFromCrypt` **fusionne** les clés du cache dans `DB` au lieu de le
   remplacer — une table ajoutée depuis l'écriture du cache garde son `[]`.
3. `safe()` de `loadFromSupabase` renvoie toujours un tableau : la réponse si
   elle en est un, sinon la valeur précédente, sinon `[]`.

L'outil vérifie les trois et sort en erreur si l'une tombe. Il a été éprouvé
dans les deux sens.

Ce qui casse vraiment, c'est une table **lue sans être déclarée**. Ainsi
`DB.exit_scans`, sur la fiche élève : table inexistante en local comme au
serveur, donc `ex` toujours indéfini — la fiche d'un enfant **déjà sorti
affichait encore son heure d'arrivée**. La sortie vit dans `scan_log` avec
`type:'exit'` ; et c'est le *dernier* passage du jour qui dit où est l'enfant,
sorti à midi puis rentré à 14 h.

`tools/audit-nullgard.mjs` a été supprimé : il posait la mauvaise question et
noyait ses rares vrais signaux dans 498 faux.

### Les autres outils

```
tools/audit-schema.mjs      code ↔ SQL — après TOUTE nouvelle écriture
tools/audit-invariant.mjs   les trois conditions ci-dessus
tools/audit-gardes.mjs      mutations `window` sans contrôle de rôle
tools/audit-mort.mjs        fonctions exposées sans appelant
tools/verif-coherence.mjs   la chaîne de calcul, EXÉCUTÉE (voir plus bas)
tools/audit-logo.mjs        l'emblème de l'école sur les 36 documents imprimés
```

`audit-schema` avait un angle mort : il exigeait un littéral comme opération,
donc `pushSync(t, ancien?'patch':'post', obj)` — forme courante — était
**ignoré en entier**. Dix colonnes du cahier de préparation manquaient au
schéma sans qu'il dise un mot. Il accepte désormais une expression
conditionnelle, et **déclare ce qu'il ne sait pas vérifier** au lieu de se
taire.

Corollaire pour le code : ne pas construire l'objet d'une écriture dans une
boucle. `{...etapes}` où `etapes` se remplit par `forEach` est illisible pour
l'analyseur ; les huit rubriques sont donc nommées une à une. **Une écriture
doit rester vérifiable par l'outil qui la surveille.**

`audit-gardes` signale quatre fonctions : `_seedFeeTypes`, `genRecuNo`,
`_bulkLot`, `_materialiserMatieres`. Chacune porte en commentaire la raison
pour laquelle elle n'a pas de garde — amorçage avant connexion, ou découpage
d'une écriture déjà autorisée par son appelant. Ce ne sont pas des défauts en
attente : ne pas les « corriger » à la prochaine passe.

**Une seule implémentation du découpage en lots** : `_bulkLot(table, op,
payload, ids)` → `id=in.(…)` par tranches de 60, identifiants dangereux
écartés. `_patchLot` en est l'enveloppe. La clôture d'année s'en sert aussi.

---

## Cahier de préparation : le canevas EPST

Une fiche de préparation n'est pas un bloc de texte libre. L'inspection
attend l'en-tête républicain, l'identification complète — branche,
sous-branche, effectif, durée, référence au programme national — l'objectif
opérationnel énoncé comme tel, la méthode, et le **déroulement en tableau** :
*Étapes · Durée · Activités de l'enseignant · Activités de l'élève · Points de
matière*. Au pied, trois visas : l'enseignant, le Chef d'établissement,
l'Inspecteur.

`PREP_ETAPES` est la seule liste des huit rubriques du déroulement, dans
l'ordre officiel : révision, motivation, annonce du sujet, analyse, synthèse,
application, conclusion, devoir. `PREP_METHODES` est fermée — un inspecteur
attend un de ces mots.

### Un formulaire, pas deux

Deux écrans écrivaient dans `cahier_prep` avec deux vocabulaires nés à des
époques différentes :

| | écran de navigation | formulaire du profil |
|---|---|---|
| auteur | `by` | `teacher_id` |
| date | `date_prevue` | `date_lesson` |
| état | `status` | `statut` |
| contenu | `content` | rubriques structurées |

Les colonnes des deux existaient, donc rien n'était rejeté — **chaque écran ne
lisait que la moitié de sa table**. Une fiche remplie dans le profil paraissait
au suivi de la Direction sans titre, sans contenu, datée « Invalid Date », et
qu'aucun bouton ne pouvait viser. `openPrepForm`/`savePrep` ont été supprimés ;
`openCahierPrepM(id)` est le seul formulaire, et a hérité du lien à l'emploi
du temps — seule chose que l'autre savait de plus.

`_prepLire(p)` réconcilie à la lecture ce qui reste en base : `_titre`,
`_auteur`, `_date`, `_statut`, `_fait`, `_corps`, `_valide`.

---

## L'emblème sur les documents officiels

`node tools/audit-logo.mjs`

Onze documents sur trente-six sortaient sans le logo — les deux fiches de
paie, les listes ENAFEP et EXÉTAT, la fiche de santé, le kit d'urgence, le
rapport SECOPE, le palmarès annuel, le rapport mensuel, le reçu de paiement.
Rien ne le vérifiait.

`_logoImg(taille, bordure)` est l'unique manière d'en poser un ; il rend une
chaîne vide s'il n'y a pas de logo, plutôt qu'un carré vide.

### Le logo et les coordonnées sont intégrés au fichier

`SCHOOL_LOGO` (512×512, 50 Ko), `ECOLE_ADRESSE`, `ECOLE_TEL`, `ECOLE_EMAIL`
sont des **replis**, au même titre que `ECOLE_NOM` : un reçu ou une
convocation imprimés hors ligne, ou avant la première synchronisation, doivent
déjà porter l'emblème et l'adresse à laquelle une famille peut se présenter.

Le numéro d'agrément DGEP n'y figure pas : il se saisit dans Paramètres, et
une valeur inventée sur un document officiel serait pire que son absence.

**Les replis s'appliquent CHAMP PAR CHAMP**, dans `_schoolInfo()` comme à la
fusion des réglages venus du serveur. Remplacer l'objet `school` en bloc
faisait qu'une ligne enregistrée avec le seul nom effaçait l'adresse, le
téléphone et l'adresse électronique — et le document suivant partait sans
indiquer où se présenter. Une valeur vide côté serveur n'écrase rien ; une
valeur renseignée l'emporte toujours.

---

## La chaîne de calcul : l'exécuter, pas la relire

`node tools/verif-coherence.mjs`

> « Imagine un parent voie les cotes de devoirs de son enfant et les cotes des
> interros, et à la fin son enfant ne réussit pas. »

Tout le reste peut être juste : si les cotes affichées ne font pas la moyenne
affichée, ou si deux écrans classent le même enfant différemment, la famille
cesse d'y croire. L'outil charge les vraies fonctions de `index.html` dans
Node avec un navigateur en carton, leur donne un jeu d'essai dont on connaît
la réponse à la main, et confronte `matAvgPct`, `_totalSection`, `_classer`
et `getSchoolTop10`.

### Ce qu'il a trouvé

`getSchoolTop10` **réimplémentait** la formule de `_classer` au lieu de
l'appeler. Les deux copies avaient divergé sur trois points :

| | `_classer` | copie de `getSchoolTop10` |
|---|---|---|
| conduite | filtrée par trimestre | **toutes époques confondues** |
| élèves archivés | écartés par l'appelant | **inclus** |
| `cid` dans la réponse | oui | **absent** |

Mesuré : un élève excellent au T1 et mauvais au T2 valait **79 au palmarès du
T1 et 73 au Top 10** — premier sur un écran, deuxième sur l'autre. Et le major
diplômé l'an dernier trônait encore en tête de l'école. L'absence de `cid`
vidait le podium de classe de deux tableaux de bord.

**Une seule formule de classement** : `_classer(eleves, matieresDe, trim)` →
`moyenne pondérée × 0,85 + conduite × 0,15`, conduite absente = « Bien »,
ex aequo au même rang. `getSchoolTop10` n'en est plus qu'une présentation.

Même famille que « une seule formule de solde » plus haut. Quand deux écrans
répondent à la même question, ils doivent appeler le même code — pas le
recopier.

---

## État Supabase (30/07/2026)

`supabase_migration_finale.sql` — **exécutée et vérifiée** sur la base de
l'école. 78 colonnes sur 23 tables, `settings.year_locked` passée de BOOLEAN
à TEXT, policies `inscriptions/UPDATE` et `settings/INSERT`, 2 index.

Elle remplace `supabase_fix_columns_v2.sql` et `v3.sql` : ne plus les lancer.
Toute nouvelle colonne s'ajoute **dans ce fichier**, dans la liste de tuples
de la section 1 puis dans les deux blocs de vérification.

`supabase_verification.sql` — 35 lignes, à coller seul dans un onglet **vide**.
Rend « TOUT EST EN PLACE ». Dix colonnes suffisent à prouver l'ensemble : la
boucle qui les ajoute est atomique, une erreur en cours annulerait tout.

### Éprouver une migration avant de la livrer

Le conteneur a PostgreSQL 16. `initdb` refuse de tourner en root — passer par
l'utilisateur `postgres` :

```bash
export PATH=/usr/lib/postgresql/16/bin:$PATH
D=/tmp/pg; rm -rf $D; mkdir -p $D; chown postgres:postgres $D
su postgres -s /bin/bash -c "PATH=$PATH initdb -D $D -U postgres --auth=trust"
su postgres -s /bin/bash -c "PATH=$PATH pg_ctl -D $D -o '-k /tmp -p 55432 -c listen_addresses=' -l $D/log start"
# CREATE ROLE anon;  puis CREATE DATABASE (jamais dans le même -c : transaction)
# rejouer setup + missing_tables + fix_columns → réplique exacte : 49 tables
```

Éprouver **dans les deux sens** : la migration doit dire « incomplet » avant,
« en place » après. Une vérification qui ne sait dire que oui ne vérifie rien.

### La forme d'une migration

Chaque colonne passe par une boucle `DO $$` qui teste d'abord l'existence de sa
table, et **signale** une table absente au lieu d'interrompre. Sans cela un seul
nom divergent fait tout échouer et l'on ignore ce qui est passé.

Attention aux apostrophes dans les types : `JSONB DEFAULT '[]'::jsonb` doit
s'écrire `'JSONB DEFAULT ''[]''::jsonb'` dans le tuple. C'est l'exécution
réelle qui l'a révélé, pas la relecture.

### L'éditeur SQL de Supabase n'affiche que le DERNIER résultat

Un fichier de 480 lignes qui vérifie en son milieu ne montre rien d'utile.
D'où un fichier de vérification séparé — et il faut un **onglet vide** (`+`),
sinon le nouveau texte se colle à la suite de l'ancien.
