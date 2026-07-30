-- ══════════════════════════════════════════════════════════════════
--  SchoolSafe — STOCKAGE DES PHOTOS
--  À lancer sur la base de l'ÉCOLE, dans un onglet SQL vide.
--
--  Crée le bucket `photos` et les droits que l'application exige.
--  Sans lui, chaque photo reste en base64 DANS la ligne de la base :
--  l'application continue de fonctionner, mais la base grossit vite et
--  les mêmes photos repartent à chaque synchronisation.
--
--  Un seul bucket, deux dossiers à l'intérieur :
--      photos/photos/   élèves, comptes, personnes autorisées
--      photos/cards/    cartes finies, pour rééditer un duplicata
--
--  Sans dommage à relancer.
-- ══════════════════════════════════════════════════════════════════

-- ── Le bucket, public en LECTURE ──────────────────────────────────
-- « Public » ne concerne que la lecture : une photo doit pouvoir
-- s'afficher dans un <img> sans jeton. L'écriture reste soumise aux
-- policies ci-dessous.
INSERT INTO storage.buckets (id, name, public)
VALUES ('photos', 'photos', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- ── Droits ────────────────────────────────────────────────────────
-- L'application se présente avec la clé publiable, donc sous le rôle
-- `anon`. Elle dépose (INSERT) et remplace (UPDATE, via l'en-tête
-- x-upsert), mais ne supprime jamais : aucun droit DELETE n'est
-- accordé — une photo effacée ne se retrouve pas.

DROP POLICY IF EXISTS "photos_lecture" ON storage.objects;
CREATE POLICY "photos_lecture" ON storage.objects
  FOR SELECT TO anon, authenticated
  USING (bucket_id = 'photos');

DROP POLICY IF EXISTS "photos_depot" ON storage.objects;
CREATE POLICY "photos_depot" ON storage.objects
  FOR INSERT TO anon, authenticated
  WITH CHECK (bucket_id = 'photos');

DROP POLICY IF EXISTS "photos_remplacement" ON storage.objects;
CREATE POLICY "photos_remplacement" ON storage.objects
  FOR UPDATE TO anon, authenticated
  USING (bucket_id = 'photos')
  WITH CHECK (bucket_id = 'photos');

-- ── VÉRIFICATION ──────────────────────────────────────────────────
SELECT
  CASE WHEN b.n = 1 AND p.n = 3 THEN 'STOCKAGE PRET' ELSE 'INCOMPLET' END AS verdict,
  b.n AS bucket_public,
  p.n AS policies_sur_3
FROM
  (SELECT count(*) n FROM storage.buckets WHERE id = 'photos' AND public) b,
  (SELECT count(*) n FROM pg_policies
    WHERE schemaname = 'storage' AND tablename = 'objects'
      AND policyname IN ('photos_lecture','photos_depot','photos_remplacement')) p;
