-- ══════════════════════════════════════════════════════════════════
--  SchoolSafe — VÉRIFICATION APRÈS MIGRATION
--
--  Coller SEUL dans un onglet SQL VIDE, puis Run.
--  Attendu : verdict = « TOUT EST EN PLACE »
--
--  Pourquoi si court : les 78 colonnes sont ajoutées par UNE boucle
--  unique. Une erreur en cours aurait annulé le bloc entier, donc
--  aucune colonne n'existerait. Vérifier un échantillon des colonnes
--  les plus tardives suffit à prouver que la boucle est allée au bout.
-- ══════════════════════════════════════════════════════════════════
SELECT
  CASE WHEN c.n = 10 AND y.n = 1 AND pi.n > 0 AND ps.n > 0
       THEN 'TOUT EST EN PLACE' ELSE 'INCOMPLET' END        AS verdict,
  c.n                                                        AS echantillon_sur_10,
  CASE WHEN y.n = 1  THEN 'ok' ELSE 'A CORRIGER' END         AS verrou_annee,
  CASE WHEN pi.n > 0 THEN 'ok' ELSE 'A CORRIGER' END         AS droit_inscriptions,
  CASE WHEN ps.n > 0 THEN 'ok' ELSE 'A CORRIGER' END         AS droit_reglages,
  t.n                                                        AS tables
FROM
  (SELECT count(*) n FROM information_schema.columns
    WHERE table_schema='public' AND (table_name,column_name) IN (
      ('students','created_at'), ('students','school_id'),
      ('daily_records','ref'),   ('daily_records','annulled'),
      ('cahier_prep','ct_id'),   ('rattrapages','paid_date'),
      ('scan_log','escort_kind'),('absences','validated_by'),
      ('messages','school_id'),  ('advances','school_id'))) c,
  (SELECT count(*) n FROM information_schema.columns
    WHERE table_schema='public' AND table_name='settings'
      AND column_name='year_locked' AND data_type='text') y,
  (SELECT count(*) n FROM pg_policies
    WHERE schemaname='public' AND tablename='inscriptions' AND cmd='UPDATE') pi,
  (SELECT count(*) n FROM pg_policies
    WHERE schemaname='public' AND tablename='settings' AND cmd='INSERT') ps,
  (SELECT count(*) n FROM information_schema.tables WHERE table_schema='public') t;
