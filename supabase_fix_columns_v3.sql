-- ══════════════════════════════════════════════════════════════════
--  SchoolSafe — Conformité du schéma, vague finale
--  À lancer sur la base de l'ÉCOLE
--
--  Produite non plus par recherche de motifs dans le texte, mais par
--  `node tools/audit-schema.mjs` : un analyseur qui lit l'arbre syntaxique du
--  programme, suit les portées de variables, les spreads et les champs
--  conditionnels. Les trois vagues précédentes venaient d'expressions
--  régulières, aveugles à ces formes — d'où trois angles morts successifs,
--  chacun révélé par un bug en service.
--
--  313 écritures analysées, 22 colonnes manquantes, 3 défauts de droits.
--
--  Sans dommage à relancer.
-- ══════════════════════════════════════════════════════════════════

-- ── CLASSES — apparence des cartes de classe ──────────────────────
ALTER TABLE classes
  ADD COLUMN IF NOT EXISTS option           TEXT,
  ADD COLUMN IF NOT EXISTS card_color       TEXT,
  ADD COLUMN IF NOT EXISTS card_color_soft  TEXT,
  ADD COLUMN IF NOT EXISTS card_color_dark  TEXT;

-- ── CAHIER DE TEXTE ───────────────────────────────────────────────
ALTER TABLE cahier_texte
  ADD COLUMN IF NOT EXISTS chapitre  TEXT,
  ADD COLUMN IF NOT EXISTS devoirs   TEXT,
  ADD COLUMN IF NOT EXISTS prochain  TEXT,
  ADD COLUMN IF NOT EXISTS school_id TEXT;

-- ── CAHIER DE PRÉPARATION ─────────────────────────────────────────
-- `ct_id` relie la préparation à la leçon publiée quand l'enseignant la
-- marque « faite ». La colonne manquait, et comme la mise à jour renvoyait
-- la ligne entière, PostgREST la rejetait en bloc : la préparation restait
-- « planifiée » côté serveur quoi que fasse l'enseignant.
ALTER TABLE cahier_prep
  ADD COLUMN IF NOT EXISTS ct_id     TEXT,
  ADD COLUMN IF NOT EXISTS school_id TEXT;

-- ── RATTRAPAGES ───────────────────────────────────────────────────
-- `paid_date` était renseigné en mémoire mais absent de la requête de mise
-- à jour comme de la table : la date d'encaissement d'un rattrapage
-- n'existait nulle part, alors que c'est elle qui rattache la prime de
-- l'enseignant au bon mois de paie.
ALTER TABLE rattrapages
  ADD COLUMN IF NOT EXISTS paid_date TEXT,
  ADD COLUMN IF NOT EXISTS school_id TEXT;

-- ── SANCTIONS ─────────────────────────────────────────────────────
-- La table déclare `description`, le code écrit `reason`. Les deux coexistent
-- plutôt que d'imposer une reprise des lectures sur une application en service.
ALTER TABLE sanctions
  ADD COLUMN IF NOT EXISTS reason    TEXT,
  ADD COLUMN IF NOT EXISTS school_id TEXT;

-- ── CONVOCATIONS ──────────────────────────────────────────────────
ALTER TABLE convocations
  ADD COLUMN IF NOT EXISTS school_id TEXT;

UPDATE sanctions SET reason = COALESCE(reason, description) WHERE reason IS NULL;

-- ── CAISSE ────────────────────────────────────────────────────────
-- `ref` et `recu_no` rattachent la recette du jour au versement qui l'a
-- produite. Sans ce lien, annuler un versement laissait sa recette dans la
-- caisse : le total du jour ne retombait jamais et le tiroir ne pouvait pas
-- s'équilibrer.
ALTER TABLE daily_records
  ADD COLUMN IF NOT EXISTS mvt_type TEXT,
  ADD COLUMN IF NOT EXISTS ref      TEXT,
  ADD COLUMN IF NOT EXISTS recu_no  TEXT,
  ADD COLUMN IF NOT EXISTS annulled BOOLEAN DEFAULT false;

CREATE INDEX IF NOT EXISTS idx_daily_records_ref ON daily_records(ref);

ALTER TABLE daily_expenses
  ADD COLUMN IF NOT EXISTS beneficiary     TEXT,
  ADD COLUMN IF NOT EXISTS category_code   TEXT,
  ADD COLUMN IF NOT EXISTS invoice_ref     TEXT,
  ADD COLUMN IF NOT EXISTS payment_method  TEXT;

-- ── SALAIRES — le bénéficiaire n'est pas toujours un enseignant ───
ALTER TABLE salaries
  ADD COLUMN IF NOT EXISTS person_name     TEXT,
  ADD COLUMN IF NOT EXISTS person_role     TEXT,
  ADD COLUMN IF NOT EXISTS payment_method  TEXT;

-- ── MESSAGES ──────────────────────────────────────────────────────
ALTER TABLE messages
  ADD COLUMN IF NOT EXISTS to_class TEXT;

-- ── NOTIFICATIONS — reçu joint ────────────────────────────────────
-- Une notification de paiement transporte le détail du reçu, pour que le
-- parent puisse le rouvrir sans dépendre d'une autre requête.
ALTER TABLE notifs
  ADD COLUMN IF NOT EXISTS receipt JSONB;

-- ── JUSTIFICATIONS D'ABSENCE — trace de la décision ───────────────
-- Qui a tranché, et quand : le journal ne le retenait pas, alors qu'une
-- absence excusée efface une arrivée tardive du dossier de l'élève.
ALTER TABLE absences
  ADD COLUMN IF NOT EXISTS validated_by TEXT,
  ADD COLUMN IF NOT EXISTS validated_at TEXT,
  ADD COLUMN IF NOT EXISTS school_id    TEXT;

-- ── ACTIVITÉS ET CANTINE ──────────────────────────────────────────
ALTER TABLE activites
  ADD COLUMN IF NOT EXISTS school_id TEXT;

ALTER TABLE cantine_menus
  ADD COLUMN IF NOT EXISTS school_id TEXT;

-- ── ABSENCES D'ENSEIGNANTS ────────────────────────────────────────
-- `duree` est saisie librement — « 1 jour », « 2 semaines » — donc du texte.
ALTER TABLE teacher_absences
  ADD COLUMN IF NOT EXISTS motif TEXT,
  ADD COLUMN IF NOT EXISTS duree TEXT;

-- ══════════════════════════════════════════════════════════════════
--  DROITS D'ACCÈS
-- ══════════════════════════════════════════════════════════════════

-- `inscriptions` : le site public dépose une demande, l'application la valide
-- ou la refuse — ce qui suppose de pouvoir modifier la ligne. Sans policy
-- UPDATE, aucune demande d'inscription ne pouvait être traitée.
DROP POLICY IF EXISTS "anon_update" ON inscriptions;
CREATE POLICY "anon_update" ON inscriptions
  FOR UPDATE TO anon USING (true) WITH CHECK (true);

-- `daily_reports` : le code supprime un rapport de caisse non validé. La table
-- l'interdit volontairement — un rapport financier ne s'efface pas. On garde
-- l'interdiction : c'est le code qui devra annuler par écriture inverse.
-- Aucune policy DELETE n'est donc ajoutée ici, sciemment.

-- ── VÉRIFICATION ──────────────────────────────────────────────────
SELECT
  count(*) FILTER (WHERE table_name='classes'          AND column_name='card_color')     AS classes_ok,
  count(*) FILTER (WHERE table_name='cahier_texte'     AND column_name='chapitre')       AS cahier_ok,
  count(*) FILTER (WHERE table_name='sanctions'        AND column_name='reason')         AS sanctions_ok,
  count(*) FILTER (WHERE table_name='daily_expenses'   AND column_name='beneficiary')    AS depenses_ok,
  count(*) FILTER (WHERE table_name='salaries'         AND column_name='person_name')    AS salaires_ok,
  count(*) FILTER (WHERE table_name='messages'         AND column_name='to_class')       AS messages_ok,
  count(*) FILTER (WHERE table_name='notifs'           AND column_name='receipt')        AS notifs_ok,
  count(*) FILTER (WHERE table_name='teacher_absences' AND column_name='duree')          AS absences_ok
FROM information_schema.columns WHERE table_schema='public';

SELECT policyname, cmd FROM pg_policies
WHERE schemaname='public' AND tablename='inscriptions' ORDER BY cmd;

-- ══════════════════════════════════════════════════════════════════
--  VERROU D'ANNÉE — un booléen qui reçoit une année
--
--  Le code écrit `DB.settings.year_locked = yr`, soit « 2025-2026 », et
--  relit `year_locked === settings.year`. La colonne était pourtant
--  déclarée BOOLEAN : PostgreSQL refuse la valeur, et comme un seul champ
--  invalide fait rejeter la ligne entière, PLUS AUCUN réglage de l'école ne
--  pouvait être enregistré dès qu'une année avait été archivée.
--
--  La sémantique du code exige du texte : c'est la colonne qui s'aligne.
-- ══════════════════════════════════════════════════════════════════
ALTER TABLE settings
  ALTER COLUMN year_locked DROP DEFAULT,
  ALTER COLUMN year_locked TYPE TEXT
    USING (CASE WHEN year_locked IS NULL THEN NULL
                WHEN year_locked::text IN ('true','false') THEN NULL
                ELSE year_locked::text END);

-- ── SETTINGS — permission d'insertion ─────────────────────────────
-- Le code enregistre les réglages par `upsert`, qui est un INSERT avec
-- résolution de conflit. Sans policy INSERT, PostgREST le rejette même quand
-- l'opération se résout en simple mise à jour : aucun réglage de l'école ne
-- pouvait être enregistré. `id` étant clé primaire, aucun doublon n'est
-- possible.
DROP POLICY IF EXISTS "anon_insert" ON settings;
CREATE POLICY "anon_insert" ON settings
  FOR INSERT TO anon WITH CHECK (true);

-- ══════════════════════════════════════════════════════════════════
--  PORTAIL — QUI ACCOMPAGNE L'ENFANT
--
--  Le journal du portail retenait qui avait scanné, jamais qui accompagnait.
--  À l'entrée, rien ne distinguait un enfant déposé par son père d'un enfant
--  arrivé seul. À la sortie, la liste n'offrait que des personnes à désigner :
--  un élève rentrant par ses propres moyens obligeait le gardien à choisir
--  quelqu'un à tort, ou à renoncer à scanner. Le premier fausse le registre,
--  le second le laisse muet.
--
--  escort_kind : seul · parent · autorisee · autre
--  escort_id   : identifiant du parent ou de la personne autorisée, si connue
--  escort_name : nom retenu, y compris saisi librement pour un cas non prévu
-- ══════════════════════════════════════════════════════════════════
ALTER TABLE scan_log
  ADD COLUMN IF NOT EXISTS escort_kind TEXT,
  ADD COLUMN IF NOT EXISTS escort_id   TEXT,
  ADD COLUMN IF NOT EXISTS escort_name TEXT;

-- Retrouver rapidement les sorties non accompagnées d'une journée.
CREATE INDEX IF NOT EXISTS idx_scan_log_escort ON scan_log(date, escort_kind);

SELECT count(*) FILTER (WHERE column_name LIKE 'escort_%') AS colonnes_accompagnant
FROM information_schema.columns
WHERE table_schema='public' AND table_name='scan_log';
