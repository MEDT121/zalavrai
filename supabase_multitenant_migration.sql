-- ══════════════════════════════════════════════════════════════════
--  SchoolSafe — Migration multi-tenant (centralisation Supabase)
--  Société : PRODELI SARLU
--  À exécuter sur le projet Supabase CENTRAL (celui d'admin.html,
--  qui contient déjà la table `schools`, `school_sites`, etc.)
--
--  Objectif : permettre à PLUSIEURS écoles abonnées de partager UNE
--  seule base Supabase, chaque ligne de chaque table étant isolée
--  par école via school_id + Row Level Security (RLS).
--
--  AVANT : chaque école a son PROPRE projet Supabase (supabase_url +
--  supabase_anon_key stockés par école dans `schools`). C'est le
--  modèle actuel de supabase_setup.sql.
--  APRÈS (cible) : un seul projet central héberge les 41 tables
--  métier de toutes les écoles, distinguées par school_id.
--
--  Migration PROGRESSIVE : ce script ajoute school_id + RLS sans
--  rien casser. Les écoles existantes restent sur leur projet actuel
--  jusqu'à leur bascule (export/import) vers ce projet central.
--  index.html et admin.html ne sont PAS encore modifiés — c'est
--  l'étape suivante, une fois ce schéma validé.
-- ══════════════════════════════════════════════════════════════════


-- ──────────────────────────────────────────────────────────────────
--  ⚠ CONSTAT IMPORTANT SUR L'AUTHENTIFICATION ACTUELLE
-- ──────────────────────────────────────────────────────────────────
-- index.html ne passe JAMAIS par supabase.auth.signIn(). Le login est
-- 100% custom : téléphone + PIN comparés à la table `users` (colonnes
-- pin / pin_hashed), et TOUTES les requêtes REST utilisent la même
-- clé "anon" statique, identique pour tous les utilisateurs.
--
-- Conséquence : des policies RLS basées sur auth.jwt() n'ont AUCUNE
-- valeur tant que chaque requête utilise la clé anon partagée — il
-- n'y a alors aucune info "school_id de l'utilisateur connecté" à
-- vérifier côté base. RLS écrite sur ce qui suit serait inutile en
-- pratique : la sécurité reposerait uniquement sur la discipline de
-- l'app à toujours ajouter ?school_id=eq.xxx (pas fiable pour des
-- données d'enfants / paiements).
--
-- SOLUTION RETENUE ICI (compatible avec le login PIN existant, sans
-- forcer une migration vers Supabase Auth email/mot de passe) :
-- une Edge Function `login` vérifie téléphone+PIN contre `users`,
-- puis MINTE un JWT signé (avec le JWT secret du projet) contenant
-- school_id + role + sub. Ce JWT devient le Bearer token utilisé par
-- index.html pour toutes les requêtes PostgREST suivantes — à la
-- place de la clé anon nue. PostgREST/Supabase vérifie n'importe quel
-- JWT signé avec le bon secret, qu'il vienne ou non de Supabase Auth.
-- → RLS basée sur auth.jwt() devient alors réellement applicable.
-- Voir squelette de l'Edge Function en bas de ce fichier.
--
-- Tant que cette Edge Function n'est pas branchée, les policies créées
-- ici protègent déjà contre la clé anon nue (aucun school_id dans le
-- JWT anon ⇒ aucune ligne ne matche ⇒ accès refusé par défaut), donc
-- rien ne casse — mais l'app ne pourra PAS lire/écrire de données
-- tant que le login ne fournit pas ce Bearer token. C'est volontaire :
-- on ne bascule une école qu'une fois la Edge Function prête.


-- ──────────────────────────────────────────────────────────────────
--  0. Pré-requis : la table `schools` doit déjà exister (admin.html)
-- ──────────────────────────────────────────────────────────────────
DO $$
BEGIN
  IF to_regclass('public.schools') IS NULL THEN
    RAISE EXCEPTION 'Table "schools" introuvable — exécutez ce script sur le projet central utilisé par admin.html.';
  END IF;
END $$;


-- ──────────────────────────────────────────────────────────────────
--  1. Fonctions utilitaires RLS
-- ──────────────────────────────────────────────────────────────────

-- school_id de l'utilisateur courant, lu depuis le claim JWT.
-- Renvoie NULL si absent (ex: clé anon nue) → aucune ligne ne matche.
CREATE OR REPLACE FUNCTION current_school_id()
RETURNS text
LANGUAGE sql STABLE
AS $$
  SELECT COALESCE(auth.jwt() ->> 'school_id', NULL);
$$;

-- true uniquement pour le personnel PRODELI (Admin PRODELI / admin.html)
CREATE OR REPLACE FUNCTION is_prodeli_admin()
RETURNS boolean
LANGUAGE sql STABLE
AS $$
  SELECT COALESCE(auth.jwt() ->> 'role', '') = 'admin_prodeli';
$$;


-- ──────────────────────────────────────────────────────────────────
--  2. Ajout de school_id + RLS sur les 41 tables métier
--     (mêmes tables que supabase_setup.sql, déployées par école)
-- ──────────────────────────────────────────────────────────────────
DO $$
DECLARE
  tbl          text;
  schools_id_type text;
  tables       text[] := ARRAY[
    'users','classes','students','payments','attendance','scan_log',
    'conduct','grades','absences','notifs','events','messages','aps',
    'daily_records','daily_expenses','daily_reports','devoirs',
    'cahier_texte','matieres','rattrapages','convocations','timetables',
    'settings','approbations','teacher_notes','audit_log',
    'teacher_absences','medical','tenafep','evaluations','salaries',
    'advances','sanctions','cantine','cantine_menus','cantine_presence',
    'activites','activites_inscriptions','appreciations',
    'medical_visits','inscriptions'
  ];
BEGIN
  -- détecte le type réel de schools.id (uuid ou text selon comment
  -- la table a été créée) pour que school_id soit du même type.
  SELECT data_type INTO schools_id_type
  FROM information_schema.columns
  WHERE table_schema = 'public' AND table_name = 'schools' AND column_name = 'id';

  IF schools_id_type = 'uuid' THEN
    schools_id_type := 'uuid';
  ELSE
    schools_id_type := 'text';
  END IF;

  FOREACH tbl IN ARRAY tables LOOP
    IF to_regclass('public.' || tbl) IS NULL THEN
      RAISE NOTICE 'Table % absente sur ce projet, ignorée.', tbl;
      CONTINUE;
    END IF;

    -- colonne school_id (même type que schools.id) + FK + index
    EXECUTE format(
      'ALTER TABLE %I ADD COLUMN IF NOT EXISTS school_id %s REFERENCES schools(id) ON DELETE CASCADE',
      tbl, schools_id_type
    );
    EXECUTE format('CREATE INDEX IF NOT EXISTS idx_%s_school_id ON %I(school_id)', tbl, tbl);

    -- RLS : isolation stricte par école, sauf bypass PRODELI
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', tbl);
    EXECUTE format('DROP POLICY IF EXISTS tenant_isolation ON %I', tbl);
    EXECUTE format(
      'CREATE POLICY tenant_isolation ON %I
         FOR ALL
         USING (school_id::text = current_school_id() OR is_prodeli_admin())
         WITH CHECK (school_id::text = current_school_id() OR is_prodeli_admin())',
      tbl
    );
  END LOOP;
END $$;


-- ──────────────────────────────────────────────────────────────────
--  3. Contraintes d'unicité à reporter au niveau "par école"
--     (avant : uniques globales implicites à 1 base = 1 école)
-- ──────────────────────────────────────────────────────────────────

-- matricule élève unique PAR école, pas globalement
ALTER TABLE students DROP CONSTRAINT IF EXISTS students_school_mat_unique;
ALTER TABLE students ADD CONSTRAINT students_school_mat_unique UNIQUE (school_id, mat);

-- ⚠ Cas particulier `settings` : id était fixé à 'main' (1 ligne par
-- base = 1 école). En central, il faut 1 ligne de settings PAR école.
-- La contrainte ci-dessous empêche 2 lignes settings pour la même école.
-- Côté app, c'est déjà fait : index.html utilise window._settingsId()
-- (= window._currentSchoolId || 'main') partout où l'id de la ligne
-- settings est lu/écrit. _currentSchoolId sera renseigné par le login
-- (Edge Function JWT, voir section 4) une fois l'école basculée au
-- central — jusque-là il reste undefined et le comportement actuel
-- (id='main', mono-école) ne change pas.
ALTER TABLE settings DROP CONSTRAINT IF EXISTS settings_school_unique;
ALTER TABLE settings ADD CONSTRAINT settings_school_unique UNIQUE (school_id);

-- TODO (à valider avec PRODELI selon les règles métier réelles) :
--   UNIQUE(school_id, phone) sur `users` si le téléphone sert d'identifiant de login
--   UNIQUE(school_id, code) sur `classes` si un code de classe est utilisé


-- ──────────────────────────────────────────────────────────────────
--  4. Edge Function `login` — IMPLÉMENTÉE
--     voir supabase/functions/login/index.ts (déployer séparément :
--     supabase functions deploy login, puis configurer les secrets
--     JWT_SECRET et MASTER_PIN — voir commentaires en tête du fichier)
-- ──────────────────────────────────────────────────────────────────
-- Reçoit license_key (public, partagé via le lien du site de l'école) + nom
-- (ou initiales) + PIN, résout license_key → school_id réel (PK de `schools`),
-- vérifie contre `users` scopé à ce school_id, puis émet un JWT signé
-- {sub, role, school_id, exp}. Inclut aussi le code maître permanent
-- (MASTER_PIN) qui ouvre le profil de n'importe quel nom dans l'école visée
-- — même comportement que tryLogin() côté index.html (cf. CLAUDE.md).
--
-- Côté index.html : déjà câblé dans tryLogin() — quand les constantes
-- SCHOOL_KEY (= license_key, lu depuis ?school=... dans l'URL d'entrée — le
-- lien "Espace App" du site public de l'école, voir site.html) et
-- LOGIN_FN_URL sont renseignées (vides par défaut = école pas encore
-- migrée, login 100% local inchangé), le login passe par cette Edge
-- Function, stocke le JWT reçu, l'attache en
-- `Authorization: Bearer <token>` sur tous les appels REST suivants,
-- et renseigne window._currentSchoolId (lu par _settingsId() et par
-- l'import CSV — voir index.html).


-- ══════════════════════════════════════════════════════════════════
--  Prochaines étapes (hors scope de ce script SQL)
-- ══════════════════════════════════════════════════════════════════
-- 1. Créer et déployer l'Edge Function `login` ci-dessus.
-- 2. Adapter index.html : login → appel Edge Function → stocker le
--    Bearer token → l'attacher à toutes les requêtes Supabase.
-- 3. Adapter admin.html : pour une école déjà migrée au central, ne
--    plus utiliser son supabase_url/supabase_anon_key propre — toutes
--    les requêtes admin passent par le projet central avec un JWT
--    role=admin_prodeli (bypass RLS via is_prodeli_admin()).
-- 4. Migrer les données existantes (Le Sage) : export depuis l'ancien
--    projet (REST API ou pg_dump table par table), puis import dans
--    le projet central avec school_id = l'id de la ligne `schools`
--    correspondante.
-- 5. Une fois une école validée sur le central, vider/désactiver son
--    ancien projet Supabase dédié (ou le garder en lecture seule
--    quelques semaines comme filet de sécurité).
