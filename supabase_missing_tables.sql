-- ══════════════════════════════════════════════════════════════════
--  SchoolSafe — Les 8 tables manquantes
--  À lancer sur la base de l'ÉCOLE (pas le central)
--
--  L'application écrit dans 49 tables ; supabase_setup.sql n'en créait que
--  41. Toute écriture visant l'une des 8 absentes échouait définitivement
--  et s'accumulait dans la file de synchronisation.
--
--  Le cas le plus visible : _seedFeeTypes() peuple `fee_types` puis vérifie
--  `if (DB.fee_types.length) return`. La table étant absente, la lecture
--  renvoyait toujours vide — le garde-fou ne se déclenchait jamais et
--  9 écritures vouées à l'échec repartaient à CHAQUE rechargement depuis
--  le serveur, donc toutes les 3 minutes.
-- ══════════════════════════════════════════════════════════════════

-- ── 1. FEE_TYPES — types de frais configurables ───────────────────
CREATE TABLE IF NOT EXISTS fee_types (
  id              TEXT PRIMARY KEY,
  label           TEXT,
  category        TEXT,
  trimestre       TEXT,
  montant_defaut  NUMERIC DEFAULT 0,
  active          BOOLEAN DEFAULT true,
  school_id       TEXT
);

-- ── 2. VERSEMENTS — encaissements de caisse ───────────────────────
CREATE TABLE IF NOT EXISTS versements (
  id                TEXT PRIMARY KEY,
  sid               TEXT,
  student_name      TEXT,
  mat               TEXT,
  fee_type_id       TEXT,
  fee_label         TEXT,
  compte_cat        TEXT,
  trimestre         TEXT,
  montant           NUMERIC DEFAULT 0,
  motif             TEXT,
  note              TEXT,
  payment_method    TEXT,
  mvt_type          TEXT,
  date              TEXT,
  time              TEXT,
  "by"              TEXT,
  by_name           TEXT,
  recu_no           TEXT,
  school_id         TEXT,
  uid_perso         TEXT,
  annulled          BOOLEAN DEFAULT false,
  annulled_by       TEXT,
  annulled_by_name  TEXT,
  annulled_date     TEXT,
  annulled_reason   TEXT
);
CREATE INDEX IF NOT EXISTS idx_versements_sid  ON versements(sid);
CREATE INDEX IF NOT EXISTS idx_versements_date ON versements(date);
CREATE INDEX IF NOT EXISTS idx_versements_recu ON versements(recu_no);

-- ── 3. JOURNAL_ENTRIES — écritures comptables SYSCOHADA ───────────
CREATE TABLE IF NOT EXISTS journal_entries (
  id         TEXT PRIMARY KEY,
  date       TEXT,
  time       TEXT,
  libelle    TEXT,
  debit      TEXT,
  credit     TEXT,
  montant    NUMERIC DEFAULT 0,
  type       TEXT,
  ref        TEXT,
  "by"       TEXT,
  school_id  TEXT
);
CREATE INDEX IF NOT EXISTS idx_journal_date ON journal_entries(date);

-- ── 4. CAHIER_PREP — cahier de préparation enseignant ─────────────
CREATE TABLE IF NOT EXISTS cahier_prep (
  id           TEXT PRIMARY KEY,
  cid          TEXT,
  matiere      TEXT,
  content      TEXT,
  lang         TEXT DEFAULT 'fr',
  date_prevue  TEXT,
  date         TEXT,
  status       TEXT DEFAULT 'planifie',
  validated    BOOLEAN DEFAULT false,
  remark       TEXT,
  teacher_id   TEXT,
  "by"         TEXT,
  by_name      TEXT,
  time         TEXT
);
CREATE INDEX IF NOT EXISTS idx_cahier_prep_cid ON cahier_prep(cid);

-- ── 5. PREVISION_MATIERE — prévision de programme par matière ─────
CREATE TABLE IF NOT EXISTS prevision_matiere (
  id           TEXT PRIMARY KEY,
  cid          TEXT,
  matiere      TEXT,
  lang         TEXT DEFAULT 'fr',
  trimestre    TEXT,
  programme    TEXT,
  pourcentage  NUMERIC DEFAULT 0,
  validated    BOOLEAN DEFAULT false,
  "by"         TEXT
);
CREATE INDEX IF NOT EXISTS idx_prevision_cid ON prevision_matiere(cid);

-- ── 6. EXETAT — examen d'État (humanités) ─────────────────────────
CREATE TABLE IF NOT EXISTS exetat (
  id                TEXT PRIMARY KEY,
  sid               TEXT,
  exetat_code       TEXT,
  option            TEXT,
  result            TEXT,
  score             NUMERIC,
  registration_num  TEXT,
  notes             TEXT,
  year              TEXT,
  registered        BOOLEAN DEFAULT false,
  updated           TEXT
);
CREATE INDEX IF NOT EXISTS idx_exetat_sid ON exetat(sid);

-- ── 7. DIRECT_PRIMES — primes exceptionnelles ─────────────────────
CREATE TABLE IF NOT EXISTS direct_primes (
  id          TEXT PRIMARY KEY,
  teacher_id  TEXT,
  amount      NUMERIC DEFAULT 0,
  motif       TEXT,
  month       TEXT,
  date        TEXT,
  "by"        TEXT
);
CREATE INDEX IF NOT EXISTS idx_direct_primes_teacher ON direct_primes(teacher_id);

-- ── 8. PUSH_SUBSCRIPTIONS — abonnements aux notifications push ────
CREATE TABLE IF NOT EXISTS push_subscriptions (
  id          TEXT PRIMARY KEY,
  uid         TEXT,
  endpoint    TEXT,
  auth        TEXT,
  p256dh      TEXT,
  ua          TEXT,
  updated_at  TEXT
);
CREATE INDEX IF NOT EXISTS idx_push_uid ON push_subscriptions(uid);

-- ══════════════════════════════════════════════════════════════════
--  RLS — mêmes niveaux d'accès que les tables existantes
-- ══════════════════════════════════════════════════════════════════

-- CRUD complet : l'application crée, modifie et supprime sur ces tables.
DO $$
DECLARE tbl TEXT;
BEGIN
  FOREACH tbl IN ARRAY ARRAY[
    'fee_types','cahier_prep','prevision_matiere','exetat',
    'direct_primes','push_subscriptions'
  ] LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', tbl);
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

-- Pièces comptables : jamais supprimables. Une recette encaissée s'annule
-- par une écriture inverse, elle ne s'effface pas.
DO $$
DECLARE tbl TEXT;
BEGIN
  FOREACH tbl IN ARRAY ARRAY['versements','journal_entries'] LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', tbl);
    EXECUTE format('DROP POLICY IF EXISTS "anon_select" ON %I', tbl);
    EXECUTE format('DROP POLICY IF EXISTS "anon_insert" ON %I', tbl);
    EXECUTE format('DROP POLICY IF EXISTS "anon_update" ON %I', tbl);
    EXECUTE format('DROP POLICY IF EXISTS "anon_delete" ON %I', tbl);
    EXECUTE format('CREATE POLICY "anon_select" ON %I FOR SELECT TO anon USING (true)', tbl);
    EXECUTE format('CREATE POLICY "anon_insert" ON %I FOR INSERT TO anon WITH CHECK (true)', tbl);
    EXECUTE format('CREATE POLICY "anon_update" ON %I FOR UPDATE TO anon USING (true) WITH CHECK (true)', tbl);
  END LOOP;
END $$;

-- ── VÉRIFICATION ──────────────────────────────────────────────────
SELECT count(*) AS tables_totales
FROM information_schema.tables
WHERE table_schema = 'public';

SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN ('fee_types','versements','journal_entries','cahier_prep',
                     'prevision_matiere','exetat','direct_primes','push_subscriptions')
ORDER BY table_name;
