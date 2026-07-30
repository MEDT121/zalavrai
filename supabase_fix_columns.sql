-- ══════════════════════════════════════════════════════════════════
--  SchoolSafe — Colonnes manquantes (audit complet code ↔ base)
--  À lancer sur la base de l'ÉCOLE, APRÈS supabase_missing_tables.sql
--
--  L'audit a comparé chaque champ écrit par l'application aux colonnes
--  réellement déclarées : 40 colonnes manquaient sur 13 tables existantes.
--  PostgREST rejette la requête entière dès qu'une seule colonne est
--  inconnue — une note, une présence ou une sanction était donc perdue
--  silencieusement, et l'opération s'accumulait dans la file de
--  synchronisation sans jamais pouvoir aboutir.
--
--  Sans dommage à relancer : ADD COLUMN IF NOT EXISTS partout.
-- ══════════════════════════════════════════════════════════════════

-- ── ÉLÈVES ────────────────────────────────────────────────────────
ALTER TABLE students
  ADD COLUMN IF NOT EXISTS access_parent     BOOLEAN DEFAULT true,
  ADD COLUMN IF NOT EXISTS archived          BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS archived_at       TEXT,
  ADD COLUMN IF NOT EXISTS card_printed      BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS card_print_date   TEXT,
  ADD COLUMN IF NOT EXISTS card_print_count  NUMERIC DEFAULT 0,
  ADD COLUMN IF NOT EXISTS diplome           BOOLEAN DEFAULT false;

-- ── COMPTES ───────────────────────────────────────────────────────
-- Deuxième génération d'empreinte de code (salée). Sans cette colonne, la
-- migration du code d'un compte échouait à chaque connexion.
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS pin_hashed_v2 BOOLEAN DEFAULT false;

-- ── NOTES ─────────────────────────────────────────────────────────
-- `trimester` coexiste avec `trimestre` : deux orthographes présentes dans
-- le code. Les unifier demanderait de reprendre toutes les lectures.
ALTER TABLE grades
  ADD COLUMN IF NOT EXISTS pct          NUMERIC,
  ADD COLUMN IF NOT EXISTS trimester    TEXT,
  ADD COLUMN IF NOT EXISTS edited_by    TEXT,
  ADD COLUMN IF NOT EXISTS edited_date  TEXT,
  ADD COLUMN IF NOT EXISTS edit_reason  TEXT;

-- ── PRÉSENCES ─────────────────────────────────────────────────────
ALTER TABLE attendance
  ADD COLUMN IF NOT EXISTS excused            BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS teacher_validated  BOOLEAN DEFAULT false;

-- ── RATTRAPAGES ───────────────────────────────────────────────────
ALTER TABLE rattrapages
  ADD COLUMN IF NOT EXISTS session_date            TEXT,
  ADD COLUMN IF NOT EXISTS session_time            TEXT,
  ADD COLUMN IF NOT EXISTS session_place           TEXT,
  ADD COLUMN IF NOT EXISTS done                    BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS done_date               TEXT,
  ADD COLUMN IF NOT EXISTS done_note               TEXT,
  ADD COLUMN IF NOT EXISTS archived                BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS payment_signaled        BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS reminder_sent           BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS validated_by_d2         TEXT,
  ADD COLUMN IF NOT EXISTS validated_by_d2_name    TEXT;

-- ── CONVOCATIONS ──────────────────────────────────────────────────
ALTER TABLE convocations
  ADD COLUMN IF NOT EXISTS convoc_type          TEXT,
  ADD COLUMN IF NOT EXISTS parent_confirmed     BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS parent_confirmed_at  TEXT;

-- ── SANCTIONS ─────────────────────────────────────────────────────
ALTER TABLE sanctions
  ADD COLUMN IF NOT EXISTS duration_days    NUMERIC,
  ADD COLUMN IF NOT EXISTS return_date      TEXT,
  ADD COLUMN IF NOT EXISTS lifted           BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS parent_notified  BOOLEAN DEFAULT false;

-- ── DEVOIRS ───────────────────────────────────────────────────────
ALTER TABLE devoirs
  ADD COLUMN IF NOT EXISTS sigs JSONB DEFAULT '[]'::jsonb;

-- ── CAISSE ────────────────────────────────────────────────────────
ALTER TABLE daily_records
  ADD COLUMN IF NOT EXISTS assigned BOOLEAN DEFAULT false;

-- Guillemets obligatoires : PostgreSQL replierait sinon la casse mixte.
ALTER TABLE daily_reports
  ADD COLUMN IF NOT EXISTS "validatedAt" TEXT;

-- ── ACTIVITÉS ─────────────────────────────────────────────────────
ALTER TABLE activites_inscriptions
  ADD COLUMN IF NOT EXISTS active BOOLEAN DEFAULT true;

-- ── PARAMÈTRES ────────────────────────────────────────────────────
ALTER TABLE settings
  ADD COLUMN IF NOT EXISTS lockdown         BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS budget_depenses  NUMERIC DEFAULT 0;

-- ── NOTIFICATIONS PUSH ────────────────────────────────────────────
ALTER TABLE push_subscriptions
  ADD COLUMN IF NOT EXISTS school_id TEXT;

-- ══════════════════════════════════════════════════════════════════
--  ÉCARTS DE VOCABULAIRE
-- ══════════════════════════════════════════════════════════════════

-- `inscriptions` : le site public écrit `status`, l'application lit `statut`
-- et ajoute un `motif_refus`. Valider ou refuser une demande échouait donc
-- systématiquement. Les deux noms coexistent volontairement — les unifier
-- demanderait de reprendre vingt emplacements de lecture.
ALTER TABLE inscriptions
  ADD COLUMN IF NOT EXISTS statut       TEXT,
  ADD COLUMN IF NOT EXISTS motif_refus  TEXT;

UPDATE inscriptions SET statut = COALESCE(statut, status, 'pending')
WHERE statut IS NULL;

-- `cahier_prep` : le formulaire de préparation envoie seize champs de plus
-- que ceux déclarés. Toute fiche enregistrée était perdue.
ALTER TABLE cahier_prep
  ADD COLUMN IF NOT EXISTS teacher_id     TEXT,
  ADD COLUMN IF NOT EXISTS titre          TEXT,
  ADD COLUMN IF NOT EXISTS date_lesson    TEXT,
  ADD COLUMN IF NOT EXISTS linked_day     TEXT,
  ADD COLUMN IF NOT EXISTS linked_period  NUMERIC,
  ADD COLUMN IF NOT EXISTS objectifs      TEXT,
  ADD COLUMN IF NOT EXISTS prerequis      TEXT,
  ADD COLUMN IF NOT EXISTS intro          TEXT,
  ADD COLUMN IF NOT EXISTS developpement  TEXT,
  ADD COLUMN IF NOT EXISTS conclusion     TEXT,
  ADD COLUMN IF NOT EXISTS materiel       TEXT,
  ADD COLUMN IF NOT EXISTS evaluation     TEXT,
  ADD COLUMN IF NOT EXISTS devoir_note    TEXT,
  ADD COLUMN IF NOT EXISTS statut         TEXT DEFAULT 'brouillon',
  ADD COLUMN IF NOT EXISTS created_at     TEXT,
  ADD COLUMN IF NOT EXISTS updated_at     TEXT;

-- ── VÉRIFICATION ──────────────────────────────────────────────────
SELECT count(*) AS tables_totales
FROM information_schema.tables WHERE table_schema = 'public';

SELECT table_name, count(*) AS colonnes
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN ('students','users','grades','attendance','rattrapages',
                     'convocations','sanctions','devoirs','daily_records',
                     'daily_reports','activites_inscriptions','settings',
                     'push_subscriptions','inscriptions','cahier_prep')
GROUP BY table_name ORDER BY table_name;
