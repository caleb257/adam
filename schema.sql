-- ============================================================
-- ADAM BRAIN DATABASE SCHEMA
-- Coralstone Capital Group - Acquisitions Intelligence System
-- ============================================================

-- ── MARKET INTELLIGENCE ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS market_areas (
  id SERIAL PRIMARY KEY,
  county TEXT NOT NULL,
  city TEXT,
  zip_code TEXT,
  state TEXT DEFAULT 'FL',
  -- Pricing
  median_sale_price INTEGER,
  avg_price_per_sqft DECIMAL,
  med_price_3br INTEGER,
  med_price_4br INTEGER,
  -- Rental
  avg_rent_studio INTEGER,
  avg_rent_1br INTEGER,
  avg_rent_2br INTEGER,
  avg_rent_3br INTEGER,
  avg_rent_4br INTEGER,
  hud_fmr_efficiency INTEGER,
  hud_fmr_1br INTEGER,
  hud_fmr_2br INTEGER,
  hud_fmr_3br INTEGER,
  hud_fmr_4br INTEGER,
  -- Market velocity
  avg_days_on_market INTEGER,
  months_of_inventory DECIMAL,
  list_to_sale_ratio DECIMAL,
  -- Investor intelligence
  investor_buyer_pct DECIMAL,
  retail_buyer_pct DECIMAL,
  -- Risk factors
  flood_zone_prevalence TEXT, -- 'low', 'medium', 'high'
  sinkhole_risk TEXT,
  -- Appreciation
  yoy_appreciation_pct DECIMAL,
  five_yr_appreciation_pct DECIMAL,
  -- Competition
  competition_level TEXT, -- 'low', 'medium', 'high', 'very_high'
  avg_offers_per_listing INTEGER,
  -- CCG priority
  ccg_priority TEXT, -- 'primary', 'secondary', 'watch', 'avoid'
  ccg_notes TEXT,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── HUD FAIR MARKET RENTS ────────────────────────────────────
CREATE TABLE IF NOT EXISTS hud_fmr (
  id SERIAL PRIMARY KEY,
  metro_area TEXT,
  county TEXT,
  fiscal_year INTEGER,
  efficiency INTEGER,
  one_br INTEGER,
  two_br INTEGER,
  three_br INTEGER,
  four_br INTEGER,
  notes TEXT,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── REHAB COST BENCHMARKS ────────────────────────────────────
CREATE TABLE IF NOT EXISTS rehab_costs (
  id SERIAL PRIMARY KEY,
  trade TEXT NOT NULL,
  item TEXT NOT NULL,
  scope TEXT, -- 'repair', 'light', 'medium', 'full', 'replacement'
  unit TEXT, -- 'sqft', 'unit', 'each', 'lf', 'per_home'
  cost_low DECIMAL,
  cost_mid DECIMAL,
  cost_high DECIMAL,
  florida_specific_notes TEXT,
  common_hidden_costs TEXT,
  typical_overrun_pct DECIMAL DEFAULT 10,
  red_flags TEXT,
  inspector_notes TEXT,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── CCG BUY CRITERIA ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS buy_criteria (
  id SERIAL PRIMARY KEY,
  deal_type TEXT NOT NULL, -- 'flip', 'rental', 'brrrr', 'wholesale'
  label TEXT,
  -- Property specs
  min_beds INTEGER DEFAULT 3,
  min_baths DECIMAL DEFAULT 2,
  min_sqft INTEGER,
  max_sqft INTEGER,
  preferred_construction TEXT[],
  year_built_min INTEGER,
  year_built_max INTEGER,
  property_types TEXT[],
  -- Financial thresholds
  min_profit INTEGER,
  min_profit_pct DECIMAL,
  min_roi_pct DECIMAL,
  min_coc_return_pct DECIMAL,
  max_purchase_price INTEGER,
  max_arv INTEGER,
  -- Financing
  hml_rate_pct DECIMAL DEFAULT 9.5,
  hml_ltv DECIMAL DEFAULT 90,
  hml_points DECIMAL DEFAULT 2,
  -- Market requirements
  preferred_counties TEXT[],
  acceptable_counties TEXT[],
  preferred_zips TEXT[],
  max_distance_from_tampa_miles INTEGER DEFAULT 60,
  -- BRRRR specific
  brrrr_refi_rate DECIMAL DEFAULT 6.75,
  brrrr_refi_ltv DECIMAL DEFAULT 75,
  brrrr_max_cash_left_in_pct DECIMAL DEFAULT 25,
  brrrr_min_cashflow_after_dscr INTEGER DEFAULT 0,
  brrrr_target_cashflow INTEGER DEFAULT 200,
  -- Rental specific
  rental_dscr_rate DECIMAL DEFAULT 6.75,
  rental_dscr_ltv DECIMAL DEFAULT 75,
  rental_min_cashflow INTEGER DEFAULT 0,
  rental_target_cashflow INTEGER DEFAULT 150,
  -- Wholesale specific
  wholesale_min_assignment_fee INTEGER DEFAULT 15000,
  wholesale_max_buy_pct_arv DECIMAL DEFAULT 65,
  -- Risk thresholds
  max_rehab_budget INTEGER,
  max_rehab_pct_arv DECIMAL,
  avoid_flood_zones BOOLEAN DEFAULT TRUE,
  avoid_hoa BOOLEAN DEFAULT FALSE,
  max_hoa_monthly INTEGER DEFAULT 200,
  -- Adam behavior
  adam_urgency_level TEXT DEFAULT 'normal',
  notes TEXT,
  active BOOLEAN DEFAULT TRUE,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── WHOLESALER PROFILES ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS wholesalers (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  company TEXT,
  phone TEXT,
  email TEXT,
  website TEXT,
  social_media TEXT,
  -- Location
  base_city TEXT,
  base_county TEXT,
  -- Relationship
  grade TEXT DEFAULT 'unknown', -- 'A', 'B', 'C', 'unknown', 'blacklisted'
  relationship_status TEXT DEFAULT 'new', -- 'active', 'warm', 'cold', 'burned', 'new', 'blacklisted'
  first_contact_date DATE,
  last_contact_date DATE,
  how_we_met TEXT,
  -- Performance metrics
  total_deals_submitted INTEGER DEFAULT 0,
  hot_buy_deals INTEGER DEFAULT 0,
  deals_ccg_purchased INTEGER DEFAULT 0,
  deals_ccg_wholesaled INTEGER DEFAULT 0,
  avg_arv_inflation_pct DECIMAL DEFAULT 0,
  arv_accuracy_rating TEXT DEFAULT 'unknown',
  -- Territory and product
  primary_counties TEXT[],
  primary_zips TEXT[],
  typical_deal_types TEXT[],
  typical_price_range_low INTEGER,
  typical_price_range_high INTEGER,
  typical_property_types TEXT[],
  -- Communication profile
  preferred_contact_method TEXT DEFAULT 'text',
  best_contact_time TEXT,
  response_time_avg_hours DECIMAL,
  ghosting_tendency TEXT DEFAULT 'unknown',
  negotiation_style TEXT DEFAULT 'unknown',
  -- Intelligence
  list_sources TEXT, -- where they find their deals
  buyer_network_size TEXT, -- 'large', 'medium', 'small', 'solo'
  daisy_chain_tendency BOOLEAN DEFAULT FALSE,
  arv_source TEXT, -- how they comp deals
  repair_estimate_quality TEXT, -- 'accurate', 'optimistic', 'unreliable'
  -- History with CCG
  last_deal_outcome TEXT,
  best_deal_with_ccg TEXT,
  issues_history TEXT,
  -- Adam notes
  adam_notes TEXT,
  adam_contact_strategy TEXT,
  caleb_private_notes TEXT,
  -- Flags
  tags TEXT[],
  do_not_contact BOOLEAN DEFAULT FALSE,
  require_caleb_approval BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── CASH BUYERS LIST ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS cash_buyers (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  company TEXT,
  phone TEXT,
  email TEXT,
  buyer_type TEXT, -- 'flipper', 'landlord', 'brrrr', 'developer', 'homeowner'
  -- Buy criteria
  buys_counties TEXT[],
  buys_zips TEXT[],
  buys_property_types TEXT[],
  min_beds INTEGER,
  max_beds INTEGER,
  min_sqft INTEGER,
  max_sqft INTEGER,
  min_price INTEGER,
  max_price INTEGER,
  max_rehab_tolerance TEXT, -- 'turnkey', 'light', 'heavy', 'any'
  preferred_construction TEXT[],
  -- Performance
  deals_purchased_from_ccg INTEGER DEFAULT 0,
  total_deals_purchased_known INTEGER,
  avg_close_time_days INTEGER DEFAULT 14,
  emd_default_count INTEGER DEFAULT 0,
  reliability_score TEXT DEFAULT 'unknown', -- 'A', 'B', 'C', 'blacklisted'
  proof_of_funds_verified BOOLEAN DEFAULT FALSE,
  pof_amount INTEGER,
  -- Contact
  preferred_contact TEXT DEFAULT 'text',
  response_speed TEXT DEFAULT 'unknown', -- 'same_day', 'next_day', 'slow', 'unreliable'
  best_contact_time TEXT,
  -- Notes
  how_we_met TEXT,
  notes TEXT,
  last_contact_date DATE,
  last_deal_date DATE,
  active BOOLEAN DEFAULT TRUE,
  do_not_use BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── DEAL PIPELINE ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS deals (
  id SERIAL PRIMARY KEY,
  uid TEXT UNIQUE,
  -- Property
  address TEXT NOT NULL,
  city TEXT,
  county TEXT,
  zip TEXT,
  state TEXT DEFAULT 'FL',
  beds INTEGER,
  baths DECIMAL,
  sqft INTEGER,
  year_built INTEGER,
  property_type TEXT,
  construction_type TEXT,
  flood_zone TEXT,
  hoa BOOLEAN DEFAULT FALSE,
  hoa_monthly INTEGER,
  -- Source
  source TEXT, -- 'derek_sheet', 'wholesaler_direct', 'mls', 'probate', 'direct_mail', 'off_market'
  wholesaler_id INTEGER REFERENCES wholesalers(id),
  wholesaler_arv INTEGER,
  wholesaler_repair_estimate INTEGER,
  wholesaler_asking_price INTEGER,
  -- Urban verdicts
  urban_verdict TEXT,
  urban_score DECIMAL,
  urban_arv INTEGER,
  urban_rehab INTEGER,
  urban_mao INTEGER,
  urban_projected_profit INTEGER,
  urban_brrrr_viable BOOLEAN,
  urban_cash_flow_est INTEGER,
  -- Adam's assessment
  adam_exit_recommendation TEXT, -- 'flip', 'rental', 'brrrr', 'wholesale', 'pass'
  adam_projected_profit INTEGER,
  adam_confidence TEXT,
  adam_concern_flags TEXT[],
  adam_assessment TEXT,
  adam_urgency TEXT,
  -- Pricing
  asking_price INTEGER,
  our_opening_offer INTEGER,
  our_current_offer INTEGER,
  accepted_price INTEGER,
  -- Pipeline status
  status TEXT DEFAULT 'INCOMING',
  -- INCOMING, SCORED, OFFER_SENT, NEGOTIATING, UNDER_CONTRACT,
  -- INSPECTION, CLOSING, CLOSED, DEAD, WHOLESALE_LISTED, WHOLESALED
  dead_reason TEXT,
  -- Dates
  date_received TIMESTAMPTZ DEFAULT NOW(),
  date_scored TIMESTAMPTZ,
  date_offer_sent TIMESTAMPTZ,
  date_accepted TIMESTAMPTZ,
  inspection_deadline TIMESTAMPTZ,
  emd_deadline TIMESTAMPTZ,
  close_date TIMESTAMPTZ,
  date_closed TIMESTAMPTZ,
  -- Contract
  emd_amount INTEGER,
  inspection_period_days INTEGER DEFAULT 10,
  assignment_fee INTEGER, -- for wholesale
  -- Buyer (for wholesale)
  buyer_id INTEGER REFERENCES cash_buyers(id),
  -- Outcome
  actual_purchase_price INTEGER,
  actual_rehab_cost INTEGER,
  actual_sale_price INTEGER,
  actual_profit INTEGER,
  -- Approval
  caleb_approved BOOLEAN,
  caleb_approved_at TIMESTAMPTZ,
  caleb_notes TEXT,
  grant_notified BOOLEAN DEFAULT FALSE,
  -- Adam actions
  adam_outreach_count INTEGER DEFAULT 0,
  adam_last_action TEXT,
  adam_next_action TEXT,
  adam_next_action_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── CONVERSATIONS ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS conversations (
  id SERIAL PRIMARY KEY,
  deal_id INTEGER REFERENCES deals(id),
  wholesaler_id INTEGER REFERENCES wholesalers(id),
  buyer_id INTEGER REFERENCES cash_buyers(id),
  party_name TEXT,
  direction TEXT NOT NULL, -- 'outbound', 'inbound'
  channel TEXT DEFAULT 'sms', -- 'sms', 'email', 'call'
  message TEXT NOT NULL,
  -- Approval flow
  draft_shown_to_caleb BOOLEAN DEFAULT FALSE,
  caleb_approved BOOLEAN,
  caleb_approved_at TIMESTAMPTZ,
  caleb_edited BOOLEAN DEFAULT FALSE,
  original_draft TEXT,
  -- Timing
  sent_at TIMESTAMPTZ,
  received_at TIMESTAMPTZ,
  -- Adam interpretation
  adam_interpretation TEXT,
  adam_detected_intent TEXT, -- 'counter', 'interested', 'ghosting', 'pof_request', 'dead'
  adam_confidence DECIMAL,
  action_taken TEXT,
  -- Trust tracking
  was_autonomous BOOLEAN DEFAULT FALSE,
  trust_action_type TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── NEGOTIATION PLAYBOOK ─────────────────────────────────────
CREATE TABLE IF NOT EXISTS negotiation_playbook (
  id SERIAL PRIMARY KEY,
  situation TEXT NOT NULL,
  wholesaler_grade TEXT, -- 'A', 'B', 'C', 'any'
  deal_type TEXT, -- 'flip', 'wholesale', 'brrrr', 'any'
  context TEXT,
  recommended_approach TEXT NOT NULL,
  example_script TEXT,
  what_not_to_do TEXT,
  follow_up_if_no_response TEXT,
  success_indicators TEXT,
  failure_indicators TEXT,
  escalate_to_caleb_if TEXT,
  notes TEXT
);

-- ── MESSAGE TEMPLATES ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS message_templates (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  -- opening_offer, follow_up_1, follow_up_2, counter_offer,
  -- soft_no, hard_no, pof_send, deal_dead, relationship_check,
  -- wholesale_blast, buyer_follow_up, under_contract_notify
  channel TEXT DEFAULT 'sms', -- 'sms', 'email', 'both'
  wholesaler_grade TEXT DEFAULT 'any', -- 'A', 'B', 'C', 'any'
  deal_type TEXT DEFAULT 'any',
  template TEXT NOT NULL,
  variables TEXT[],
  tone TEXT, -- 'warm', 'direct', 'urgent', 'casual', 'professional'
  char_count_target INTEGER,
  do_not_include TEXT,
  notes TEXT,
  use_count INTEGER DEFAULT 0,
  success_rate DECIMAL,
  active BOOLEAN DEFAULT TRUE
);

-- ── ADAM TRUST SCORES ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS adam_trust_scores (
  id SERIAL PRIMARY KEY,
  action_type TEXT UNIQUE NOT NULL,
  description TEXT,
  category TEXT, -- 'outreach', 'negotiation', 'admin', 'wholesale', 'reporting'
  score INTEGER DEFAULT 0,
  threshold INTEGER DEFAULT 25,
  autonomous BOOLEAN DEFAULT FALSE,
  requires_caleb_approval BOOLEAN DEFAULT TRUE,
  last_failure_at TIMESTAMPTZ,
  last_success_at TIMESTAMPTZ,
  total_attempts INTEGER DEFAULT 0,
  total_successes INTEGER DEFAULT 0,
  total_failures INTEGER DEFAULT 0,
  total_edits INTEGER DEFAULT 0,
  notes TEXT
);

-- ── MARKET KNOWLEDGE BASE ────────────────────────────────────
CREATE TABLE IF NOT EXISTS market_knowledge (
  id SERIAL PRIMARY KEY,
  topic TEXT NOT NULL,
  category TEXT NOT NULL,
  -- legal, market_dynamics, construction, finance, negotiation,
  -- insurance, tax, title, lending, florida_specific, ccg_strategy
  subcategory TEXT,
  content TEXT NOT NULL,
  key_numbers TEXT,
  action_implications TEXT,
  source TEXT,
  confidence TEXT DEFAULT 'high', -- 'high', 'medium', 'low'
  applies_to_counties TEXT[],
  applies_to_deal_types TEXT[],
  tags TEXT[],
  last_verified DATE,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── ADAM LEARNINGS ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS adam_learnings (
  id SERIAL PRIMARY KEY,
  type TEXT NOT NULL,
  -- deal_outcome, caleb_rejection, caleb_edit, market_pattern,
  -- wholesaler_pattern, negotiation_outcome, buyer_pattern
  context TEXT,
  lesson TEXT NOT NULL,
  confidence TEXT DEFAULT 'medium',
  deal_id INTEGER REFERENCES deals(id),
  wholesaler_id INTEGER REFERENCES wholesalers(id),
  buyer_id INTEGER REFERENCES cash_buyers(id),
  applies_to TEXT[],
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── TITLE COMPANIES ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS title_companies (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  contact_name TEXT,
  phone TEXT,
  email TEXT,
  address TEXT,
  counties TEXT[],
  investor_friendly BOOLEAN DEFAULT TRUE,
  avg_close_days INTEGER DEFAULT 21,
  simultaneous_close_capable BOOLEAN DEFAULT TRUE,
  assignment_friendly BOOLEAN DEFAULT TRUE,
  fee_notes TEXT,
  relationship_status TEXT,
  ccg_deals_closed INTEGER DEFAULT 0,
  notes TEXT
);

-- ── HARD MONEY LENDERS ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS hard_money_lenders (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  contact_name TEXT,
  phone TEXT,
  email TEXT,
  website TEXT,
  -- Terms
  interest_rate_pct DECIMAL,
  interest_rate_type TEXT DEFAULT 'fixed',
  origination_points DECIMAL,
  max_ltv_purchase DECIMAL,
  max_ltv_arv DECIMAL,
  max_loan_amount INTEGER,
  min_loan_amount INTEGER,
  term_months INTEGER DEFAULT 12,
  extension_available BOOLEAN DEFAULT TRUE,
  extension_fee TEXT,
  -- Draw process
  draws_available INTEGER,
  draw_inspection_required BOOLEAN DEFAULT TRUE,
  draw_turnaround_days INTEGER DEFAULT 3,
  -- Requirements
  min_credit_score INTEGER,
  experience_required BOOLEAN DEFAULT FALSE,
  entity_required BOOLEAN DEFAULT TRUE,
  personal_guarantee BOOLEAN DEFAULT TRUE,
  -- Relationship
  relationship_status TEXT DEFAULT 'unknown',
  ccg_deals_funded INTEGER DEFAULT 0,
  notes TEXT
);

-- ── INSURANCE DATA ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS insurance_data (
  id SERIAL PRIMARY KEY,
  county TEXT NOT NULL,
  property_type TEXT DEFAULT 'SFR',
  construction_type TEXT, -- 'frame', 'concrete_block', 'mixed'
  -- Costs
  avg_annual_premium INTEGER,
  avg_premium_per_1000_dwelling DECIMAL,
  min_annual_premium INTEGER,
  max_annual_premium INTEGER,
  -- Adjustments
  wind_mitigation_discount_pct DECIMAL DEFAULT 20,
  new_roof_discount_pct DECIMAL DEFAULT 15,
  four_point_required_year_built INTEGER DEFAULT 1992,
  -- Market conditions
  market_notes TEXT,
  preferred_carriers TEXT[],
  carriers_to_avoid TEXT[],
  -- Caleb notes
  notes TEXT,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── PROPERTY TAX DATA ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS property_tax_data (
  id SERIAL PRIMARY KEY,
  county TEXT NOT NULL,
  -- Rates
  millage_rate_per_1000 DECIMAL,
  effective_rate_pct DECIMAL,
  -- Assessment
  assessment_ratio DECIMAL DEFAULT 100,
  homestead_exemption_amount INTEGER DEFAULT 50000,
  soh_cap_pct DECIMAL DEFAULT 3, -- Save Our Homes cap
  -- Investor notes (no homestead)
  investor_no_homestead_notes TEXT,
  investor_effective_rate_pct DECIMAL,
  -- Estimate formula
  estimate_formula TEXT,
  -- Links
  assessor_website TEXT,
  notes TEXT,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── CCG ENTITY STRUCTURE ─────────────────────────────────────
CREATE TABLE IF NOT EXISTS ccg_entities (
  id SERIAL PRIMARY KEY,
  entity_name TEXT NOT NULL,
  entity_type TEXT, -- 'trust', 'llc', 'corporation'
  primary_use TEXT,
  counties TEXT[],
  deal_types TEXT[],
  signing_authority TEXT,
  notes TEXT
);

-- ── CONTRACT TEMPLATES ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS contract_templates (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  type TEXT, -- 'psa', 'assignment', 'novation', 'loi'
  state TEXT DEFAULT 'FL',
  template_path TEXT,
  variables TEXT[], -- list of merge fields
  notes TEXT,
  active BOOLEAN DEFAULT TRUE
);

-- ── DEAL ANALYTICS ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS deal_analytics (
  id SERIAL PRIMARY KEY,
  period_start DATE,
  period_end DATE,
  -- Volume
  deals_scored INTEGER DEFAULT 0,
  deals_hot_buy INTEGER DEFAULT 0,
  offers_sent INTEGER DEFAULT 0,
  deals_accepted INTEGER DEFAULT 0,
  deals_closed INTEGER DEFAULT 0,
  deals_dead INTEGER DEFAULT 0,
  deals_wholesaled INTEGER DEFAULT 0,
  -- Conversion rates
  score_to_offer_rate DECIMAL,
  offer_to_contract_rate DECIMAL,
  contract_to_close_rate DECIMAL,
  -- Time metrics
  avg_time_score_to_offer_hours DECIMAL,
  avg_time_offer_to_response_hours DECIMAL,
  avg_time_offer_to_contract_days DECIMAL,
  avg_time_contract_to_close_days DECIMAL,
  -- Financial
  total_profit_closed INTEGER DEFAULT 0,
  avg_profit_per_deal INTEGER,
  total_assignment_fees INTEGER DEFAULT 0,
  -- By source
  best_wholesaler_id INTEGER REFERENCES wholesalers(id),
  top_performing_zip TEXT,
  -- Notes
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── INDEXES ──────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_deals_status ON deals(status);
CREATE INDEX IF NOT EXISTS idx_deals_county ON deals(county);
CREATE INDEX IF NOT EXISTS idx_deals_wholesaler ON deals(wholesaler_id);
CREATE INDEX IF NOT EXISTS idx_conversations_deal ON conversations(deal_id);
CREATE INDEX IF NOT EXISTS idx_wholesalers_grade ON wholesalers(grade);
CREATE INDEX IF NOT EXISTS idx_market_areas_county ON market_areas(county);
CREATE INDEX IF NOT EXISTS idx_market_areas_zip ON market_areas(zip_code);
CREATE INDEX IF NOT EXISTS idx_knowledge_category ON market_knowledge(category);
CREATE INDEX IF NOT EXISTS idx_buyers_counties ON cash_buyers USING GIN(buys_counties);
