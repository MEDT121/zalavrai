-- ══════════════════════════════════════════════════════════════════
--  SchoolSafe — Central Supabase Migration v2.0
--  Run this on the CENTRAL Supabase (vcifxatmlgzueavalfks)
--  NOT on each school's own Supabase
-- ══════════════════════════════════════════════════════════════════

-- Expand school_sites table with all site management fields
ALTER TABLE school_sites
  ADD COLUMN IF NOT EXISTS school_name       text,
  ADD COLUMN IF NOT EXISTS school_name_en    text,
  ADD COLUMN IF NOT EXISTS address           text,
  ADD COLUMN IF NOT EXISTS phone             text,
  ADD COLUMN IF NOT EXISTS email             text,
  ADD COLUMN IF NOT EXISTS whatsapp          text,
  ADD COLUMN IF NOT EXISTS logo_url          text,
  ADD COLUMN IF NOT EXISTS hero_url          text,
  ADD COLUMN IF NOT EXISTS hero_photos       jsonb       DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS primary_color     varchar(7)  DEFAULT '#c0962e',
  ADD COLUMN IF NOT EXISTS theme             varchar(20) DEFAULT 'dark',
  ADD COLUMN IF NOT EXISTS mission           text,
  ADD COLUMN IF NOT EXISTS founded_year      int,
  ADD COLUMN IF NOT EXISTS city              text,
  ADD COLUMN IF NOT EXISTS staff             jsonb       DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS gallery           jsonb       DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS programs          jsonb       DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS pillars           jsonb       DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS stats             jsonb       DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS social            jsonb       DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS updated_at        timestamptz DEFAULT now();

-- Index for fast lookups by license_key (if not already present)
CREATE INDEX IF NOT EXISTS idx_school_sites_license_key ON school_sites(license_key);

-- Allow anonymous SELECT on school_sites (public site reads)
CREATE POLICY IF NOT EXISTS "public_read_school_sites"
  ON school_sites FOR SELECT
  USING (published = true);

-- Allow authenticated (apikey) PATCH — schools update via anon key with license_key filter
-- This is already covered by the existing RLS or service role in admin

-- ──────────────────────────────────────────────────────────────────
--  school_announcements table (create if missing)
-- ──────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS school_announcements (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  license_key  text NOT NULL,
  school_name  text,
  title        text NOT NULL,
  content      text,
  date         date DEFAULT current_date,
  published    boolean DEFAULT true,
  created_at   timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_ann_license_key ON school_announcements(license_key);
CREATE INDEX IF NOT EXISTS idx_ann_date        ON school_announcements(date DESC);

-- Public read for published announcements
ALTER TABLE school_announcements ENABLE ROW LEVEL SECURITY;

CREATE POLICY IF NOT EXISTS "public_read_announcements"
  ON school_announcements FOR SELECT
  USING (published = true);

-- ──────────────────────────────────────────────────────────────────
--  card_orders table (create if missing)
-- ──────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS card_orders (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  school_name  text NOT NULL,
  quantity     int  NOT NULL DEFAULT 0,
  status       varchar(20) NOT NULL DEFAULT 'pending',
  notes        text,
  ordered_at   timestamptz DEFAULT now(),
  delivered_at timestamptz
);

CREATE INDEX IF NOT EXISTS idx_card_orders_school ON card_orders(school_name);
CREATE INDEX IF NOT EXISTS idx_card_orders_status ON card_orders(status);
