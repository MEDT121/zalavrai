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
- `saveDir1Profile()` / `saveDir2Profile()` (+ wrapper `saveDirProfile(inputId)`) → ligne 15955
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
- **Toujours** `DB.xxx || []` avant `.filter()` / `.length` (null guard)
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
