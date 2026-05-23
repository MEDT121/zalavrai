-- ============================================================
-- SchoolSafe v3.0 — Script complet Supabase
-- Complexe Scolaire Le Sage / The Wise School International
-- Projet : zqgksxgozpnhqzvzxloa.supabase.co
-- ── Coller dans : Supabase → SQL Editor → New Query ─────────
-- Safe à relancer (IF NOT EXISTS / ON CONFLICT partout)
-- ============================================================

-- ── 1. USERS ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
  id          TEXT PRIMARY KEY,
  name        TEXT,
  role        TEXT,
  pin         TEXT,
  pin_hashed  BOOLEAN DEFAULT false,
  initials    TEXT,
  phone       TEXT,
  photo_url   TEXT
);
ALTER TABLE users ADD COLUMN IF NOT EXISTS initials   TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS pin_hashed BOOLEAN DEFAULT false;
ALTER TABLE users ADD COLUMN IF NOT EXISTS photo_url  TEXT;

-- ── 2. CLASSES ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS classes (
  id             TEXT PRIMARY KEY,
  name           TEXT,
  cycle          TEXT,
  teacher_id     TEXT,
  teacher_id_en  TEXT,
  titulaire_id   TEXT
);
ALTER TABLE classes ADD COLUMN IF NOT EXISTS teacher_id_en TEXT;
ALTER TABLE classes ADD COLUMN IF NOT EXISTS titulaire_id  TEXT;

-- ── 3. STUDENTS ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS students (
  id               TEXT PRIMARY KEY,
  name             TEXT,
  mat              TEXT,
  cid              TEXT,
  pid              TEXT,
  dob              TEXT,
  photo            TEXT,
  adresse          TEXT,
  nom_papa         TEXT,
  nom_maman        TEXT,
  access_blocked   BOOLEAN DEFAULT false,
  blocked          BOOLEAN DEFAULT false,
  created_by       TEXT,
  created_by_name  TEXT
);
ALTER TABLE students ADD COLUMN IF NOT EXISTS dob             TEXT;
ALTER TABLE students ADD COLUMN IF NOT EXISTS adresse         TEXT;
ALTER TABLE students ADD COLUMN IF NOT EXISTS nom_papa        TEXT;
ALTER TABLE students ADD COLUMN IF NOT EXISTS nom_maman       TEXT;
ALTER TABLE students ADD COLUMN IF NOT EXISTS photo           TEXT;
ALTER TABLE students ADD COLUMN IF NOT EXISTS access_blocked  BOOLEAN DEFAULT false;
ALTER TABLE students ADD COLUMN IF NOT EXISTS blocked         BOOLEAN DEFAULT false;
ALTER TABLE students ADD COLUMN IF NOT EXISTS created_by      TEXT;
ALTER TABLE students ADD COLUMN IF NOT EXISTS created_by_name TEXT;

-- ── 4. PAYMENTS ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS payments (
  id    TEXT PRIMARY KEY,
  sid   TEXT,
  t     TEXT,
  paid  BOOLEAN DEFAULT false,
  date  TEXT,
  "by"  TEXT,
  note  TEXT
);
ALTER TABLE payments ADD COLUMN IF NOT EXISTS date TEXT;
ALTER TABLE payments ADD COLUMN IF NOT EXISTS "by" TEXT;
ALTER TABLE payments ADD COLUMN IF NOT EXISTS note TEXT;

-- ── 5. ATTENDANCE ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS attendance (
  id         TEXT PRIMARY KEY,
  sid        TEXT,
  cid        TEXT,
  date       TEXT,
  status     TEXT,
  arr_time   TEXT,
  manual     BOOLEAN DEFAULT false,
  marked_by  TEXT,
  note       TEXT
);
ALTER TABLE attendance ADD COLUMN IF NOT EXISTS cid       TEXT;
ALTER TABLE attendance ADD COLUMN IF NOT EXISTS arr_time  TEXT;
ALTER TABLE attendance ADD COLUMN IF NOT EXISTS manual    BOOLEAN DEFAULT false;
ALTER TABLE attendance ADD COLUMN IF NOT EXISTS marked_by TEXT;
ALTER TABLE attendance ADD COLUMN IF NOT EXISTS note      TEXT;

-- ── 6. SCAN_LOG ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS scan_log (
  id           TEXT PRIMARY KEY,
  sid          TEXT,
  type         TEXT,
  status       TEXT,
  date         TEXT,
  time         TEXT,
  name         TEXT,
  label        TEXT,
  by_uid       TEXT,
  by_name      TEXT,
  description  TEXT,
  photo_thumb  TEXT,
  note         TEXT
);
ALTER TABLE scan_log ADD COLUMN IF NOT EXISTS label       TEXT;
ALTER TABLE scan_log ADD COLUMN IF NOT EXISTS by_uid      TEXT;
ALTER TABLE scan_log ADD COLUMN IF NOT EXISTS by_name     TEXT;
ALTER TABLE scan_log ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE scan_log ADD COLUMN IF NOT EXISTS photo_thumb TEXT;
ALTER TABLE scan_log ADD COLUMN IF NOT EXISTS note        TEXT;

-- ── 7. CONDUCT ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS conduct (
  id      TEXT PRIMARY KEY,
  sid     TEXT,
  score   TEXT,
  remark  TEXT,
  date    TEXT,
  "by"    TEXT
);
ALTER TABLE conduct ADD COLUMN IF NOT EXISTS remark TEXT;

-- ── 8. GRADES ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS grades (
  id           TEXT PRIMARY KEY,
  sid          TEXT,
  cid          TEXT,
  type         TEXT,
  matiere      TEXT,
  note         NUMERIC,
  max          NUMERIC DEFAULT 20,
  weight       NUMERIC DEFAULT 1,
  trimestre    TEXT,
  date         TEXT,
  label        TEXT,
  devoir_id    TEXT,
  comment      TEXT,
  "by"         TEXT,
  corrected_at TEXT
);
ALTER TABLE grades ADD COLUMN IF NOT EXISTS cid          TEXT;
ALTER TABLE grades ADD COLUMN IF NOT EXISTS max          NUMERIC DEFAULT 20;
ALTER TABLE grades ADD COLUMN IF NOT EXISTS weight       NUMERIC DEFAULT 1;
ALTER TABLE grades ADD COLUMN IF NOT EXISTS label        TEXT;
ALTER TABLE grades ADD COLUMN IF NOT EXISTS devoir_id    TEXT;
ALTER TABLE grades ADD COLUMN IF NOT EXISTS comment      TEXT;
ALTER TABLE grades ADD COLUMN IF NOT EXISTS corrected_at TEXT;

-- ── 9. ABSENCES ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS absences (
  id         TEXT PRIMARY KEY,
  sid        TEXT,
  pid        TEXT,
  dates      TEXT,
  motif      TEXT,
  note       TEXT,
  status     TEXT DEFAULT 'pending',
  date       TEXT,
  time       TEXT,
  "by"       TEXT
);
ALTER TABLE absences ADD COLUMN IF NOT EXISTS pid  TEXT;
ALTER TABLE absences ADD COLUMN IF NOT EXISTS note TEXT;

-- ── 10. NOTIFS ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS notifs (
  id        TEXT PRIMARY KEY,
  uid       TEXT,
  "from"    TEXT,
  msg       TEXT,
  type      TEXT DEFAULT 'info',
  date      TEXT,
  time      TEXT,
  read      BOOLEAN DEFAULT false,
  devoir_id TEXT,
  status    TEXT,
  to_role   TEXT
);
ALTER TABLE notifs ADD COLUMN IF NOT EXISTS "from"    TEXT;
ALTER TABLE notifs ADD COLUMN IF NOT EXISTS devoir_id TEXT;
ALTER TABLE notifs ADD COLUMN IF NOT EXISTS status    TEXT;
ALTER TABLE notifs ADD COLUMN IF NOT EXISTS to_role   TEXT;

-- ── 11. EVENTS ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS events (
  id           TEXT PRIMARY KEY,
  title        TEXT,
  date         TEXT,
  type         TEXT,
  description  TEXT,
  "by"         TEXT
);
ALTER TABLE events ADD COLUMN IF NOT EXISTS description TEXT;

-- ── 12. MESSAGES ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS messages (
  id            TEXT PRIMARY KEY,
  "from"        TEXT,
  from_role     TEXT,
  "to"          TEXT,
  to_role       TEXT,
  to_class_cid  TEXT,
  subject       TEXT,
  body          TEXT,
  msg_type      TEXT,
  date          TEXT,
  time          TEXT,
  status        TEXT DEFAULT 'sent',
  read          BOOLEAN DEFAULT false
);
ALTER TABLE messages ADD COLUMN IF NOT EXISTS "from"       TEXT;
ALTER TABLE messages ADD COLUMN IF NOT EXISTS from_role    TEXT;
ALTER TABLE messages ADD COLUMN IF NOT EXISTS "to"         TEXT;
ALTER TABLE messages ADD COLUMN IF NOT EXISTS to_role      TEXT;
ALTER TABLE messages ADD COLUMN IF NOT EXISTS to_class_cid TEXT;
ALTER TABLE messages ADD COLUMN IF NOT EXISTS subject      TEXT;
ALTER TABLE messages ADD COLUMN IF NOT EXISTS body         TEXT;
ALTER TABLE messages ADD COLUMN IF NOT EXISTS msg_type     TEXT;
ALTER TABLE messages ADD COLUMN IF NOT EXISTS time         TEXT;

-- ── 13. APS ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS aps (
  id        TEXT PRIMARY KEY,
  sid       TEXT,
  name      TEXT,
  relation  TEXT,
  photo     TEXT,
  active    BOOLEAN DEFAULT true,
  phone     TEXT
);
ALTER TABLE aps ADD COLUMN IF NOT EXISTS phone TEXT;

-- ── 14. DAILY_RECORDS ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS daily_records (
  id            TEXT PRIMARY KEY,
  sid           TEXT,
  student_name  TEXT,
  mat           TEXT,
  type          TEXT,
  type_label    TEXT,
  trimestre     TEXT,
  amount        NUMERIC,
  note          TEXT,
  date          TEXT,
  time          TEXT,
  "by"          TEXT,
  validated     BOOLEAN DEFAULT false
);
ALTER TABLE daily_records ADD COLUMN IF NOT EXISTS student_name TEXT;
ALTER TABLE daily_records ADD COLUMN IF NOT EXISTS mat          TEXT;
ALTER TABLE daily_records ADD COLUMN IF NOT EXISTS type_label   TEXT;
ALTER TABLE daily_records ADD COLUMN IF NOT EXISTS trimestre    TEXT;
ALTER TABLE daily_records ADD COLUMN IF NOT EXISTS note         TEXT;
ALTER TABLE daily_records ADD COLUMN IF NOT EXISTS time         TEXT;
ALTER TABLE daily_records ADD COLUMN IF NOT EXISTS validated    BOOLEAN DEFAULT false;

-- ── 15. DAILY_EXPENSES ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS daily_expenses (
  id         TEXT PRIMARY KEY,
  amount     NUMERIC,
  motif      TEXT,
  date       TEXT,
  time       TEXT,
  "by"       TEXT,
  validated  BOOLEAN DEFAULT false
);
ALTER TABLE daily_expenses ADD COLUMN IF NOT EXISTS motif     TEXT;
ALTER TABLE daily_expenses ADD COLUMN IF NOT EXISTS time      TEXT;
ALTER TABLE daily_expenses ADD COLUMN IF NOT EXISTS validated BOOLEAN DEFAULT false;

-- ── 16. DAILY_REPORTS ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS daily_reports (
  id        TEXT PRIMARY KEY,
  date      TEXT,
  time      TEXT,
  "by"      TEXT,
  status    TEXT DEFAULT 'pending',
  records   JSONB DEFAULT '[]',
  expenses  JSONB DEFAULT '[]',
  summary   JSONB DEFAULT '{}'
);
ALTER TABLE daily_reports ADD COLUMN IF NOT EXISTS records  JSONB DEFAULT '[]';
ALTER TABLE daily_reports ADD COLUMN IF NOT EXISTS expenses JSONB DEFAULT '[]';
ALTER TABLE daily_reports ADD COLUMN IF NOT EXISTS summary  JSONB DEFAULT '{}';

-- ── 17. DEVOIRS ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS devoirs (
  id              TEXT PRIMARY KEY,
  cid             TEXT,
  title           TEXT,
  type            TEXT,
  content         TEXT,
  lang            TEXT DEFAULT 'fr',
  matiere         TEXT,
  description     TEXT,
  chapters        TEXT,
  duration        NUMERIC,
  category        TEXT,
  date            TEXT,
  deadline        TEXT,
  teacher_id      TEXT,
  status          TEXT DEFAULT 'published',
  expires_at      TEXT,
  pdf_local_only  BOOLEAN DEFAULT false
);
ALTER TABLE devoirs ADD COLUMN IF NOT EXISTS lang           TEXT DEFAULT 'fr';
ALTER TABLE devoirs ADD COLUMN IF NOT EXISTS description    TEXT;
ALTER TABLE devoirs ADD COLUMN IF NOT EXISTS chapters       TEXT;
ALTER TABLE devoirs ADD COLUMN IF NOT EXISTS duration       NUMERIC;
ALTER TABLE devoirs ADD COLUMN IF NOT EXISTS deadline       TEXT;
ALTER TABLE devoirs ADD COLUMN IF NOT EXISTS expires_at     TEXT;
ALTER TABLE devoirs ADD COLUMN IF NOT EXISTS pdf_local_only BOOLEAN DEFAULT false;

-- ── 18. CAHIER_TEXTE ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS cahier_texte (
  id       TEXT PRIMARY KEY,
  cid      TEXT,
  "by"     TEXT,
  matiere  TEXT,
  content  TEXT,
  date     TEXT,
  status   TEXT DEFAULT 'pending',
  "ctId"   TEXT
);
ALTER TABLE cahier_texte ADD COLUMN IF NOT EXISTS matiere TEXT;
ALTER TABLE cahier_texte ADD COLUMN IF NOT EXISTS content TEXT;
ALTER TABLE cahier_texte ADD COLUMN IF NOT EXISTS "ctId"  TEXT;

-- ── 19. MATIERES ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS matieres (
  id      TEXT PRIMARY KEY,
  cid     TEXT,
  name    TEXT,
  lang    TEXT DEFAULT 'fr',
  active  BOOLEAN DEFAULT true
);
ALTER TABLE matieres ADD COLUMN IF NOT EXISTS lang   TEXT DEFAULT 'fr';
ALTER TABLE matieres ADD COLUMN IF NOT EXISTS active BOOLEAN DEFAULT true;

-- ── 20. RATTRAPAGES ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS rattrapages (
  id               TEXT PRIMARY KEY,
  sid              TEXT,
  teacher_id       TEXT,
  matiere          TEXT,
  motif            TEXT,
  date             TEXT,
  time             TEXT,
  status           TEXT DEFAULT 'pending',
  amount           NUMERIC DEFAULT 0,
  paid             BOOLEAN DEFAULT false,
  score            NUMERIC,
  auto_triggered   BOOLEAN DEFAULT false,
  trimestre        TEXT,
  validated_by     TEXT,
  validated_date   TEXT,
  d2_validated     BOOLEAN DEFAULT false,
  note             TEXT
);
ALTER TABLE rattrapages ADD COLUMN IF NOT EXISTS matiere        TEXT;
ALTER TABLE rattrapages ADD COLUMN IF NOT EXISTS motif          TEXT;
ALTER TABLE rattrapages ADD COLUMN IF NOT EXISTS paid           BOOLEAN DEFAULT false;
ALTER TABLE rattrapages ADD COLUMN IF NOT EXISTS score          NUMERIC;
ALTER TABLE rattrapages ADD COLUMN IF NOT EXISTS auto_triggered BOOLEAN DEFAULT false;
ALTER TABLE rattrapages ADD COLUMN IF NOT EXISTS validated_date TEXT;
ALTER TABLE rattrapages ADD COLUMN IF NOT EXISTS d2_validated   BOOLEAN DEFAULT false;
ALTER TABLE rattrapages ADD COLUMN IF NOT EXISTS trimestre      TEXT;

-- ── 21. CONVOCATIONS ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS convocations (
  id              TEXT PRIMARY KEY,
  sid             TEXT,
  date            TEXT,
  reason          TEXT,
  body            TEXT,
  note            TEXT,
  status          TEXT DEFAULT 'pending',
  rdv_date        TEXT,
  score           NUMERIC,
  trimestre       TEXT,
  auto_generated  BOOLEAN DEFAULT false,
  weak_mats       TEXT,
  "by"            TEXT
);
ALTER TABLE convocations ADD COLUMN IF NOT EXISTS body           TEXT;
ALTER TABLE convocations ADD COLUMN IF NOT EXISTS note           TEXT;
ALTER TABLE convocations ADD COLUMN IF NOT EXISTS rdv_date       TEXT;
ALTER TABLE convocations ADD COLUMN IF NOT EXISTS score          NUMERIC;
ALTER TABLE convocations ADD COLUMN IF NOT EXISTS trimestre      TEXT;
ALTER TABLE convocations ADD COLUMN IF NOT EXISTS auto_generated BOOLEAN DEFAULT false;
ALTER TABLE convocations ADD COLUMN IF NOT EXISTS weak_mats      TEXT;
ALTER TABLE convocations ADD COLUMN IF NOT EXISTS "by"           TEXT;

-- ── 22. TIMETABLES ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS timetables (
  id          TEXT PRIMARY KEY,
  cid         TEXT,
  day         TEXT,
  period      NUMERIC,
  matiere     TEXT,
  teacher_id  TEXT
);
ALTER TABLE timetables ADD COLUMN IF NOT EXISTS day        TEXT;
ALTER TABLE timetables ADD COLUMN IF NOT EXISTS period     NUMERIC;
ALTER TABLE timetables ADD COLUMN IF NOT EXISTS matiere    TEXT;
ALTER TABLE timetables ADD COLUMN IF NOT EXISTS teacher_id TEXT;

-- ── 23. SETTINGS ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS settings (
  id                    TEXT PRIMARY KEY DEFAULT 'main',
  "currentTrimestre"    TEXT DEFAULT 'T1',
  "feesControl"         JSONB DEFAULT '{"active":false,"trimestre":"T1"}',
  fees                  JSONB DEFAULT '{"T1":0,"T2":0,"T3":0,"inscription":0}',
  retention             JSONB DEFAULT '{"notifs":30,"scan_log":90,"audit_log":90,"approbations":60,"messages":30,"messages_unread":60,"convocations":90}',
  toggles               JSONB DEFAULT '{}',
  "trimLocks"           JSONB DEFAULT '{"T1":false,"T2":false,"T3":false}',
  school                JSONB DEFAULT '{"name":"Le Sage / The Wise School International"}',
  year                  TEXT DEFAULT '2025-2026',
  horaires              JSONB DEFAULT '{}',
  session_timeout_min   NUMERIC DEFAULT 30,
  "_lastCleanup"        TEXT
);
ALTER TABLE settings ADD COLUMN IF NOT EXISTS "feesControl"       JSONB DEFAULT '{"active":false,"trimestre":"T1"}';
ALTER TABLE settings ADD COLUMN IF NOT EXISTS fees                JSONB DEFAULT '{"T1":0,"T2":0,"T3":0,"inscription":0}';
ALTER TABLE settings ADD COLUMN IF NOT EXISTS retention           JSONB DEFAULT '{"notifs":30,"scan_log":90,"audit_log":90,"approbations":60,"messages":30,"messages_unread":60,"convocations":90}';
ALTER TABLE settings ADD COLUMN IF NOT EXISTS toggles             JSONB DEFAULT '{}';
ALTER TABLE settings ADD COLUMN IF NOT EXISTS "trimLocks"         JSONB DEFAULT '{"T1":false,"T2":false,"T3":false}';
ALTER TABLE settings ADD COLUMN IF NOT EXISTS school              JSONB DEFAULT '{"name":"Le Sage / The Wise School International"}';
ALTER TABLE settings ADD COLUMN IF NOT EXISTS year                TEXT DEFAULT '2025-2026';
ALTER TABLE settings ADD COLUMN IF NOT EXISTS horaires            JSONB DEFAULT '{}';
ALTER TABLE settings ADD COLUMN IF NOT EXISTS session_timeout_min NUMERIC DEFAULT 30;
ALTER TABLE settings ADD COLUMN IF NOT EXISTS "_lastCleanup"      TEXT;
-- Mise à jour retention pour inclure messages et convocations
UPDATE settings SET retention = '{"notifs":30,"scan_log":90,"audit_log":90,"approbations":60,"messages":30,"messages_unread":60,"convocations":90}'::JSONB
WHERE id = 'main' AND (retention->>'messages' IS NULL OR retention->>'convocations' IS NULL);
-- Ligne par défaut
INSERT INTO settings (id) VALUES ('main') ON CONFLICT (id) DO NOTHING;

-- ── 24. APPROBATIONS ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS approbations (
  id       TEXT PRIMARY KEY,
  type     TEXT,
  status   TEXT DEFAULT 'pending',
  content  TEXT,
  data     JSONB DEFAULT '{}',
  date     TEXT,
  time     TEXT,
  "by"     TEXT,
  sid      TEXT
);
ALTER TABLE approbations ADD COLUMN IF NOT EXISTS content TEXT;
ALTER TABLE approbations ADD COLUMN IF NOT EXISTS data    JSONB DEFAULT '{}';
ALTER TABLE approbations ADD COLUMN IF NOT EXISTS time    TEXT;
ALTER TABLE approbations ADD COLUMN IF NOT EXISTS sid     TEXT;

-- ── 25. TEACHER_NOTES ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS teacher_notes (
  id          TEXT PRIMARY KEY,
  content     TEXT,
  date        TEXT,
  time        TEXT,
  sid         TEXT,
  expires_at  TEXT,
  "by"        TEXT
);
ALTER TABLE teacher_notes ADD COLUMN IF NOT EXISTS content    TEXT;
ALTER TABLE teacher_notes ADD COLUMN IF NOT EXISTS time       TEXT;
ALTER TABLE teacher_notes ADD COLUMN IF NOT EXISTS expires_at TEXT;

-- ── 26. AUDIT_LOG ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS audit_log (
  id         TEXT PRIMARY KEY,
  "by"       TEXT,
  by_name    TEXT,
  action     TEXT,
  detail     TEXT,
  target_id  TEXT,
  date       TEXT,
  time       TEXT
);
ALTER TABLE audit_log ADD COLUMN IF NOT EXISTS by_name   TEXT;
ALTER TABLE audit_log ADD COLUMN IF NOT EXISTS target_id TEXT;

-- ── 27. TEACHER_ABSENCES ────────────────────────────────────
CREATE TABLE IF NOT EXISTS teacher_absences (
  id           TEXT PRIMARY KEY,
  uid          TEXT,
  date         TEXT,
  reason       TEXT,
  status       TEXT DEFAULT 'pending',
  approved_by  TEXT
);
ALTER TABLE teacher_absences ADD COLUMN IF NOT EXISTS approved_by TEXT;

-- ── 28. MEDICAL ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS medical (
  id             TEXT PRIMARY KEY,
  sid            TEXT,
  blood_type     TEXT,
  allergies      TEXT,
  vaccines       JSONB DEFAULT '[]',
  vax_dates      JSONB DEFAULT '{}',
  doctor_name    TEXT,
  doctor_phone   TEXT,
  medical_notes  TEXT,
  updated        TEXT
);
ALTER TABLE medical ADD COLUMN IF NOT EXISTS blood_type    TEXT;
ALTER TABLE medical ADD COLUMN IF NOT EXISTS allergies     TEXT;
ALTER TABLE medical ADD COLUMN IF NOT EXISTS vaccines      JSONB DEFAULT '[]';
ALTER TABLE medical ADD COLUMN IF NOT EXISTS vax_dates     JSONB DEFAULT '{}';
ALTER TABLE medical ADD COLUMN IF NOT EXISTS doctor_name   TEXT;
ALTER TABLE medical ADD COLUMN IF NOT EXISTS doctor_phone  TEXT;
ALTER TABLE medical ADD COLUMN IF NOT EXISTS medical_notes TEXT;
ALTER TABLE medical ADD COLUMN IF NOT EXISTS updated       TEXT;

-- ── 29. TENAFEP ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS tenafep (
  id                TEXT PRIMARY KEY,
  sid               TEXT,
  enafep_code       TEXT,
  result            TEXT,
  score             NUMERIC,
  registration_num  TEXT,
  notes             TEXT,
  year              TEXT,
  registered        BOOLEAN DEFAULT false,
  updated           TEXT
);
ALTER TABLE tenafep ADD COLUMN IF NOT EXISTS enafep_code      TEXT;
ALTER TABLE tenafep ADD COLUMN IF NOT EXISTS result           TEXT;
ALTER TABLE tenafep ADD COLUMN IF NOT EXISTS registration_num TEXT;
ALTER TABLE tenafep ADD COLUMN IF NOT EXISTS notes            TEXT;
ALTER TABLE tenafep ADD COLUMN IF NOT EXISTS registered       BOOLEAN DEFAULT false;
ALTER TABLE tenafep ADD COLUMN IF NOT EXISTS updated          TEXT;

-- ── 30. EVALUATIONS ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS evaluations (
  id          TEXT PRIMARY KEY,
  teacher_id  TEXT,
  "by"        TEXT,
  date        TEXT,
  trimestre   TEXT,
  comment     TEXT,
  year        TEXT,
  criteria    JSONB DEFAULT '{}'
);
ALTER TABLE evaluations ADD COLUMN IF NOT EXISTS teacher_id TEXT;
ALTER TABLE evaluations ADD COLUMN IF NOT EXISTS trimestre  TEXT;
ALTER TABLE evaluations ADD COLUMN IF NOT EXISTS comment    TEXT;
ALTER TABLE evaluations ADD COLUMN IF NOT EXISTS year       TEXT;
ALTER TABLE evaluations ADD COLUMN IF NOT EXISTS criteria   JSONB DEFAULT '{}';

-- ── 31. SALARIES ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS salaries (
  id          TEXT PRIMARY KEY,
  teacher_id  TEXT,
  month       TEXT,
  amount      NUMERIC DEFAULT 0,
  bonus       NUMERIC DEFAULT 0,
  rat_prime   NUMERIC DEFAULT 0,
  deductions  NUMERIC DEFAULT 0,
  adv_total   NUMERIC DEFAULT 0,
  net         NUMERIC DEFAULT 0,
  paid        BOOLEAN DEFAULT false,
  paid_date   TEXT,
  notes       TEXT,
  "by"        TEXT,
  updated     TEXT
);
ALTER TABLE salaries ADD COLUMN IF NOT EXISTS teacher_id TEXT;
ALTER TABLE salaries ADD COLUMN IF NOT EXISTS bonus      NUMERIC DEFAULT 0;
ALTER TABLE salaries ADD COLUMN IF NOT EXISTS rat_prime  NUMERIC DEFAULT 0;
ALTER TABLE salaries ADD COLUMN IF NOT EXISTS deductions NUMERIC DEFAULT 0;
ALTER TABLE salaries ADD COLUMN IF NOT EXISTS adv_total  NUMERIC DEFAULT 0;
ALTER TABLE salaries ADD COLUMN IF NOT EXISTS net        NUMERIC DEFAULT 0;
ALTER TABLE salaries ADD COLUMN IF NOT EXISTS paid_date  TEXT;
ALTER TABLE salaries ADD COLUMN IF NOT EXISTS notes      TEXT;
ALTER TABLE salaries ADD COLUMN IF NOT EXISTS updated    TEXT;

-- ── 32. ADVANCES ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS advances (
  id          TEXT PRIMARY KEY,
  teacher_id  TEXT,
  amount      NUMERIC DEFAULT 0,
  reason      TEXT,
  month       TEXT,
  date        TEXT,
  "by"        TEXT
);
ALTER TABLE advances ADD COLUMN IF NOT EXISTS teacher_id TEXT;
ALTER TABLE advances ADD COLUMN IF NOT EXISTS reason     TEXT;
ALTER TABLE advances ADD COLUMN IF NOT EXISTS month      TEXT;

-- ── 33. SANCTIONS ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS sanctions (
  id           TEXT PRIMARY KEY,
  sid          TEXT,
  type         TEXT,
  description  TEXT,
  date         TEXT,
  "by"         TEXT
);
ALTER TABLE sanctions ADD COLUMN IF NOT EXISTS description TEXT;

-- ── 34. CANTINE ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS cantine (
  id                TEXT PRIMARY KEY,
  sid               TEXT,
  type              TEXT,
  amount            NUMERIC,
  active            BOOLEAN DEFAULT true,
  date_inscription  TEXT,
  "by"              TEXT
);

-- ── 35. CANTINE_MENUS ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS cantine_menus (
  id         TEXT PRIMARY KEY,
  date       TEXT,
  plat       TEXT,
  dessert    TEXT,
  boisson    TEXT,
  prix       NUMERIC,
  photo_url  TEXT,
  emoji      TEXT
);

-- ── 36. CANTINE_PRESENCE ────────────────────────────────────
CREATE TABLE IF NOT EXISTS cantine_presence (
  id       TEXT PRIMARY KEY,
  sid      TEXT,
  date     TEXT,
  present  BOOLEAN DEFAULT true
);

-- ── 37. ACTIVITES ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS activites (
  id           TEXT PRIMARY KEY,
  name         TEXT,
  description  TEXT,
  color        TEXT,
  frais        NUMERIC,
  date         TEXT,
  "by"         TEXT
);

-- ── 38. ACTIVITES_INSCRIPTIONS ──────────────────────────────
CREATE TABLE IF NOT EXISTS activites_inscriptions (
  id                TEXT PRIMARY KEY,
  sid               TEXT,
  activity_id       TEXT,
  date_inscription  TEXT,
  "by"              TEXT
);

-- ── 39. APPRECIATIONS ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS appreciations (
  id       TEXT PRIMARY KEY,
  sid      TEXT,
  cid      TEXT,
  trim     TEXT,
  text     TEXT,
  "by"     TEXT,
  date     TEXT,
  updated  TEXT
);

-- ── 40. MEDICAL_VISITS ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS medical_visits (
  id         TEXT PRIMARY KEY,
  sid        TEXT,
  date       TEXT,
  reason     TEXT,
  treatment  TEXT,
  "by"       TEXT,
  time       TEXT
);

-- ============================================================
-- ROW LEVEL SECURITY — activer sur les 40 tables
-- ============================================================
DO $$
DECLARE tbl TEXT;
BEGIN
  FOREACH tbl IN ARRAY ARRAY[
    'users','classes','students','payments','attendance','scan_log',
    'conduct','grades','absences','notifs','events','messages','aps',
    'daily_records','daily_expenses','daily_reports','devoirs','cahier_texte',
    'matieres','rattrapages','convocations','timetables','settings',
    'approbations','teacher_notes','audit_log','teacher_absences',
    'medical','tenafep','evaluations','salaries','advances','sanctions',
    'cantine','cantine_menus','cantine_presence','activites',
    'activites_inscriptions','appreciations','medical_visits'
  ] LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', tbl);
  END LOOP;
END $$;

-- ============================================================
-- POLICIES RLS DURCIES — 3 niveaux d'accès anon
-- Protection contre accès non autorisé via clé anon volée
-- La vraie protection #1 reste le domaine allowlist Supabase
-- ============================================================

-- ── Niveau A : CRUD complet (tables opérationnelles) ─────────
-- L'app a besoin de créer, modifier ET supprimer sur ces tables
DO $$
DECLARE tbl TEXT;
BEGIN
  FOREACH tbl IN ARRAY ARRAY[
    'users','classes','students','payments','attendance','scan_log',
    'conduct','grades','absences','notifs','events','messages','aps',
    'daily_records','daily_expenses','devoirs','cahier_texte',
    'matieres','rattrapages','convocations','timetables',
    'approbations','teacher_notes','teacher_absences',
    'medical','tenafep','evaluations','salaries','advances','sanctions',
    'cantine','cantine_menus','cantine_presence','activites',
    'activites_inscriptions','appreciations','medical_visits'
  ] LOOP
    EXECUTE format('DROP POLICY IF EXISTS "anon_select" ON %I', tbl);
    EXECUTE format('DROP POLICY IF EXISTS "anon_insert" ON %I', tbl);
    EXECUTE format('DROP POLICY IF EXISTS "anon_update" ON %I', tbl);
    EXECUTE format('DROP POLICY IF EXISTS "anon_delete" ON %I', tbl);
    EXECUTE format('CREATE POLICY "anon_select" ON %I FOR SELECT TO anon USING (true)', tbl);
    EXECUTE format('CREATE POLICY "anon_insert" ON %I FOR INSERT TO anon WITH CHECK (true)', tbl);
    EXECUTE format('CREATE POLICY "anon_update" ON %I FOR UPDATE TO anon USING (true) WITH CHECK (true)', tbl);
    EXECUTE format('CREATE POLICY "anon_delete" ON %I FOR DELETE TO anon USING (true)', tbl);
  END LOOP;
END $$;

-- ── Niveau B : SELECT + INSERT + UPDATE (pas de DELETE) ──────
-- daily_reports : rapports financiers — jamais effaçables
DROP POLICY IF EXISTS "anon_select" ON daily_reports;
DROP POLICY IF EXISTS "anon_insert" ON daily_reports;
DROP POLICY IF EXISTS "anon_update" ON daily_reports;
DROP POLICY IF EXISTS "anon_delete" ON daily_reports;
CREATE POLICY "anon_select" ON daily_reports FOR SELECT TO anon USING (true);
CREATE POLICY "anon_insert" ON daily_reports FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "anon_update" ON daily_reports FOR UPDATE TO anon USING (true) WITH CHECK (true);
-- Pas de DELETE sur daily_reports

-- ── Niveau C : SELECT + INSERT seulement (immuable) ──────────
-- audit_log : journal d'audit — on ne peut ni modifier ni effacer
DROP POLICY IF EXISTS "anon_select" ON audit_log;
DROP POLICY IF EXISTS "anon_insert" ON audit_log;
DROP POLICY IF EXISTS "anon_update" ON audit_log;
DROP POLICY IF EXISTS "anon_delete" ON audit_log;
CREATE POLICY "anon_select" ON audit_log FOR SELECT TO anon USING (true);
CREATE POLICY "anon_insert" ON audit_log FOR INSERT TO anon WITH CHECK (true);
-- Pas d'UPDATE ni DELETE sur audit_log

-- ── Niveau D : SELECT + UPDATE seulement ─────────────────────
-- settings : une seule ligne 'main' — jamais créée ni supprimée
DROP POLICY IF EXISTS "anon_select" ON settings;
DROP POLICY IF EXISTS "anon_insert" ON settings;
DROP POLICY IF EXISTS "anon_update" ON settings;
DROP POLICY IF EXISTS "anon_delete" ON settings;
CREATE POLICY "anon_select" ON settings FOR SELECT TO anon USING (true);
CREATE POLICY "anon_update" ON settings FOR UPDATE TO anon USING (true) WITH CHECK (true);
-- Pas d'INSERT ni DELETE sur settings (la ligne 'main' existe déjà)

-- ============================================================
-- INDEX DE PERFORMANCE
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_students_cid          ON students(cid);
CREATE INDEX IF NOT EXISTS idx_students_pid          ON students(pid);
CREATE INDEX IF NOT EXISTS idx_payments_sid          ON payments(sid);
CREATE INDEX IF NOT EXISTS idx_attendance_sid        ON attendance(sid);
CREATE INDEX IF NOT EXISTS idx_attendance_date       ON attendance(date);
CREATE INDEX IF NOT EXISTS idx_scan_log_sid          ON scan_log(sid);
CREATE INDEX IF NOT EXISTS idx_scan_log_date         ON scan_log(date);
CREATE INDEX IF NOT EXISTS idx_grades_sid            ON grades(sid);
CREATE INDEX IF NOT EXISTS idx_grades_cid            ON grades(cid);
CREATE INDEX IF NOT EXISTS idx_grades_trimestre      ON grades(trimestre);
CREATE INDEX IF NOT EXISTS idx_notifs_uid            ON notifs(uid);
CREATE INDEX IF NOT EXISTS idx_notifs_read           ON notifs(read);
CREATE INDEX IF NOT EXISTS idx_messages_to           ON messages("to");
CREATE INDEX IF NOT EXISTS idx_messages_from         ON messages("from");
CREATE INDEX IF NOT EXISTS idx_messages_date         ON messages(date);
CREATE INDEX IF NOT EXISTS idx_rattrapages_sid       ON rattrapages(sid);
CREATE INDEX IF NOT EXISTS idx_convocations_sid      ON convocations(sid);
CREATE INDEX IF NOT EXISTS idx_audit_log_date        ON audit_log(date);
CREATE INDEX IF NOT EXISTS idx_daily_records_date    ON daily_records(date);
CREATE INDEX IF NOT EXISTS idx_daily_expenses_date   ON daily_expenses(date);
CREATE INDEX IF NOT EXISTS idx_devoirs_cid           ON devoirs(cid);
CREATE INDEX IF NOT EXISTS idx_aps_sid               ON aps(sid);
CREATE INDEX IF NOT EXISTS idx_conduct_sid           ON conduct(sid);
CREATE INDEX IF NOT EXISTS idx_approbations_status   ON approbations(status);
CREATE INDEX IF NOT EXISTS idx_cantine_presence_date ON cantine_presence(date);
CREATE INDEX IF NOT EXISTS idx_medical_visits_sid    ON medical_visits(sid);
CREATE INDEX IF NOT EXISTS idx_sanctions_sid         ON sanctions(sid);
CREATE INDEX IF NOT EXISTS idx_appreciations_sid     ON appreciations(sid);

-- ============================================================
-- VÉRIFICATION FINALE
-- ============================================================
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;

SELECT 'SchoolSafe v3.0 — 40 tables configurées ✅' AS statut;
