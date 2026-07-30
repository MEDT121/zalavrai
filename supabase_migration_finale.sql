-- ══════════════════════════════════════════════════════════════════════════
--  SchoolSafe — MIGRATION CONSOLIDÉE
--  À lancer sur la base de l'ÉCOLE, d'un seul bloc, dans l'éditeur SQL.
--
--  Remplace supabase_fix_columns_v2.sql ET supabase_fix_columns_v3.sql.
--  Inutile de les lancer séparément : ce fichier contient les deux.
--
--  77 colonnes sur 22 tables · 1 changement de type · 2 droits
--  d'accès · 2 index · 2 reprises de données.
--
--  Sans dommage à relancer autant de fois qu'on veut : chaque opération
--  vérifie d'abord si elle a déjà été faite.
--
--  POURQUOI C'EST NÉCESSAIRE
--  PostgREST rejette la ligne ENTIÈRE dès qu'une seule colonne lui est
--  inconnue. Un élève inscrit, une note corrigée, une préparation validée
--  ou un réglage d'école disparaissait donc en silence, et l'opération
--  s'accumulait dans la file de synchronisation sans jamais aboutir.
-- ══════════════════════════════════════════════════════════════════════════

-- ══════════════════════════════════════════════════════════════════════════
--  1 — COLONNES MANQUANTES
--
--  Une table absente n'interrompt pas la migration : elle est signalée et le
--  reste continue. Sans cela un seul nom inattendu ferait tout échouer, et
--  l'on ne saurait pas ce qui est passé.
-- ══════════════════════════════════════════════════════════════════════════
DO $$
DECLARE
  r        record;
  ajoutees int := 0;
  ignorees int := 0;
BEGIN
  FOR r IN
    SELECT * FROM (VALUES
      -- students : création d'un élève. `created_at`, `lieu_naissance`,
      --   `num_inscription` et `school_id` étaient envoyés sans exister :
      --   PostgREST rejetant la ligne entière, l'élève n'atteignait jamais la base.
      ('students','created_at','TEXT'),
      ('students','lieu_naissance','TEXT'),
      ('students','num_inscription','TEXT'),
      ('students','school_id','TEXT'),

      ('users','school_id','TEXT'),

      -- grades : `year` et `school_id`, absents des bulletins synchronisés.
      ('grades','school_id','TEXT'),
      ('grades','year','TEXT'),

      ('attendance','by','TEXT'),
      ('attendance','school_id','TEXT'),

      -- scan_log : qui accompagnait l'enfant, à l'entrée comme à la sortie.
      ('scan_log','by_role','TEXT'),
      ('scan_log','manual','BOOLEAN DEFAULT false'),

      -- absences : qui a tranché une justification, et quand.
      ('absences','submitted','TEXT'),

      ('notifs','by','TEXT'),
      ('notifs','school_id','TEXT'),
      ('notifs','wa_links','JSONB DEFAULT ''[]''::jsonb'),

      -- messages : deux générations de code se croisent — `type`/`msg_type`,
      --   `name`/`from_name`.
      ('messages','type','TEXT'),
      ('messages','name','TEXT'),
      ('messages','from_name','TEXT'),
      ('messages','to_name','TEXT'),
      ('messages','about_sid','TEXT'),
      ('messages','about_name','TEXT'),

      -- daily_records : `ref` et `recu_no` rattachent la recette du jour au versement.
      --   Sans ce lien, annuler un versement laissait sa recette en caisse.
      ('daily_records','school_id','TEXT'),

      ('daily_expenses','by_name','TEXT'),
      ('daily_expenses','category_label','TEXT'),
      ('daily_expenses','school_id','TEXT'),

      ('salaries','direct_primes_total','NUMERIC DEFAULT 0'),
      ('salaries','school_id','TEXT'),

      ('activites','emoji','TEXT'),
      ('activites','jour','TEXT'),
      ('activites','heure','TEXT'),
      ('activites','lieu','TEXT'),

      -- activites_inscriptions : `act_id` double `activity_id` : les deux noms coexistent.
      ('activites_inscriptions','act_id','TEXT'),
      ('activites_inscriptions','date','TEXT'),

      ('cahier_texte','lang','TEXT DEFAULT ''fr'''),

      ('teacher_notes','cid','TEXT'),

      -- teacher_absences : `duree` est saisie librement — « 1 jour », « 2 semaines ».
      ('teacher_absences','cid','TEXT'),
      ('teacher_absences','name','TEXT'),
      ('teacher_absences','time','TEXT'),

      ('classes','option','TEXT'),
      ('classes','card_color','TEXT'),
      ('classes','card_color_soft','TEXT'),
      ('classes','card_color_dark','TEXT'),

      ('cahier_texte','chapitre','TEXT'),
      ('cahier_texte','devoirs','TEXT'),
      ('cahier_texte','prochain','TEXT'),
      ('cahier_texte','school_id','TEXT'),

      -- cahier_prep : `ct_id` relie la préparation à la leçon publiée. Sa colonne
      --   manquait, et la mise à jour renvoyant la ligne entière, PostgREST la
      --   rejetait en bloc : la préparation restait « planifiée » sur le serveur.
      ('cahier_prep','ct_id','TEXT'),
      ('cahier_prep','school_id','TEXT'),

      -- rattrapages : `paid_date` rattache la prime de l'enseignant au bon mois de paie.
      ('rattrapages','paid_date','TEXT'),
      ('rattrapages','school_id','TEXT'),

      -- sanctions : la table déclare `description`, le code écrit `reason`.
      ('sanctions','reason','TEXT'),
      ('sanctions','school_id','TEXT'),

      ('convocations','school_id','TEXT'),

      -- daily_records : `ref` et `recu_no` rattachent la recette du jour au versement.
      --   Sans ce lien, annuler un versement laissait sa recette en caisse.
      ('daily_records','mvt_type','TEXT'),
      ('daily_records','ref','TEXT'),
      ('daily_records','recu_no','TEXT'),
      ('daily_records','annulled','BOOLEAN DEFAULT false'),

      ('daily_expenses','beneficiary','TEXT'),
      ('daily_expenses','category_code','TEXT'),
      ('daily_expenses','invoice_ref','TEXT'),
      ('daily_expenses','payment_method','TEXT'),

      ('salaries','person_name','TEXT'),
      ('salaries','person_role','TEXT'),
      ('salaries','payment_method','TEXT'),

      -- messages : deux générations de code se croisent — `type`/`msg_type`,
      --   `name`/`from_name`.
      ('messages','to_class','TEXT'),
      ('messages','school_id','TEXT'),

      ('notifs','receipt','JSONB'),

      -- absences : qui a tranché une justification, et quand.
      ('absences','validated_by','TEXT'),
      ('absences','validated_at','TEXT'),
      ('absences','school_id','TEXT'),

      ('activites','school_id','TEXT'),

      ('cantine_menus','school_id','TEXT'),

      -- teacher_absences : `duree` est saisie librement — « 1 jour », « 2 semaines ».
      ('teacher_absences','motif','TEXT'),
      ('teacher_absences','duree','TEXT'),

      -- scan_log : qui accompagnait l'enfant, à l'entrée comme à la sortie.
      ('scan_log','escort_kind','TEXT'),
      ('scan_log','escort_id','TEXT'),
      ('scan_log','escort_name','TEXT')
    ) AS t(tbl, col, typ)
  LOOP
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.tables
      WHERE table_schema = 'public' AND table_name = r.tbl
    ) THEN
      RAISE NOTICE 'Table absente, ignoree : %', r.tbl;
      ignorees := ignorees + 1;
      CONTINUE;
    END IF;

    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema = 'public' AND table_name = r.tbl AND column_name = r.col
    ) THEN
      EXECUTE format('ALTER TABLE public.%I ADD COLUMN %I %s', r.tbl, r.col, r.typ);
      ajoutees := ajoutees + 1;
    END IF;
  END LOOP;

  RAISE NOTICE 'Colonnes ajoutees : % — tables absentes : %', ajoutees, ignorees;
END $$;

-- ══════════════════════════════════════════════════════════════════════════
--  2 — VERROU D'ANNÉE : un booléen qui reçoit une année
--
--  Le code écrit `settings.year_locked = "2025-2026"` puis relit
--  `year_locked === settings.year`. La colonne était pourtant déclarée
--  BOOLEAN : PostgreSQL refuse la valeur, et comme un seul champ invalide
--  fait rejeter la ligne entière, PLUS AUCUN réglage de l'école ne pouvait
--  être enregistré dès qu'une année avait été archivée.
--
--  Un booléen ne porte aucune année : les valeurs existantes (true/false)
--  n'ont pas d'équivalent en texte et deviennent NULL, c'est-à-dire
--  « aucune année verrouillée ». C'est l'état correct pour une base où le
--  verrou n'a de toute façon jamais pu s'enregistrer.
-- ══════════════════════════════════════════════════════════════════════════
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables
                 WHERE table_schema='public' AND table_name='settings') THEN
    RAISE NOTICE 'Table settings absente — verrou d''annee ignore';
  ELSIF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='settings'
      AND column_name='year_locked' AND data_type='boolean'
  ) THEN
    ALTER TABLE settings ALTER COLUMN year_locked DROP DEFAULT;
    ALTER TABLE settings ALTER COLUMN year_locked TYPE TEXT USING NULL;
    RAISE NOTICE 'settings.year_locked : BOOLEAN -> TEXT';
  ELSIF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='settings' AND column_name='year_locked'
  ) THEN
    ALTER TABLE settings ADD COLUMN year_locked TEXT;
    RAISE NOTICE 'settings.year_locked creee en TEXT';
  ELSE
    RAISE NOTICE 'settings.year_locked deja en TEXT — rien a faire';
  END IF;
END $$;

-- ══════════════════════════════════════════════════════════════════════════
--  3 — DROITS D'ACCÈS
-- ══════════════════════════════════════════════════════════════════════════

-- `inscriptions` : le site public dépose une demande, l'application la valide
-- ou la refuse — ce qui suppose de pouvoir modifier la ligne. Sans policy
-- UPDATE, aucune demande d'inscription ne pouvait être traitée.
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables
             WHERE table_schema='public' AND table_name='inscriptions') THEN
    DROP POLICY IF EXISTS "anon_update" ON inscriptions;
    CREATE POLICY "anon_update" ON inscriptions
      FOR UPDATE TO anon USING (true) WITH CHECK (true);
  END IF;
END $$;

-- `settings` : le code enregistre les réglages par `upsert`, qui est un INSERT
-- avec résolution de conflit. Sans policy INSERT, PostgREST le rejette même
-- quand l'opération se résout en simple mise à jour — aucun réglage de l'école
-- ne pouvait donc être enregistré. `id` étant clé primaire, aucun doublon
-- n'est possible.
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables
             WHERE table_schema='public' AND table_name='settings') THEN
    DROP POLICY IF EXISTS "anon_insert" ON settings;
    CREATE POLICY "anon_insert" ON settings
      FOR INSERT TO anon WITH CHECK (true);
  END IF;
END $$;

-- `daily_reports` : le code supprime un rapport de caisse non validé. La table
-- l'interdit volontairement — un rapport financier ne s'efface pas. On garde
-- l'interdiction : c'est au code d'annuler par écriture inverse. Aucune policy
-- DELETE n'est ajoutée ici, sciemment.

-- ══════════════════════════════════════════════════════════════════════════
--  4 — INDEX
-- ══════════════════════════════════════════════════════════════════════════
CREATE INDEX IF NOT EXISTS idx_daily_records_ref ON daily_records(ref);
CREATE INDEX IF NOT EXISTS idx_scan_log_escort   ON scan_log(date, escort_kind);

-- ══════════════════════════════════════════════════════════════════════════
--  5 — REPRISE DES DONNÉES EXISTANTES
--
--  Deux orthographes coexistent volontairement : le site public et
--  l'application n'emploient pas le même mot, et les unifier demanderait de
--  reprendre une vingtaine de lectures sur une application en service.
-- ══════════════════════════════════════════════════════════════════════════
UPDATE inscriptions SET statut = COALESCE(statut, status, 'pending') WHERE statut IS NULL;
UPDATE sanctions    SET reason = COALESCE(reason, description)       WHERE reason IS NULL;

-- ══════════════════════════════════════════════════════════════════════════
--  6 — VÉRIFICATION
--
--  Quatre résultats s'affichent. Le premier est celui qui compte :
--  `manquantes` doit valoir 0.
-- ══════════════════════════════════════════════════════════════════════════
WITH attendu(tbl, col) AS (
  VALUES
    ('students','created_at'),
    ('students','lieu_naissance'),
    ('students','num_inscription'),
    ('students','school_id'),
    ('users','school_id'),
    ('grades','school_id'),
    ('grades','year'),
    ('attendance','by'),
    ('attendance','school_id'),
    ('scan_log','by_role'),
    ('scan_log','manual'),
    ('absences','submitted'),
    ('notifs','by'),
    ('notifs','school_id'),
    ('notifs','wa_links'),
    ('messages','type'),
    ('messages','name'),
    ('messages','from_name'),
    ('messages','to_name'),
    ('messages','about_sid'),
    ('messages','about_name'),
    ('daily_records','school_id'),
    ('daily_expenses','by_name'),
    ('daily_expenses','category_label'),
    ('daily_expenses','school_id'),
    ('salaries','direct_primes_total'),
    ('salaries','school_id'),
    ('activites','emoji'),
    ('activites','jour'),
    ('activites','heure'),
    ('activites','lieu'),
    ('activites_inscriptions','act_id'),
    ('activites_inscriptions','date'),
    ('cahier_texte','lang'),
    ('teacher_notes','cid'),
    ('teacher_absences','cid'),
    ('teacher_absences','name'),
    ('teacher_absences','time'),
    ('classes','option'),
    ('classes','card_color'),
    ('classes','card_color_soft'),
    ('classes','card_color_dark'),
    ('cahier_texte','chapitre'),
    ('cahier_texte','devoirs'),
    ('cahier_texte','prochain'),
    ('cahier_texte','school_id'),
    ('cahier_prep','ct_id'),
    ('cahier_prep','school_id'),
    ('rattrapages','paid_date'),
    ('rattrapages','school_id'),
    ('sanctions','reason'),
    ('sanctions','school_id'),
    ('convocations','school_id'),
    ('daily_records','mvt_type'),
    ('daily_records','ref'),
    ('daily_records','recu_no'),
    ('daily_records','annulled'),
    ('daily_expenses','beneficiary'),
    ('daily_expenses','category_code'),
    ('daily_expenses','invoice_ref'),
    ('daily_expenses','payment_method'),
    ('salaries','person_name'),
    ('salaries','person_role'),
    ('salaries','payment_method'),
    ('messages','to_class'),
    ('messages','school_id'),
    ('notifs','receipt'),
    ('absences','validated_by'),
    ('absences','validated_at'),
    ('absences','school_id'),
    ('activites','school_id'),
    ('cantine_menus','school_id'),
    ('teacher_absences','motif'),
    ('teacher_absences','duree'),
    ('scan_log','escort_kind'),
    ('scan_log','escort_id'),
    ('scan_log','escort_name')
),
present AS (
  SELECT table_name AS tbl, column_name AS col
  FROM information_schema.columns WHERE table_schema = 'public'
)
SELECT
  (SELECT count(*) FROM attendu)                                   AS attendues,
  (SELECT count(*) FROM attendu a JOIN present p USING (tbl, col)) AS presentes,
  (SELECT count(*) FROM attendu a
     WHERE NOT EXISTS (SELECT 1 FROM present p WHERE p.tbl=a.tbl AND p.col=a.col))
                                                                   AS manquantes;

-- Le détail, si la ligne ci-dessus n'annonce pas 0.
WITH attendu(tbl, col) AS (
  VALUES
    ('students','created_at'),
    ('students','lieu_naissance'),
    ('students','num_inscription'),
    ('students','school_id'),
    ('users','school_id'),
    ('grades','school_id'),
    ('grades','year'),
    ('attendance','by'),
    ('attendance','school_id'),
    ('scan_log','by_role'),
    ('scan_log','manual'),
    ('absences','submitted'),
    ('notifs','by'),
    ('notifs','school_id'),
    ('notifs','wa_links'),
    ('messages','type'),
    ('messages','name'),
    ('messages','from_name'),
    ('messages','to_name'),
    ('messages','about_sid'),
    ('messages','about_name'),
    ('daily_records','school_id'),
    ('daily_expenses','by_name'),
    ('daily_expenses','category_label'),
    ('daily_expenses','school_id'),
    ('salaries','direct_primes_total'),
    ('salaries','school_id'),
    ('activites','emoji'),
    ('activites','jour'),
    ('activites','heure'),
    ('activites','lieu'),
    ('activites_inscriptions','act_id'),
    ('activites_inscriptions','date'),
    ('cahier_texte','lang'),
    ('teacher_notes','cid'),
    ('teacher_absences','cid'),
    ('teacher_absences','name'),
    ('teacher_absences','time'),
    ('classes','option'),
    ('classes','card_color'),
    ('classes','card_color_soft'),
    ('classes','card_color_dark'),
    ('cahier_texte','chapitre'),
    ('cahier_texte','devoirs'),
    ('cahier_texte','prochain'),
    ('cahier_texte','school_id'),
    ('cahier_prep','ct_id'),
    ('cahier_prep','school_id'),
    ('rattrapages','paid_date'),
    ('rattrapages','school_id'),
    ('sanctions','reason'),
    ('sanctions','school_id'),
    ('convocations','school_id'),
    ('daily_records','mvt_type'),
    ('daily_records','ref'),
    ('daily_records','recu_no'),
    ('daily_records','annulled'),
    ('daily_expenses','beneficiary'),
    ('daily_expenses','category_code'),
    ('daily_expenses','invoice_ref'),
    ('daily_expenses','payment_method'),
    ('salaries','person_name'),
    ('salaries','person_role'),
    ('salaries','payment_method'),
    ('messages','to_class'),
    ('messages','school_id'),
    ('notifs','receipt'),
    ('absences','validated_by'),
    ('absences','validated_at'),
    ('absences','school_id'),
    ('activites','school_id'),
    ('cantine_menus','school_id'),
    ('teacher_absences','motif'),
    ('teacher_absences','duree'),
    ('scan_log','escort_kind'),
    ('scan_log','escort_id'),
    ('scan_log','escort_name')
)
SELECT a.tbl AS table_incomplete, a.col AS colonne_manquante
FROM attendu a
WHERE NOT EXISTS (
  SELECT 1 FROM information_schema.columns c
  WHERE c.table_schema='public' AND c.table_name=a.tbl AND c.column_name=a.col
)
ORDER BY 1, 2;

-- Doit indiquer « text ».
SELECT data_type AS type_year_locked
FROM information_schema.columns
WHERE table_schema='public' AND table_name='settings' AND column_name='year_locked';

-- Doit lister au moins : inscriptions/UPDATE et settings/INSERT.
SELECT tablename, policyname, cmd
FROM pg_policies
WHERE schemaname='public' AND tablename IN ('inscriptions','settings')
ORDER BY tablename, cmd;
