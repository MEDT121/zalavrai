-- ============================================================
-- SchoolSafe v3.0 — Script de création Supabase
-- Complexe Scolaire Le Sage / The Wise School International
-- Copiez-collez ce script dans : Supabase → SQL Editor → New Query
-- ============================================================

-- ── USERS ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
  id          TEXT PRIMARY KEY,
  name        TEXT NOT NULL,
  role        TEXT NOT NULL,        -- direction|direction2|direction3|enseignant|parent|gardien
  pin         TEXT,
  pin_hashed  BOOLEAN DEFAULT false,
  initials    TEXT,
  phone       TEXT,
  photo_url   TEXT,
  lang        TEXT DEFAULT 'fr',    -- fr|en (enseignants)
  class_id    TEXT
);

-- ── CLASSES ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS classes (
  id              TEXT PRIMARY KEY,
  name            TEXT NOT NULL,
  cycle           TEXT,             -- maternelle|primaire|secondaire
  teacher_id      TEXT,
  teacher_id_en   TEXT,
  titulaire_id    TEXT
);

-- ── STUDENTS ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS students (
  id              TEXT PRIMARY KEY,
  name            TEXT NOT NULL,
  mat             TEXT UNIQUE,
  cid             TEXT,             -- class id
  pid             TEXT,             -- parent user id
  dob             TEXT,
  photo           TEXT,             -- base64
  photo_url       TEXT,
  adresse         TEXT,
  nom_papa        TEXT,
  nom_maman       TEXT,
  access_parent   BOOLEAN DEFAULT false,
  access_blocked  BOOLEAN DEFAULT false,
  blocked         BOOLEAN DEFAULT false
);

-- ── PAYMENTS ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS payments (
  id    TEXT PRIMARY KEY,
  sid   TEXT NOT NULL,
  t     TEXT NOT NULL,   -- T1|T2|T3|inscription
  paid  BOOLEAN DEFAULT false,
  date  TEXT,
  by    TEXT,
  note  TEXT
);

-- ── ATTENDANCE ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS attendance (
  id                 TEXT PRIMARY KEY,
  sid                TEXT NOT NULL,
  cid                TEXT,
  date               TEXT NOT NULL,
  status             TEXT,          -- ontime|late|absent
  arr_time           TEXT,
  teacher_validated  BOOLEAN DEFAULT false,
  by                 TEXT
);
CREATE INDEX IF NOT EXISTS idx_attendance_date ON attendance(date);
CREATE INDEX IF NOT EXISTS idx_attendance_sid  ON attendance(sid);

-- ── SCAN LOG ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS scan_log (
  id      TEXT PRIMARY KEY,
  sid     TEXT,
  type    TEXT,    -- entry|exit
  status  TEXT,
  date    TEXT NOT NULL,
  time    TEXT,
  name    TEXT,
  label   TEXT
);
CREATE INDEX IF NOT EXISTS idx_scan_log_date ON scan_log(date);

-- ── GRADES ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS grades (
  id          TEXT PRIMARY KEY,
  sid         TEXT NOT NULL,
  matiere     TEXT,
  note        NUMERIC,
  max_note    NUMERIC DEFAULT 10,
  type        TEXT,    -- examen|devoir|interrogation|pratique
  trimestre   TEXT,    -- T1|T2|T3
  date        TEXT,
  by          TEXT
);
CREATE INDEX IF NOT EXISTS idx_grades_sid ON grades(sid);

-- ── CONDUCT ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS conduct (
  id      TEXT PRIMARY KEY,
  sid     TEXT NOT NULL,
  score   TEXT,    -- Excellent|Bien|Moyen|Mauvais
  remark  TEXT,
  date    TEXT,
  by      TEXT
);

-- ── ABSENCES (justifications) ──────────────────────────────
CREATE TABLE IF NOT EXISTS absences (
  id      TEXT PRIMARY KEY,
  sid     TEXT,
  pid     TEXT,
  dates   TEXT,
  motif   TEXT,
  status  TEXT DEFAULT 'pending',   -- pending|approved|refused
  date    TEXT,
  time    TEXT,
  by      TEXT
);

-- ── NOTIFICATIONS ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS notifs (
  id    TEXT PRIMARY KEY,
  uid   TEXT NOT NULL,
  msg   TEXT,
  date  TEXT,
  time  TEXT,
  read  BOOLEAN DEFAULT false,
  type  TEXT,
  by    TEXT
);
CREATE INDEX IF NOT EXISTS idx_notifs_uid ON notifs(uid);

-- ── EVENTS / CALENDAR ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS events (
  id           TEXT PRIMARY KEY,
  title        TEXT,
  date         TEXT,
  type         TEXT,
  description  TEXT,
  by           TEXT
);

-- ── MESSAGES ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS messages (
  id       TEXT PRIMARY KEY,
  from_id  TEXT,
  to_id    TEXT,
  to_role  TEXT,
  content  TEXT,
  date     TEXT,
  time     TEXT,
  read     BOOLEAN DEFAULT false,
  status   TEXT DEFAULT 'sent'
);

-- ── AUTHORIZED PERSONS (sortie) ────────────────────────────
CREATE TABLE IF NOT EXISTS aps (
  id        TEXT PRIMARY KEY,
  sid       TEXT NOT NULL,
  name      TEXT,
  relation  TEXT,
  photo     TEXT,
  active    BOOLEAN DEFAULT true,
  phone     TEXT
);

-- ── DAILY RECORDS (recettes caisse) ────────────────────────
CREATE TABLE IF NOT EXISTS daily_records (
  id         TEXT PRIMARY KEY,
  date       TEXT NOT NULL,
  amount     NUMERIC DEFAULT 0,
  label      TEXT,
  by         TEXT,
  validated  BOOLEAN DEFAULT false,
  sid        TEXT    -- élève lié (paiement)
);
CREATE INDEX IF NOT EXISTS idx_daily_records_date ON daily_records(date);

-- ── DAILY EXPENSES (dépenses caisse) ───────────────────────
CREATE TABLE IF NOT EXISTS daily_expenses (
  id         TEXT PRIMARY KEY,
  date       TEXT NOT NULL,
  amount     NUMERIC DEFAULT 0,
  label      TEXT,
  by         TEXT,
  validated  BOOLEAN DEFAULT false
);
CREATE INDEX IF NOT EXISTS idx_daily_expenses_date ON daily_expenses(date);

-- ── DAILY REPORTS ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS daily_reports (
  id        TEXT PRIMARY KEY,
  date      TEXT NOT NULL,
  time      TEXT,
  by        TEXT,
  status    TEXT DEFAULT 'pending',   -- pending|validated
  records   JSONB DEFAULT '[]',
  expenses  JSONB DEFAULT '[]',
  summary   JSONB DEFAULT '{}'
);

-- ── DEVOIRS ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS devoirs (
  id          TEXT PRIMARY KEY,
  cid         TEXT,
  title       TEXT,
  category    TEXT,
  date        TEXT,
  by          TEXT,
  questions   JSONB DEFAULT '[]',
  expires_at  BIGINT,
  lang        TEXT DEFAULT 'fr'
);

-- ── CAHIER DE TEXTE ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS cahier_texte (
  id       TEXT PRIMARY KEY,
  cid      TEXT,
  by       TEXT,
  date     TEXT,
  content  TEXT,
  status   TEXT DEFAULT 'pending',   -- pending|approved|refused
  lang     TEXT DEFAULT 'fr'
);

-- ── MATIERES ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS matieres (
  id      TEXT PRIMARY KEY,
  cid     TEXT NOT NULL,
  name    TEXT NOT NULL,
  lang    TEXT DEFAULT 'fr',
  active  BOOLEAN DEFAULT true
);

-- ── RATTRAPAGES ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS rattrapages (
  id               TEXT PRIMARY KEY,
  sid              TEXT NOT NULL,
  teacher_id       TEXT,
  status           TEXT DEFAULT 'pending',
  validated_by     TEXT,
  d2_validated     BOOLEAN DEFAULT false,
  date             TEXT,
  time             TEXT,
  amount           NUMERIC DEFAULT 0,
  payment_signaled BOOLEAN DEFAULT false,
  note             TEXT
);

-- ── CONVOCATIONS ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS convocations (
  id      TEXT PRIMARY KEY,
  sid     TEXT,
  reason  TEXT,
  date    TEXT,
  status  TEXT DEFAULT 'pending',
  by      TEXT,
  note    TEXT
);

-- ── TIMETABLES ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS timetables (
  id    TEXT PRIMARY KEY,
  cid   TEXT,
  data  JSONB DEFAULT '{}'
);

-- ── SETTINGS ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS settings (
  id                   TEXT PRIMARY KEY DEFAULT 'main',
  fees                 JSONB DEFAULT '{"T1":0,"T2":0,"T3":0,"inscription":0}',
  currentTrimestre     TEXT DEFAULT 'T1',
  toggles              JSONB DEFAULT '{}',
  year                 TEXT DEFAULT '2025-2026',
  session_timeout_min  INTEGER DEFAULT 15,
  feesControl          JSONB DEFAULT '{"active":false,"trimestre":"T1"}',
  retention            JSONB DEFAULT '{"notifs":30,"scan_log":90,"audit_log":90,"approbations":60}',
  _lastCleanup         TEXT
);
-- Ligne settings par défaut
INSERT INTO settings (id) VALUES ('main') ON CONFLICT (id) DO NOTHING;

-- ── APPROBATIONS ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS approbations (
  id       TEXT PRIMARY KEY,
  type     TEXT,
  status   TEXT DEFAULT 'pending',
  content  TEXT,
  sid      TEXT,
  date     TEXT,
  time     TEXT,
  by       TEXT,
  data     JSONB DEFAULT '{}'
);

-- ── TEACHER NOTES ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS teacher_notes (
  id    TEXT PRIMARY KEY,
  uid   TEXT,
  sid   TEXT,
  note  TEXT,
  date  TEXT
);

-- ── AUDIT LOG ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS audit_log (
  id         TEXT PRIMARY KEY,
  action     TEXT,
  detail     TEXT,
  date       TEXT,
  time       TEXT,
  by         TEXT,
  target_id  TEXT
);
CREATE INDEX IF NOT EXISTS idx_audit_log_date ON audit_log(date);

-- ── TEACHER ABSENCES ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS teacher_absences (
  id      TEXT PRIMARY KEY,
  uid     TEXT NOT NULL,
  date    TEXT,
  reason  TEXT,
  status  TEXT DEFAULT 'pending'
);

-- ── SANCTIONS ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS sanctions (
  id      TEXT PRIMARY KEY,
  sid     TEXT NOT NULL,
  type    TEXT,
  reason  TEXT,
  date    TEXT,
  by      TEXT,
  status  TEXT DEFAULT 'active'
);

-- ── MEDICAL ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS medical (
  id     TEXT PRIMARY KEY,
  sid    TEXT NOT NULL,
  type   TEXT,
  date   TEXT,
  notes  TEXT,
  by     TEXT
);

-- ── TENAFEP ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS tenafep (
  id     TEXT PRIMARY KEY,
  sid    TEXT NOT NULL,
  score  NUMERIC,
  year   TEXT,
  notes  TEXT
);

-- ── EVALUATIONS ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS evaluations (
  id         TEXT PRIMARY KEY,
  sid        TEXT NOT NULL,
  cid        TEXT,
  matiere    TEXT,
  score      NUMERIC,
  max_score  NUMERIC DEFAULT 20,
  date       TEXT,
  type       TEXT,
  trimestre  TEXT,
  by         TEXT
);

-- ── SALARIES ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS salaries (
  id      TEXT PRIMARY KEY,
  uid     TEXT NOT NULL,
  month   TEXT,
  amount  NUMERIC DEFAULT 0,
  paid    BOOLEAN DEFAULT false,
  date    TEXT,
  note    TEXT
);

-- ── ADVANCES ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS advances (
  id      TEXT PRIMARY KEY,
  uid     TEXT NOT NULL,
  amount  NUMERIC DEFAULT 0,
  date    TEXT,
  reason  TEXT,
  status  TEXT DEFAULT 'pending'
);

-- ============================================================
-- ACTIVER RLS SUR TOUTES LES TABLES
-- (à faire AVANT d'ajouter les policies)
-- ============================================================
ALTER TABLE users              ENABLE ROW LEVEL SECURITY;
ALTER TABLE classes            ENABLE ROW LEVEL SECURITY;
ALTER TABLE students           ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments           ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance         ENABLE ROW LEVEL SECURITY;
ALTER TABLE scan_log           ENABLE ROW LEVEL SECURITY;
ALTER TABLE grades             ENABLE ROW LEVEL SECURITY;
ALTER TABLE conduct            ENABLE ROW LEVEL SECURITY;
ALTER TABLE absences           ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifs             ENABLE ROW LEVEL SECURITY;
ALTER TABLE events             ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages           ENABLE ROW LEVEL SECURITY;
ALTER TABLE aps                ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_records      ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_expenses     ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_reports      ENABLE ROW LEVEL SECURITY;
ALTER TABLE devoirs            ENABLE ROW LEVEL SECURITY;
ALTER TABLE cahier_texte       ENABLE ROW LEVEL SECURITY;
ALTER TABLE matieres           ENABLE ROW LEVEL SECURITY;
ALTER TABLE rattrapages        ENABLE ROW LEVEL SECURITY;
ALTER TABLE convocations       ENABLE ROW LEVEL SECURITY;
ALTER TABLE timetables         ENABLE ROW LEVEL SECURITY;
ALTER TABLE settings           ENABLE ROW LEVEL SECURITY;
ALTER TABLE approbations       ENABLE ROW LEVEL SECURITY;
ALTER TABLE teacher_notes      ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_log          ENABLE ROW LEVEL SECURITY;
ALTER TABLE teacher_absences   ENABLE ROW LEVEL SECURITY;
ALTER TABLE sanctions          ENABLE ROW LEVEL SECURITY;
ALTER TABLE medical            ENABLE ROW LEVEL SECURITY;
ALTER TABLE tenafep            ENABLE ROW LEVEL SECURITY;
ALTER TABLE evaluations        ENABLE ROW LEVEL SECURITY;
ALTER TABLE salaries           ENABLE ROW LEVEL SECURITY;
ALTER TABLE advances           ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- POLICIES RLS — accès complet à la clé anon
-- (l'application gère elle-même les droits par rôle)
-- ============================================================
DO $$
DECLARE
  t TEXT;
  tables TEXT[] := ARRAY[
    'users','classes','students','payments','attendance','scan_log',
    'grades','conduct','absences','notifs','events','messages','aps',
    'daily_records','daily_expenses','daily_reports','devoirs',
    'cahier_texte','matieres','rattrapages','convocations','timetables',
    'settings','approbations','teacher_notes','audit_log',
    'teacher_absences','sanctions','medical','tenafep',
    'evaluations','salaries','advances'
  ];
BEGIN
  FOREACH t IN ARRAY tables LOOP
    -- SELECT
    EXECUTE format('DROP POLICY IF EXISTS "anon_select" ON %I', t);
    EXECUTE format('CREATE POLICY "anon_select" ON %I FOR SELECT TO anon USING (true)', t);
    -- INSERT
    EXECUTE format('DROP POLICY IF EXISTS "anon_insert" ON %I', t);
    EXECUTE format('CREATE POLICY "anon_insert" ON %I FOR INSERT TO anon WITH CHECK (true)', t);
    -- UPDATE
    EXECUTE format('DROP POLICY IF EXISTS "anon_update" ON %I', t);
    EXECUTE format('CREATE POLICY "anon_update" ON %I FOR UPDATE TO anon USING (true) WITH CHECK (true)', t);
    -- DELETE
    EXECUTE format('DROP POLICY IF EXISTS "anon_delete" ON %I', t);
    EXECUTE format('CREATE POLICY "anon_delete" ON %I FOR DELETE TO anon USING (true)', t);
  END LOOP;
END $$;

-- ============================================================
-- VÉRIFICATION
-- ============================================================
SELECT table_name, COUNT(*) as policies
FROM information_schema.table_constraints
WHERE constraint_type = 'CHECK'
GROUP BY table_name;

SELECT 'Tables créées et RLS configuré avec succès ✅' as statut;
