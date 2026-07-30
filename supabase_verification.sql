-- ══════════════════════════════════════════════════════════════════
--  SchoolSafe — VÉRIFICATION APRÈS MIGRATION
--
--  À lancer seul, après supabase_migration_finale.sql.
--  Une seule requête, une seule ligne à lire.
--
--  Attendu :  verdict = « TOUT EST EN PLACE »
-- ══════════════════════════════════════════════════════════════════
WITH attendu(tbl, col) AS (VALUES
  ('students','created_at'), ('students','lieu_naissance'), ('students','num_inscription'), ('students','school_id'),
  ('users','school_id'), ('grades','school_id'), ('grades','year'), ('attendance','by'),
  ('attendance','school_id'), ('scan_log','by_role'), ('scan_log','manual'), ('absences','submitted'),
  ('notifs','by'), ('notifs','school_id'), ('notifs','wa_links'), ('messages','type'),
  ('messages','name'), ('messages','from_name'), ('messages','to_name'), ('messages','about_sid'),
  ('messages','about_name'), ('daily_records','school_id'), ('daily_expenses','by_name'), ('daily_expenses','category_label'),
  ('daily_expenses','school_id'), ('salaries','direct_primes_total'), ('salaries','school_id'), ('activites','emoji'),
  ('activites','jour'), ('activites','heure'), ('activites','lieu'), ('activites_inscriptions','act_id'),
  ('activites_inscriptions','date'), ('cahier_texte','lang'), ('teacher_notes','cid'), ('teacher_absences','cid'),
  ('teacher_absences','name'), ('teacher_absences','time'), ('classes','option'), ('classes','card_color'),
  ('classes','card_color_soft'), ('classes','card_color_dark'), ('cahier_texte','chapitre'), ('cahier_texte','devoirs'),
  ('cahier_texte','prochain'), ('cahier_texte','school_id'), ('cahier_prep','ct_id'), ('cahier_prep','school_id'),
  ('rattrapages','paid_date'), ('rattrapages','school_id'), ('sanctions','reason'), ('sanctions','school_id'),
  ('convocations','school_id'), ('daily_records','mvt_type'), ('daily_records','ref'), ('daily_records','recu_no'),
  ('daily_records','annulled'), ('daily_expenses','beneficiary'), ('daily_expenses','category_code'), ('daily_expenses','invoice_ref'),
  ('daily_expenses','payment_method'), ('salaries','person_name'), ('salaries','person_role'), ('salaries','payment_method'),
  ('messages','to_class'), ('messages','school_id'), ('notifs','receipt'), ('absences','validated_by'),
  ('absences','validated_at'), ('absences','school_id'), ('activites','school_id'), ('advances','school_id'),
  ('cantine_menus','school_id'), ('teacher_absences','motif'), ('teacher_absences','duree'), ('scan_log','escort_kind'),
  ('scan_log','escort_id'), ('scan_log','escort_name')
),
manquantes AS (
  SELECT a.tbl, a.col FROM attendu a
  WHERE NOT EXISTS (
    SELECT 1 FROM information_schema.columns c
    WHERE c.table_schema='public' AND c.table_name=a.tbl AND c.column_name=a.col)
),
etat AS (
  SELECT
    (SELECT count(*) FROM attendu)                                       AS attendues,
    (SELECT count(*) FROM manquantes)                                    AS manquantes,
    (SELECT count(*) FROM information_schema.columns
      WHERE table_schema='public' AND table_name='settings'
        AND column_name='year_locked' AND data_type='text')              AS annee_en_texte,
    (SELECT count(*) FROM pg_policies
      WHERE schemaname='public' AND tablename='inscriptions' AND cmd='UPDATE') AS droit_inscriptions,
    (SELECT count(*) FROM pg_policies
      WHERE schemaname='public' AND tablename='settings' AND cmd='INSERT')     AS droit_reglages,
    (SELECT count(*) FROM information_schema.tables
      WHERE table_schema='public')                                       AS tables,
    (SELECT string_agg(tbl||'.'||col, ', ' ORDER BY tbl, col) FROM manquantes) AS detail
)
SELECT
  CASE WHEN manquantes=0 AND annee_en_texte=1 AND droit_inscriptions>0 AND droit_reglages>0
       THEN 'TOUT EST EN PLACE'
       ELSE 'INCOMPLET' END                          AS verdict,
  attendues, manquantes, tables,
  CASE WHEN annee_en_texte=1     THEN 'ok' ELSE 'A CORRIGER' END AS verrou_annee,
  CASE WHEN droit_inscriptions>0 THEN 'ok' ELSE 'A CORRIGER' END AS droit_inscriptions,
  CASE WHEN droit_reglages>0     THEN 'ok' ELSE 'A CORRIGER' END AS droit_reglages,
  COALESCE(detail,'—')                               AS colonnes_manquantes
FROM etat;
