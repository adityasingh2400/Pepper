-- Pepper v1.5 — compound metadata v2
-- Adds the structured data the new Pinning/Calculator/Timeline/Research views need.

-- 1. Extend the `compounds` table with first-class fields used by every surface
ALTER TABLE compounds
  ADD COLUMN IF NOT EXISTS goal_categories         text[] DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS administration_routes   text[] DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS time_to_effect_hours    numeric,
  ADD COLUMN IF NOT EXISTS peak_effect_hours       numeric,
  ADD COLUMN IF NOT EXISTS duration_hours          numeric,
  ADD COLUMN IF NOT EXISTS dosing_formula          text,
  ADD COLUMN IF NOT EXISTS dosing_unit             text,
  ADD COLUMN IF NOT EXISTS dosing_frequency        text,
  ADD COLUMN IF NOT EXISTS bac_water_ml_default    numeric,
  ADD COLUMN IF NOT EXISTS storage_temp            text,
  ADD COLUMN IF NOT EXISTS storage_max_days        int,
  ADD COLUMN IF NOT EXISTS needle_gauge_default    text,
  ADD COLUMN IF NOT EXISTS needle_length_default   text;

-- 2. Pin sites (anatomy library)
--    Every pin site has a stable string id, a normalized hotspot on a body image,
--    and step-by-step technique markdown. Sites are global (not per-compound).
CREATE TABLE IF NOT EXISTS pin_sites (
  id              text PRIMARY KEY,
  region          text NOT NULL,           -- "abdomen", "thigh", "deltoid", "glute", "tricep"
  side            text,                    -- "left", "right", null for centered
  route           text NOT NULL CHECK (route IN ('subq', 'im')),
  display_name    text NOT NULL,
  body_view       text NOT NULL CHECK (body_view IN ('front', 'back')),
  hotspot_x       numeric NOT NULL,        -- 0..1 normalized
  hotspot_y       numeric NOT NULL,        -- 0..1 normalized
  technique_md    text NOT NULL,
  rotation_advice text,
  pinch_required  boolean DEFAULT false,
  created_at      timestamptz DEFAULT now()
);
ALTER TABLE pin_sites ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can read pin sites"
  ON pin_sites FOR SELECT USING (true);

-- 3. Compound → pin site recommendations
CREATE TABLE IF NOT EXISTS compound_pin_sites (
  compound_id    uuid REFERENCES compounds(id) ON DELETE CASCADE NOT NULL,
  pin_site_id    text REFERENCES pin_sites(id) ON DELETE CASCADE NOT NULL,
  preference     int DEFAULT 0,            -- 0=primary, 1=secondary, 2=avoid
  rationale      text,
  PRIMARY KEY (compound_id, pin_site_id)
);
ALTER TABLE compound_pin_sites ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can read compound pin sites"
  ON compound_pin_sites FOR SELECT USING (true);

-- 4. Citations (peer-reviewed sources, scoped to a compound + topic)
CREATE TABLE IF NOT EXISTS citations (
  id             uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  compound_id    uuid REFERENCES compounds(id) ON DELETE CASCADE,
  pubmed_id      text,
  doi            text,
  title          text NOT NULL,
  authors        text,
  year           int,
  journal        text,
  url            text,
  topic          text,                     -- "dosing", "safety", "mechanism", "weight_loss", "recovery", etc
  relevance      text,                     -- one-line "why this matters"
  evidence_grade text,                     -- "A" (RCT), "B" (cohort), "C" (case), "preclinical"
  created_at     timestamptz DEFAULT now()
);
CREATE INDEX IF NOT EXISTS citations_compound_topic_idx
  ON citations (compound_id, topic);
ALTER TABLE citations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can read citations"
  ON citations FOR SELECT USING (true);

-- 5. Goal categories lookup (used by the new onboarding goal multi-select)
CREATE TABLE IF NOT EXISTS goal_categories (
  id          text PRIMARY KEY,
  display     text NOT NULL,
  description text NOT NULL,
  icon        text,                        -- SF Symbol name
  sort_order  int DEFAULT 0
);
ALTER TABLE goal_categories ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can read goal categories"
  ON goal_categories FOR SELECT USING (true);

-- Seed canonical goals so the onboarding UI has something to render even before content sync
INSERT INTO goal_categories (id, display, description, icon, sort_order) VALUES
  ('recovery',   'Recovery & Healing',  'Tendons, joints, gut, post-injury repair',     'bandage.fill',          1),
  ('growth',     'Muscle & Growth',     'GH pulse, lean mass, IGF-1',                   'figure.strengthtraining.traditional', 2),
  ('fat_loss',   'Fat Loss',            'Appetite, GLP-1, lipolysis',                   'flame.fill',            3),
  ('longevity',  'Longevity',           'Cellular health, mitochondrial, telomere',     'leaf.fill',             4),
  ('cognitive',  'Cognitive',           'Focus, memory, mood, neuroprotection',         'brain.head.profile',    5),
  ('libido',     'Libido & Performance','Sexual function, energy',                      'flame.circle.fill',     6),
  ('skin_hair',  'Skin & Hair',         'Collagen, copper peptides, regeneration',      'sparkles',              7),
  ('immune',     'Immune Support',      'Antimicrobial, immune modulation',             'shield.lefthalf.filled',8),
  ('sleep',      'Sleep',               'Deep sleep, GH pulse, recovery',               'moon.stars.fill',       9)
ON CONFLICT (id) DO NOTHING;

-- 6. Convenience view for "active pinned" compounds with pin site joined
CREATE OR REPLACE VIEW v_compound_metadata AS
SELECT
  c.*,
  (
    SELECT json_agg(json_build_object(
      'pin_site_id', cps.pin_site_id,
      'preference',  cps.preference,
      'rationale',   cps.rationale,
      'region',      ps.region,
      'side',        ps.side,
      'route',       ps.route,
      'display_name', ps.display_name,
      'body_view',   ps.body_view,
      'hotspot_x',   ps.hotspot_x,
      'hotspot_y',   ps.hotspot_y
    ) ORDER BY cps.preference)
    FROM compound_pin_sites cps
    JOIN pin_sites ps ON ps.id = cps.pin_site_id
    WHERE cps.compound_id = c.id
  ) AS pin_sites,
  (
    SELECT json_agg(json_build_object(
      'id',         cit.id,
      'title',      cit.title,
      'authors',    cit.authors,
      'year',       cit.year,
      'journal',    cit.journal,
      'url',        cit.url,
      'pubmed_id',  cit.pubmed_id,
      'topic',      cit.topic,
      'relevance',  cit.relevance,
      'evidence_grade', cit.evidence_grade
    ) ORDER BY cit.year DESC NULLS LAST)
    FROM citations cit
    WHERE cit.compound_id = c.id
  ) AS citations
FROM compounds c;
