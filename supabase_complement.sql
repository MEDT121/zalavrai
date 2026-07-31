-- ══════════════════════════════════════════════════════════════════════════
--  SchoolSafe — COMPLÉMENT à la migration consolidée
--  À coller dans un onglet SQL VIDE, sur la base de l'école.
--
--  `supabase_migration_finale.sql` a été exécutée et vérifiée. Elle a gagné
--  depuis trois colonnes et une reprise de données. Ce fichier ne contient
--  QUE ce complément — il évite de recoller 480 lignes déjà passées.
--
--  Le fichier consolidé reste la référence : toute nouvelle colonne s'y
--  ajoute. Celui-ci est un raccourci de circonstance, sans dommage à
--  relancer autant de fois qu'on veut.
-- ══════════════════════════════════════════════════════════════════════════

-- ── 1 — TROIS COLONNES ────────────────────────────────────────────────────
--
--  matieres.coeff      un cours ne pèse pas tous le même poids au bulletin ;
--                      sans cette colonne le coefficient saisi était rejeté
--                      et TOUTE la ligne de matière avec lui.
--  conduct.trimestre   la conduite pèse 15 % du classement ; sans trimestre,
--                      celle de septembre jugeait encore l'élève en juin.
--  conduct.school_id   comme partout ailleurs.
--
--  Une table absente n'interrompt pas : elle est signalée, la boucle continue.
DO $$
DECLARE
  t TEXT; c TEXT; ty TEXT; n INT := 0; manquantes TEXT := '';
BEGIN
  FOR t, c, ty IN
    SELECT * FROM (VALUES
      ('matieres','coeff','NUMERIC DEFAULT 1'),
      ('conduct','trimestre','TEXT'),
      ('conduct','school_id','TEXT')
    ) AS v(t,c,ty)
  LOOP
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables
                    WHERE table_schema='public' AND table_name=t) THEN
      manquantes := manquantes || t || ' ';
      CONTINUE;
    END IF;
    EXECUTE format('ALTER TABLE %I ADD COLUMN IF NOT EXISTS %I %s', t, c, ty);
    n := n + 1;
  END LOOP;
  RAISE NOTICE 'Colonnes traitees : % — tables absentes : %', n,
    COALESCE(NULLIF(manquantes,''),'aucune');
END $$;

-- ── 2 — RATTACHER CHAQUE NOTE À SON ANNÉE SCOLAIRE ────────────────────────
--
--  `grades.year` existait, mais seul le panneau de notes la renseignait :
--  une cote saisie en corrigeant un devoir avait `year` à NULL. La clôture
--  d'année purgeait pourtant les notes sur `year = <année>` — la requête
--  réussissait sans rien supprimer, et toutes les cotes de devoirs et
--  d'interros revenaient au premier sync, mêlées à celles de la nouvelle
--  année. Mesuré sur une réplique : 60 notes sur 100 survivaient.
--
--  L'application les rattache désormais à l'écriture. Celles déjà en base le
--  sont ici, d'après leur date. L'année scolaire congolaise court de
--  septembre à août : une note du 15/11/2025 comme une du 12/03/2026
--  appartiennent à 2025-2026.
--
--  Une note dont l'année est DÉJÀ renseignée n'est pas touchée.
UPDATE grades
   SET year = CASE
     WHEN substring(date from 6 for 2) >= '09'
       THEN substring(date from 1 for 4) || '-' || (substring(date from 1 for 4)::int + 1)::text
       ELSE (substring(date from 1 for 4)::int - 1)::text || '-' || substring(date from 1 for 4)
   END
 WHERE year IS NULL
   AND date ~ '^\d{4}-\d{2}';

-- ── VÉRIFICATION ──────────────────────────────────────────────────────────
--  L'éditeur Supabase n'affiche que le résultat de la DERNIÈRE requête :
--  celle-ci est donc seule, et se suffit.
SELECT
  CASE WHEN cols.n = 3 AND orphelines.n = 0 THEN 'TOUT EST EN PLACE'
       WHEN cols.n < 3                      THEN 'INCOMPLET : colonnes manquantes'
       ELSE 'INCOMPLET : des notes sans annee' END AS verdict,
  cols.n        AS colonnes_sur_3,
  notes.n       AS notes_total,
  rattachees.n  AS notes_avec_annee,
  orphelines.n  AS notes_sans_annee_datees
FROM
  (SELECT count(*) n FROM information_schema.columns
    WHERE table_schema='public'
      AND (table_name,column_name) IN
          (('matieres','coeff'),('conduct','trimestre'),('conduct','school_id'))) cols,
  (SELECT count(*) n FROM grades) notes,
  (SELECT count(*) n FROM grades WHERE year IS NOT NULL) rattachees,
  (SELECT count(*) n FROM grades WHERE year IS NULL AND date ~ '^\d{4}-\d{2}') orphelines;
