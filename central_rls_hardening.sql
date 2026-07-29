-- ══════════════════════════════════════════════════════════════════
--  PRODELI Central — Durcissement RLS
--  À lancer sur le projet CENTRAL (SQL Editor)
--
--  Corrige une exposition : la policy "anon_select_schools" laissait
--  n'importe quel visiteur lire la table `schools` — donc l'URL et la clé
--  d'accès à la base de TOUTES les écoles. La résolution license_key →
--  credentials se fait uniquement dans l'Edge Function `login`, qui utilise
--  la clé secrète et n'est donc pas soumise à RLS.
-- ══════════════════════════════════════════════════════════════════

-- ── schools : aucun accès client. Lecture réservée à la clé secrète ──
DROP POLICY IF EXISTS "anon_select_schools" ON schools;
DROP POLICY IF EXISTS "public_read_schools" ON schools;
ALTER TABLE schools ENABLE ROW LEVEL SECURITY;
-- Aucune policy = aucune ligne visible avec une clé publishable.
-- La clé secrète (Edge Function login / admin-api) contourne RLS.

-- ── card_orders : aucun accès client non plus ──
DROP POLICY IF EXISTS "anon_select_card_orders" ON card_orders;
ALTER TABLE card_orders ENABLE ROW LEVEL SECURITY;

-- ── school_announcements : lecture publique des annonces publiées ──
ALTER TABLE school_announcements ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "public_read_announcements" ON school_announcements;
CREATE POLICY "public_read_announcements" ON school_announcements
  FOR SELECT TO anon, authenticated
  USING (published = true);

-- ── school_sites : lecture publique des sites publiés ──
ALTER TABLE school_sites ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "public_read_sites" ON school_sites;
CREATE POLICY "public_read_sites" ON school_sites
  FOR SELECT TO anon, authenticated
  USING (published = true);

-- ── Vérification ──────────────────────────────────────────────────
SELECT tablename,
       COALESCE(string_agg(policyname, ', '), '— aucune (clé secrète seule)') AS policies
FROM pg_tables t
LEFT JOIN pg_policies p ON p.tablename = t.tablename AND p.schemaname = 'public'
WHERE t.schemaname = 'public'
  AND t.tablename IN ('schools','card_orders','school_announcements','school_sites')
GROUP BY tablename
ORDER BY tablename;
