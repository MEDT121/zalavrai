-- ══════════════════════════════════════════════════════════════════
--  SchoolSafe — 2ᵉ vague de colonnes manquantes
--  À lancer sur la base de l'ÉCOLE
--
--  Le premier audit n'inspectait que les objets écrits EN CLAIR dans le code :
--      pushSync('students','post', { name: …, mat: … })
--  Il passait à côté de la forme la plus courante :
--      const ns = { … }; pushSync('students','post', ns)
--
--  Or c'est celle de la création d'un élève. Résultat : `created_at`,
--  `lieu_naissance`, `num_inscription` et `school_id` étaient envoyés sans
--  exister. PostgREST rejette la ligne ENTIÈRE dès qu'une colonne est inconnue
--  — l'élève n'atteignait donc jamais la base, sans le moindre message.
--
--  Le nouvel audit résout les variables et les spreads : 41 colonnes
--  manquaient sur 17 tables.
--
--  Sans dommage à relancer.
-- ══════════════════════════════════════════════════════════════════

-- ── ÉLÈVES — la cause du bug signalé ──────────────────────────────
ALTER TABLE students
  ADD COLUMN IF NOT EXISTS created_at        TEXT,
  ADD COLUMN IF NOT EXISTS lieu_naissance    TEXT,
  ADD COLUMN IF NOT EXISTS num_inscription   TEXT,
  ADD COLUMN IF NOT EXISTS school_id         TEXT;

-- ── COMPTES ───────────────────────────────────────────────────────
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS school_id TEXT;

-- ── NOTES ─────────────────────────────────────────────────────────
ALTER TABLE grades
  ADD COLUMN IF NOT EXISTS school_id TEXT,
  ADD COLUMN IF NOT EXISTS year      TEXT;

-- ── PRÉSENCES ─────────────────────────────────────────────────────
ALTER TABLE attendance
  ADD COLUMN IF NOT EXISTS "by"      TEXT,
  ADD COLUMN IF NOT EXISTS school_id TEXT;

-- ── SCANS AU PORTAIL ──────────────────────────────────────────────
ALTER TABLE scan_log
  ADD COLUMN IF NOT EXISTS by_role TEXT,
  ADD COLUMN IF NOT EXISTS manual  BOOLEAN DEFAULT false;

-- ── ABSENCES ──────────────────────────────────────────────────────
ALTER TABLE absences
  ADD COLUMN IF NOT EXISTS submitted TEXT;

-- ── NOTIFICATIONS ─────────────────────────────────────────────────
-- wa_links : liste de destinataires WhatsApp préparés pour une relance.
ALTER TABLE notifs
  ADD COLUMN IF NOT EXISTS "by"      TEXT,
  ADD COLUMN IF NOT EXISTS school_id TEXT,
  ADD COLUMN IF NOT EXISTS wa_links  JSONB DEFAULT '[]'::jsonb;

-- ── MESSAGES ──────────────────────────────────────────────────────
-- `type` coexiste avec `msg_type`, et `name` avec `from_name` : deux
-- générations de code se croisent ici.
ALTER TABLE messages
  ADD COLUMN IF NOT EXISTS type       TEXT,
  ADD COLUMN IF NOT EXISTS name       TEXT,
  ADD COLUMN IF NOT EXISTS from_name  TEXT,
  ADD COLUMN IF NOT EXISTS to_name    TEXT,
  ADD COLUMN IF NOT EXISTS about_sid  TEXT,
  ADD COLUMN IF NOT EXISTS about_name TEXT;

-- ── CAISSE ────────────────────────────────────────────────────────
ALTER TABLE daily_records
  ADD COLUMN IF NOT EXISTS school_id TEXT;

ALTER TABLE daily_expenses
  ADD COLUMN IF NOT EXISTS by_name         TEXT,
  ADD COLUMN IF NOT EXISTS category_label  TEXT,
  ADD COLUMN IF NOT EXISTS school_id       TEXT;

-- ── SALAIRES ──────────────────────────────────────────────────────
ALTER TABLE salaries
  ADD COLUMN IF NOT EXISTS direct_primes_total NUMERIC DEFAULT 0,
  ADD COLUMN IF NOT EXISTS school_id           TEXT;

-- ── ACTIVITÉS EXTRASCOLAIRES ──────────────────────────────────────
ALTER TABLE activites
  ADD COLUMN IF NOT EXISTS emoji TEXT,
  ADD COLUMN IF NOT EXISTS jour  TEXT,
  ADD COLUMN IF NOT EXISTS heure TEXT,
  ADD COLUMN IF NOT EXISTS lieu  TEXT;

-- `act_id` double `activity_id` : les deux noms coexistent dans le code.
ALTER TABLE activites_inscriptions
  ADD COLUMN IF NOT EXISTS act_id TEXT,
  ADD COLUMN IF NOT EXISTS date   TEXT;

-- ── PÉDAGOGIE ─────────────────────────────────────────────────────
ALTER TABLE cahier_texte
  ADD COLUMN IF NOT EXISTS lang TEXT DEFAULT 'fr';

ALTER TABLE teacher_notes
  ADD COLUMN IF NOT EXISTS cid TEXT;

ALTER TABLE teacher_absences
  ADD COLUMN IF NOT EXISTS cid  TEXT,
  ADD COLUMN IF NOT EXISTS name TEXT,
  ADD COLUMN IF NOT EXISTS time TEXT;

-- ── VÉRIFICATION ──────────────────────────────────────────────────
SELECT
  count(*) FILTER (WHERE table_name='students'    AND column_name='created_at')      AS eleve_created_at,
  count(*) FILTER (WHERE table_name='students'    AND column_name='school_id')       AS eleve_school_id,
  count(*) FILTER (WHERE table_name='students'    AND column_name='lieu_naissance')  AS eleve_lieu,
  count(*) FILTER (WHERE table_name='students'    AND column_name='num_inscription') AS eleve_num,
  count(*) FILTER (WHERE table_name='messages'    AND column_name='about_sid')       AS messages_ok,
  count(*) FILTER (WHERE table_name='notifs'      AND column_name='wa_links')        AS notifs_ok,
  count(*) FILTER (WHERE table_name='scan_log'    AND column_name='by_role')         AS scans_ok,
  count(*) FILTER (WHERE table_name='activites'   AND column_name='lieu')            AS activites_ok
FROM information_schema.columns
WHERE table_schema='public';
