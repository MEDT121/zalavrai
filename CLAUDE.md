# SchoolSafe v3.0 — Code Map

**Fichier unique :** `index.html` (~10 600 lignes)  
**École :** Complexe Scolaire Le Sage / The Wise School International (Kinshasa, DRC)  
**Backend :** Supabase (URL + KEY ligne ~880)

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

### Profils (tous en onglets depuis mai 2026)
| Renderer | Ligne | Onglets (défaut en gras) |
|----------|-------|--------------------------|
| `R.profil_direction` | 10190 | **stats** · profil · donnees · securite |
| `R.profil_direction2` | 10289 | **stats** · profil · securite |
| `R.profil_enseignant` | 9429 | **classe** · profil · securite |
| `R.profil_parent` | 9573 | **enfants** · profil · honneur · securite |
| `R.profil_gardien` | 9985 | **activite** · profil · securite |
| `R.profil_caisse` | 10068 | **caisse** · profil · securite |

Fonctions save profil :
- `saveDirProfile('dir1_phone')` / `saveDirProfile('dir2_phone')` → ligne 10357
- `saveTeacherProfile()` → ligne 9511
- `saveParentProfile()` → ligne 9698
- `saveGardienProfile()` → ligne 10053
- `saveCaisseProfile()` → ligne 10139

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
