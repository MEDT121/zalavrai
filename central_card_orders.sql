-- ══════════════════════════════════════════════════════════════════
--  PRODELI Central — Commandes de cartes élèves
--  À lancer sur le projet CENTRAL (SQL Editor)
--
--  SchoolSafe envoie une commande par élève, avec les données nécessaires
--  à l'impression. La table d'origine n'avait que 8 colonnes génériques :
--  toute commande était rejetée par PostgREST (colonne inexistante).
--
--  Aucune policy RLS n'est ajoutée volontairement : les commandes portent
--  des données personnelles d'élèves et de parents. Elles ne sont jamais
--  lisibles avec une clé publishable — l'Edge Function centrale valide la
--  licence puis filtre elle-même par école.
-- ══════════════════════════════════════════════════════════════════

ALTER TABLE card_orders
  ADD COLUMN IF NOT EXISTS student_name            TEXT,
  ADD COLUMN IF NOT EXISTS student_mat             TEXT,
  ADD COLUMN IF NOT EXISTS student_dob             TEXT,
  ADD COLUMN IF NOT EXISTS student_lieu_naissance  TEXT,
  ADD COLUMN IF NOT EXISTS student_num_inscription TEXT,
  ADD COLUMN IF NOT EXISTS student_adresse         TEXT,
  ADD COLUMN IF NOT EXISTS student_class           TEXT,
  ADD COLUMN IF NOT EXISTS student_cycle           TEXT,
  ADD COLUMN IF NOT EXISTS teacher_name            TEXT,
  ADD COLUMN IF NOT EXISTS parent_name             TEXT,
  ADD COLUMN IF NOT EXISTS parent_phone            TEXT,
  ADD COLUMN IF NOT EXISTS school_phone            TEXT,
  ADD COLUMN IF NOT EXISTS school_address          TEXT,
  ADD COLUMN IF NOT EXISTS school_dgep             TEXT,
  ADD COLUMN IF NOT EXISTS school_year             TEXT,
  ADD COLUMN IF NOT EXISTS director_name           TEXT,
  ADD COLUMN IF NOT EXISTS card_image_url          TEXT;

-- Une commande par élève : la quantité vaut 1 par défaut.
ALTER TABLE card_orders ALTER COLUMN quantity SET DEFAULT 1;

CREATE INDEX IF NOT EXISTS idx_card_orders_ordered ON card_orders(ordered_at DESC);

-- Confirme qu'aucune policy n'ouvre la table à la clé publishable.
ALTER TABLE card_orders ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "anon_select_card_orders" ON card_orders;
DROP POLICY IF EXISTS "anon_insert_card_orders" ON card_orders;

-- ── Vérification ──────────────────────────────────────────────────
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'card_orders'
ORDER BY ordinal_position;

SELECT COALESCE(string_agg(policyname, ', '), '— aucune (Edge Function seule) ✅') AS policies
FROM pg_policies WHERE schemaname = 'public' AND tablename = 'card_orders';
