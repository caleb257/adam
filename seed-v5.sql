-- ============================================================
-- ADAM BRAIN SEED V5 — GENIUS LAYER
-- School ratings, HOA data, subdivision intelligence, DSCR
-- programs, 30 more deal examples, epistemic rules,
-- performance targets, permit timing, dead deal patterns
-- ============================================================
BEGIN;

-- ── SCHEMA ADDITIONS ─────────────────────────────────────────
ALTER TABLE market_areas
  ADD COLUMN IF NOT EXISTS school_rating_overall SMALLINT,
  ADD COLUMN IF NOT EXISTS school_rating_elementary SMALLINT,
  ADD COLUMN IF NOT EXISTS school_rating_middle SMALLINT,
  ADD COLUMN IF NOT EXISTS school_rating_high SMALLINT,
  ADD COLUMN IF NOT EXISTS top_schools TEXT[],
  ADD COLUMN IF NOT EXISTS hoa_prevalence_pct SMALLINT,
  ADD COLUMN IF NOT EXISTS cdd_common BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS new_construction_units_yr SMALLINT,
  ADD COLUMN IF NOT EXISTS permit_pull_weeks_avg SMALLINT,
  ADD COLUMN IF NOT EXISTS retail_buyer_profile TEXT,
  ADD COLUMN IF NOT EXISTS primary_employers TEXT[],
  ADD COLUMN IF NOT EXISTS commute_to_tampa_min SMALLINT,
  ADD COLUMN IF NOT EXISTS investor_saturation TEXT;

CREATE TABLE IF NOT EXISTS subdivision_intelligence (
  id SERIAL PRIMARY KEY,
  county TEXT NOT NULL,
  city TEXT NOT NULL,
  zip TEXT NOT NULL,
  subdivision_name TEXT NOT NULL,
  property_type TEXT DEFAULT 'SFR',
  year_built_range TEXT,
  construction TEXT,
  hoa_monthly INTEGER,
  hoa_rental_allowed BOOLEAN,
  cdd_annual INTEGER,
  avg_sqft INTEGER,
  lot_size_avg TEXT,
  school_rating SMALLINT,
  median_sale_price INTEGER,
  avg_days_on_market SMALLINT,
  investor_buy_pct SMALLINT,
  flood_zone TEXT DEFAULT 'X',
  ccg_interest TEXT,
  notes TEXT
);

CREATE TABLE IF NOT EXISTS permit_timing (
  id SERIAL PRIMARY KEY,
  county TEXT NOT NULL,
  permit_type TEXT NOT NULL,
  avg_business_days INTEGER,
  expedite_available BOOLEAN DEFAULT FALSE,
  expedite_cost TEXT,
  online_portal TEXT,
  tips TEXT,
  notes TEXT
);

CREATE TABLE IF NOT EXISTS dscr_programs (
  id SERIAL PRIMARY KEY,
  lender_name TEXT NOT NULL,
  program_name TEXT,
  loan_type TEXT DEFAULT 'DSCR',
  min_dscr NUMERIC DEFAULT 1.0,
  max_ltv NUMERIC DEFAULT 75,
  rate_range_low NUMERIC,
  rate_range_high NUMERIC,
  origination_points_low NUMERIC,
  origination_points_high NUMERIC,
  min_credit_score INTEGER,
  min_loan_amount INTEGER,
  max_loan_amount INTEGER,
  entity_required BOOLEAN DEFAULT TRUE,
  seasoning_months SMALLINT DEFAULT 6,
  fl_active BOOLEAN DEFAULT TRUE,
  close_time_days SMALLINT,
  prepay_penalty TEXT,
  portfolio_cap INTEGER,
  strengths TEXT[],
  weaknesses TEXT[],
  notes TEXT,
  verified_date DATE DEFAULT CURRENT_DATE
);

CREATE TABLE IF NOT EXISTS performance_targets (
  id SERIAL PRIMARY KEY,
  metric_name TEXT NOT NULL,
  category TEXT NOT NULL,
  target_value NUMERIC,
  target_unit TEXT,
  measurement_period TEXT,
  current_baseline NUMERIC,
  strong_threshold NUMERIC,
  weak_threshold NUMERIC,
  how_to_measure TEXT,
  adam_role TEXT,
  notes TEXT
);

CREATE TABLE IF NOT EXISTS dead_deal_patterns (
  id SERIAL PRIMARY KEY,
  pattern_name TEXT NOT NULL,
  frequency TEXT,
  early_warning_signs TEXT[],
  at_what_stage TEXT,
  prevention_action TEXT,
  recovery_action TEXT,
  example_scenario TEXT,
  deal_types TEXT[],
  counties_most_common TEXT[],
  financial_impact TEXT,
  notes TEXT
);

-- ── UPDATE MARKET AREAS WITH SCHOOL RATINGS AND HOA DATA ─────
-- Pasco County key zips
UPDATE market_areas SET
  school_rating_overall=6, school_rating_elementary=6,
  school_rating_middle=6, school_rating_high=5,
  top_schools=ARRAY['Paul R Smith Middle (7)','Zephyrhills High (5)','Woodland Elementary (7)'],
  hoa_prevalence_pct=25, cdd_common=FALSE,
  new_construction_units_yr=180, permit_pull_weeks_avg=4,
  retail_buyer_profile='First-time buyers, Tampa commuters, retirees from Hillsborough overflow',
  primary_employers=ARRAY['Pasco County Schools','Amazon Distribution (nearby)','Healthcare/medical offices','Retail'],
  commute_to_tampa_min=45,
  investor_saturation='medium',
  investor_buyer_pct=35, retail_buyer_pct=65,
  months_of_inventory=2.1, list_to_sale_ratio=0.97
WHERE zip_code='33525';

UPDATE market_areas SET
  school_rating_overall=9, school_rating_elementary=8,
  school_rating_middle=8, school_rating_high=9,
  top_schools=ARRAY['Wiregrass Ranch HS (9)','Cypress Creek Middle (8)','Quail Hollow Elementary (9)'],
  hoa_prevalence_pct=78, cdd_common=TRUE,
  new_construction_units_yr=1200, permit_pull_weeks_avg=5,
  retail_buyer_profile='Families relocating from Northeast/Midwest, corporate relocations, tech workers',
  primary_employers=ARRAY['AdventHealth (hospital)','Remote workers','Financial services','Tech'],
  commute_to_tampa_min=35,
  investor_saturation='high',
  investor_buyer_pct=25, retail_buyer_pct=75,
  months_of_inventory=1.8, list_to_sale_ratio=0.98
WHERE zip_code='33544';

UPDATE market_areas SET
  school_rating_overall=8, school_rating_elementary=7,
  school_rating_middle=7, school_rating_high=8,
  top_schools=ARRAY['Wesley Chapel HS (8)','Thomas Weightman Middle (7)'],
  hoa_prevalence_pct=65, cdd_common=TRUE,
  new_construction_units_yr=600, permit_pull_weeks_avg=5,
  retail_buyer_profile='Families, commuters, move-up buyers from Brandon/Riverview',
  primary_employers=ARRAY['Healthcare','Retail/Commercial','Remote work'],
  commute_to_tampa_min=38,
  investor_saturation='medium',
  investor_buyer_pct=28, retail_buyer_pct=72,
  months_of_inventory=1.9, list_to_sale_ratio=0.97
WHERE zip_code='33545';

UPDATE market_areas SET
  school_rating_overall=9, school_rating_elementary=8,
  school_rating_middle=9, school_rating_high=9,
  top_schools=ARRAY['J.W. Mitchell HS (9)','Seven Springs Middle (9)','Trinity Oaks Elementary (9)'],
  hoa_prevalence_pct=82, cdd_common=TRUE,
  new_construction_units_yr=300, permit_pull_weeks_avg=4,
  retail_buyer_profile='Premium buyers, corporate relocations, move-up from Wesley Chapel',
  primary_employers=ARRAY['Healthcare','Remote work','Financial services','Legal'],
  commute_to_tampa_min=30,
  investor_saturation='low',
  investor_buyer_pct=18, retail_buyer_pct=82,
  months_of_inventory=1.5, list_to_sale_ratio=0.99
WHERE zip_code='34655';

UPDATE market_areas SET
  school_rating_overall=8, school_rating_elementary=8,
  school_rating_middle=8, school_rating_high=9,
  top_schools=ARRAY['Sunlake HS (9)','Charles S Rushe Middle (8)','Oakstead Elementary (8)'],
  hoa_prevalence_pct=68, cdd_common=TRUE,
  new_construction_units_yr=800, permit_pull_weeks_avg=5,
  retail_buyer_profile='Families, Tampa North commuters, move-up buyers',
  primary_employers=ARRAY['Healthcare','Remote work','Retail','USF research corridor'],
  commute_to_tampa_min=32,
  investor_saturation='medium',
  investor_buyer_pct=24, retail_buyer_pct=76,
  months_of_inventory=1.7, list_to_sale_ratio=0.98
WHERE zip_code='34637';

UPDATE market_areas SET
  school_rating_overall=5, school_rating_elementary=5,
  school_rating_middle=5, school_rating_high=5,
  top_schools=ARRAY['Gulf HS (5)','River Ridge Middle (6)'],
  hoa_prevalence_pct=20, cdd_common=FALSE,
  new_construction_units_yr=60, permit_pull_weeks_avg=3,
  retail_buyer_profile='First-time buyers, retirees, blue-collar workers, coastal lifestyle seekers',
  primary_employers=ARRAY['Tourism/coastal','Healthcare','Retail','Trades'],
  commute_to_tampa_min=50,
  investor_saturation='medium',
  investor_buyer_pct=38, retail_buyer_pct=62,
  months_of_inventory=2.5, list_to_sale_ratio=0.96
WHERE zip_code='34652';

UPDATE market_areas SET
  school_rating_overall=5, school_rating_elementary=5,
  school_rating_middle=4, school_rating_high=5,
  top_schools=ARRAY['Fivay HS (5)','River Ridge Middle (6)'],
  hoa_prevalence_pct=15, cdd_common=FALSE,
  new_construction_units_yr=40, permit_pull_weeks_avg=3,
  retail_buyer_profile='Retirees, coastal lifestyle, budget buyers',
  primary_employers=ARRAY['Healthcare','Retail','Fishing/tourism'],
  commute_to_tampa_min=55,
  investor_saturation='low',
  investor_buyer_pct=40, retail_buyer_pct=60,
  months_of_inventory=3.0, list_to_sale_ratio=0.95
WHERE zip_code='34667';

UPDATE market_areas SET
  school_rating_overall=7, school_rating_elementary=7,
  school_rating_middle=7, school_rating_high=7,
  top_schools=ARRAY['Pasco HS (7)','Pasco Middle (7)'],
  hoa_prevalence_pct=22, cdd_common=FALSE,
  new_construction_units_yr=120, permit_pull_weeks_avg=4,
  retail_buyer_profile='Rural lifestyle seekers, farmers, Tampa commuters wanting land',
  primary_employers=ARRAY['Agriculture','Healthcare','Manufacturing','Pasco County govt'],
  commute_to_tampa_min=48,
  investor_saturation='low',
  investor_buyer_pct=32, retail_buyer_pct=68,
  months_of_inventory=2.2, list_to_sale_ratio=0.97
WHERE zip_code='33576';

-- Hillsborough key zips
UPDATE market_areas SET
  school_rating_overall=6, school_rating_elementary=6,
  school_rating_middle=6, school_rating_high=7,
  top_schools=ARRAY['East Bay HS (7)','Eisenhower Middle (6)','Ruskin Elementary (7)'],
  hoa_prevalence_pct=30, cdd_common=FALSE,
  new_construction_units_yr=250, permit_pull_weeks_avg=3,
  retail_buyer_profile='Blue-collar workers, Port of Tampa employees, first-time buyers, Manatee County overflow',
  primary_employers=ARRAY['Port of Tampa','Agriculture/distribution','Amazon','Healthcare'],
  commute_to_tampa_min=30,
  investor_saturation='medium',
  investor_buyer_pct=32, retail_buyer_pct=68,
  months_of_inventory=1.9, list_to_sale_ratio=0.97
WHERE zip_code='33570';

UPDATE market_areas SET
  school_rating_overall=8, school_rating_elementary=7,
  school_rating_middle=8, school_rating_high=8,
  top_schools=ARRAY['Riverview HS (8)','Rodgers Middle (8)','Sessums Elementary (8)'],
  hoa_prevalence_pct=55, cdd_common=TRUE,
  new_construction_units_yr=500, permit_pull_weeks_avg=3,
  retail_buyer_profile='Families, military (MacDill), healthcare workers, tech workers',
  primary_employers=ARRAY['MacDill AFB','Healthcare (USF Health, BayCare)','Amazon','Financial services'],
  commute_to_tampa_min=25,
  investor_saturation='high',
  investor_buyer_pct=26, retail_buyer_pct=74,
  months_of_inventory=1.7, list_to_sale_ratio=0.98
WHERE zip_code='33569';

UPDATE market_areas SET
  school_rating_overall=8, school_rating_elementary=8,
  school_rating_middle=8, school_rating_high=8,
  top_schools=ARRAY['Riverview HS (8)','McLane Middle (8)','Alafia Elementary (8)'],
  hoa_prevalence_pct=60, cdd_common=TRUE,
  new_construction_units_yr=400, permit_pull_weeks_avg=3,
  retail_buyer_profile='Young families, MacDill military, healthcare',
  primary_employers=ARRAY['MacDill AFB','Healthcare','Amazon Riverview','Distribution/logistics'],
  commute_to_tampa_min=22,
  investor_saturation='high',
  investor_buyer_pct=27, retail_buyer_pct=73,
  months_of_inventory=1.8, list_to_sale_ratio=0.97
WHERE zip_code='33578';

UPDATE market_areas SET
  school_rating_overall=6, school_rating_elementary=6,
  school_rating_middle=5, school_rating_high=6,
  top_schools=ARRAY['Brandon HS (6)','Burns Middle (5)'],
  hoa_prevalence_pct=35, cdd_common=FALSE,
  new_construction_units_yr=150, permit_pull_weeks_avg=3,
  retail_buyer_profile='Established families, first-time buyers upgrading, Tampa East commuters',
  primary_employers=ARRAY['Brandon Regional Hospital','Retail/Westfield Brandon','Healthcare','Financial services'],
  commute_to_tampa_min=28,
  investor_saturation='medium',
  investor_buyer_pct=30, retail_buyer_pct=70,
  months_of_inventory=1.8, list_to_sale_ratio=0.97
WHERE zip_code='33510';

UPDATE market_areas SET
  school_rating_overall=8, school_rating_elementary=8,
  school_rating_middle=7, school_rating_high=8,
  top_schools=ARRAY['Bloomingdale HS (8)','Burns Middle (7 - boundary)','Lamb Elementary (8)'],
  hoa_prevalence_pct=42, cdd_common=FALSE,
  new_construction_units_yr=180, permit_pull_weeks_avg=3,
  retail_buyer_profile='Move-up buyers, established families, tech workers commuting to Tampa',
  primary_employers=ARRAY['Healthcare','Financial services','Remote workers','Brandon hub employers'],
  commute_to_tampa_min=30,
  investor_saturation='medium',
  investor_buyer_pct=28, retail_buyer_pct=72,
  months_of_inventory=1.7, list_to_sale_ratio=0.98
WHERE zip_code='33511';

UPDATE market_areas SET
  school_rating_overall=8, school_rating_elementary=8,
  school_rating_middle=8, school_rating_high=8,
  top_schools=ARRAY['Bloomingdale HS (8)','Turkey Creek Middle (8)','Brooker Elementary (8)'],
  hoa_prevalence_pct=48, cdd_common=FALSE,
  new_construction_units_yr=200, permit_pull_weeks_avg=3,
  retail_buyer_profile='Families, move-up buyers, remote workers, Tampa East corridor professionals',
  primary_employers=ARRAY['Healthcare','Remote work','Financial services','Brandon/Riverview hub'],
  commute_to_tampa_min=32,
  investor_saturation='medium',
  investor_buyer_pct=25, retail_buyer_pct=75,
  months_of_inventory=1.6, list_to_sale_ratio=0.98
WHERE zip_code='33594';

UPDATE market_areas SET
  school_rating_overall=9, school_rating_elementary=9,
  school_rating_middle=9, school_rating_high=9,
  top_schools=ARRAY['Newsome HS (10)','Randall Middle (9)','Fishhawk Creek Elementary (10)'],
  hoa_prevalence_pct=88, cdd_common=TRUE,
  new_construction_units_yr=400, permit_pull_weeks_avg=3,
  retail_buyer_profile='Premium buyers, top-school seekers, high-income families',
  primary_employers=ARRAY['Remote high earners','Healthcare specialists','Legal/financial professionals'],
  commute_to_tampa_min=35,
  investor_saturation='very_low',
  investor_buyer_pct=18, retail_buyer_pct=82,
  months_of_inventory=1.4, list_to_sale_ratio=0.99
WHERE zip_code='33547';

-- Hernando County key zips
UPDATE market_areas SET
  school_rating_overall=5, school_rating_elementary=5,
  school_rating_middle=5, school_rating_high=6,
  top_schools=ARRAY['Central HS (6)','Fox Chapel Middle (5)','Pine Grove Elementary (6)'],
  hoa_prevalence_pct=18, cdd_common=FALSE,
  new_construction_units_yr=80, permit_pull_weeks_avg=3,
  retail_buyer_profile='Retirees, blue-collar workers, Tampa remote commuters, budget first-time buyers',
  primary_employers=ARRAY['HCA Florida Oak Hill Hospital','Hernando County Schools','Healthcare/medical','Retail'],
  commute_to_tampa_min=55,
  investor_saturation='low',
  investor_buyer_pct=36, retail_buyer_pct=64,
  months_of_inventory=2.4, list_to_sale_ratio=0.96
WHERE zip_code='34606';

UPDATE market_areas SET
  school_rating_overall=6, school_rating_elementary=6,
  school_rating_middle=6, school_rating_high=7,
  top_schools=ARRAY['Nature Coast Technical HS (7)','Explorer K-8 (7)'],
  hoa_prevalence_pct=15, cdd_common=FALSE,
  new_construction_units_yr=120, permit_pull_weeks_avg=3,
  retail_buyer_profile='Retirees, young families priced out of Pasco, remote workers',
  primary_employers=ARRAY['Healthcare','Retail','Remote workers','Hernando County govt'],
  commute_to_tampa_min=52,
  investor_saturation='low',
  investor_buyer_pct=33, retail_buyer_pct=67,
  months_of_inventory=2.1, list_to_sale_ratio=0.97
WHERE zip_code='34608';

UPDATE market_areas SET
  school_rating_overall=6, school_rating_elementary=6,
  school_rating_middle=6, school_rating_high=7,
  top_schools=ARRAY['Nature Coast Technical HS (7)','Parrott Middle (6)'],
  hoa_prevalence_pct=20, cdd_common=FALSE,
  new_construction_units_yr=150, permit_pull_weeks_avg=3,
  retail_buyer_profile='Growing suburban buyers, Pasco overflow, remote workers',
  primary_employers=ARRAY['Healthcare','Distribution','Remote workers','Retail'],
  commute_to_tampa_min=50,
  investor_saturation='low',
  investor_buyer_pct=32, retail_buyer_pct=68,
  months_of_inventory=2.0, list_to_sale_ratio=0.97
WHERE zip_code='34609';


-- ── SUBDIVISION INTELLIGENCE ──────────────────────────────────
INSERT INTO subdivision_intelligence (county,city,zip,subdivision_name,construction,year_built_range,hoa_monthly,hoa_rental_allowed,cdd_annual,avg_sqft,school_rating,median_sale_price,avg_days_on_market,investor_buy_pct,flood_zone,ccg_interest,notes) VALUES
('Pasco','Wesley Chapel','33544','Meadow Pointe','concrete_block','1992-2003',85,TRUE,1800,1580,9,368000,17,22,'X','FLIP','Excellent schools. 3/2 CBS 1998-2003. Strong retail exit. HOA allows rentals. CDD is high-ish but buyers accept it. Great flip territory.'),
('Pasco','Wesley Chapel','33544','Wiregrass Ranch Area (New)','concrete_block','2008-2020',165,FALSE,3200,2100,9,425000,15,15,'X','AVOID_RENTAL','Too new for CCG criteria. HOA rental restriction. Premium flip territory only if deal is exceptional.'),
('Pasco','Wesley Chapel','33545','Cypress Creek','concrete_block','1994-2005',95,TRUE,1500,1720,8,352000,19,24,'X','FLIP','Good CBS stock from mid-90s to early 2000s. Solid school zone. HOA allows rentals. Good flip exit.'),
('Pasco','Land O Lakes','34637','Sunlake/Bexley Area','concrete_block','2015-2023',175,FALSE,3500,2300,9,415000,14,18,'X','AVOID','New construction. HOA rental restriction. Not CCG target criteria (too new).'),
('Pasco','Land O Lakes','34638','Connerton','concrete_block','2005-2018',135,FALSE,2800,1900,8,385000,16,20,'X','FLIP_ONLY','CDD community. No rental allowed per HOA. Strong flip exit if deal found at discount.'),
('Pasco','Zephyrhills','33525','Betmar Acres','frame','1960-1980',45,TRUE,NULL,1050,5,185000,28,48,'X','WHOLESALE_ONLY','55+ mobile/manufactured area. Frame, older. Not CCG criteria. Wholesale only if extreme discount.'),
('Pasco','Zephyrhills','33525','Zephyr Lakes/Cherokee Trails','concrete_block','1985-1998',65,TRUE,NULL,1420,6,258000,22,30,'X','PRIMARY_TARGET','Classic CCG target. CBS 1985-1998, reasonable HOA, allows rentals. Good BRRRR and flip. Zephyrhills sweet spot.'),
('Pasco','Trinity','34655','Heritage Springs (55+)','concrete_block','1999-2008',280,FALSE,NULL,1650,8,368000,18,20,'X','FLIP_55PLUS','Active adult (55+) gated community. Different buyer pool. High HOA. Good flip exit to active adult buyers. No rental allowed.'),
('Pasco','Trinity','34655','Fox Wood/Champions Club','concrete_block','1998-2008',125,TRUE,NULL,1880,9,405000,15,18,'X','FLIP','Premium Trinity. Top school zone. Rentals allowed. Strong retail exit. High entry price limits BRRRR math.'),
('Hillsborough','Riverview','33569','Boyette Farms','concrete_block','1993-2004',75,TRUE,NULL,1640,8,345000,18,24,'X','PRIMARY_TARGET','CBS 1993-2004. Boyette area strong schools. Rentals allowed. Good retail exit. CCG regular territory.'),
('Hillsborough','Riverview','33579','Panther Trace','concrete_block','2001-2010',95,FALSE,2200,2050,9,372000,16,20,'X','FLIP_ONLY','Strong schools (Newsome HS boundary). CDD community. Rental restriction. Premium flip exit.'),
('Hillsborough','Riverview','33578','South Pointe','concrete_block','1990-2002',65,TRUE,NULL,1520,7,328000,20,28,'X','FLIP_BRRRR','Older Riverview CBS. HOA allows rentals. Good BRRRR candidate if entry price right. Solid flip exit.'),
('Hillsborough','Brandon','33511','Bloomingdale','concrete_block','1980-1998',55,TRUE,NULL,1780,8,338000,18,26,'X','PRIMARY_TARGET','Classic Brandon CBS. Bloomingdale HS zone (8). Rentals allowed. Good mix of flip and BRRRR. CCG primary target.'),
('Hillsborough','Brandon','33510','Brandon Lakes','concrete_block','1975-1992',45,TRUE,NULL,1450,6,308000,20,30,'X','FLIP_BRRRR','Older Brandon CBS. Lower school rating limits retail ARV vs 33511. Good BRRRR for rental. Solid buy-and-hold.'),
('Hillsborough','Valrico','33594','Buckhorn Preserve','concrete_block','1995-2008',85,TRUE,NULL,1720,8,345000,17,23,'X','FLIP_BRRRR','Valrico CBS mid-90s to mid-2000s. Bloomingdale HS zone. HOA allows rentals. Strong retail buyer profile.'),
('Hillsborough','Lithia','33547','FishHawk Ranch','concrete_block','2000-2015',165,FALSE,3200,2400,10,458000,14,16,'X','FLIP_PREMIUM','Best school zone in Hillsborough (Newsome HS 10). CDD. No rental. Premium flip territory only.'),
('Hillsborough','Ruskin','33570','Bahia Lakes','concrete_block','2003-2012',105,TRUE,NULL,1680,6,295000,20,28,'X','BRRRR_RENTAL','Good CBS in Ruskin. HOA allows rentals. Positive DSCR math works here. Strong rental demand. BRRRR candidate.'),
('Hillsborough','Apollo Beach','33572','MiraBay','concrete_block','2004-2015',185,FALSE,NULL,2800,7,498000,15,15,'medium','AVOID_RENTAL','Premium waterfront community. High HOA, rental restrictions, flood zone concerns near water. Flip only for exceptional deals.'),
('Hernando','Spring Hill','34608','Wellington at Seven Hills','concrete_block','1998-2008',95,TRUE,NULL,1820,7,272000,22,26,'X','BRRRR_RENTAL','Spring Hill CBS 1998-2008. One of better-quality Spring Hill areas. HOA allows rentals. Good BRRRR math. CCG target for rental portfolio.'),
('Hernando','Spring Hill','34608','Spring Hill (No HOA areas)','concrete_block','1985-1998',NULL,TRUE,NULL,1380,6,242000,23,35,'X','PRIMARY_BRRRR','No HOA CBS homes in Spring Hill are CCG primary BRRRR targets. Maximum flexibility. Light to medium rehab. Strong cash flow math.'),
('Hernando','Spring Hill','34606','Regency Park','concrete_block','1980-1995',55,TRUE,NULL,1250,5,228000,25,38,'X','BRRRR_BUDGET','Older Spring Hill CBS. Lower school zone but strong rental demand from healthcare workers. Best DSCR math in CCG territory.'),
('Hernando','Spring Hill','34609','Royal Highlands (55+)','concrete_block','1998-2010',220,FALSE,NULL,1450,7,268000,20,25,'X','FLIP_55PLUS','Active adult community. High HOA, no rental. Premium active adult buyers. Flip only if priced right.');

-- ── PERMIT TIMING BY COUNTY ───────────────────────────────────
INSERT INTO permit_timing (county,permit_type,avg_business_days,expedite_available,expedite_cost,online_portal,tips,notes) VALUES
('Hillsborough','Roofing permit',10,TRUE,'$150-300 add-on','permits.hillsboroughcounty.org','File electronically. Weekday submission by Tuesday helps. Roof permits are quick vs structural.','Hillsborough has good online system. E-permitting significantly faster than walk-in.'),
('Hillsborough','HVAC permit (replacement)',7,TRUE,'$100-200','permits.hillsboroughcounty.org','Submit mechanical permit online. HVAC replacement straightforward. Inspection often same week.','Hillsborough HVAC permits typically fastest county in CCG territory.'),
('Hillsborough','Electrical panel upgrade',8,FALSE,NULL,'permits.hillsboroughcounty.org','Panel upgrades require electrical contractor license. 7-10 business days typical.','Inspections book 3-5 days out after permit issued.'),
('Hillsborough','Kitchen/bath remodel (w/ plumbing)',15,FALSE,NULL,'permits.hillsboroughcounty.org','Any plumbing changes require permit. Submit early in project. Does not slow work if planned.','Hillsborough requires permit for moving plumbing. Check if project requires plan review.'),
('Hillsborough','Full renovation (plan review)',25,TRUE,'20% fee premium','permits.hillsboroughcounty.org','Plan review adds 2-3 weeks for major projects. Budget this into timeline.','Full gut with structural changes: 4-6 weeks. Simple renovation: 1-2 weeks.'),
('Pasco','Roofing permit',18,FALSE,NULL,'epermit.pascocountyfl.net','Pasco is understaffed. Roof permits taking 3-4 weeks in 2024-2025. Apply immediately upon contract.','CRITICAL: Apply for Pasco permits within 48 hours of closing. Do not wait. Permit delay is the #1 Pasco project killer.'),
('Pasco','HVAC permit (replacement)',14,FALSE,NULL,'epermit.pascocountyfl.net','HVAC in Pasco taking 2-3 weeks. Apply immediately. Work can continue on other items while waiting.','Pasco permit office is understaffed. Expect delays. Build 4 extra weeks into Pasco project timeline vs Hillsborough.'),
('Pasco','Electrical permit',15,FALSE,NULL,'epermit.pascocountyfl.net','Electrical permits similar to HVAC in Pasco. 2-4 weeks. Apply same day as other permits.','Submit all Pasco permits simultaneously to avoid sequential delays.'),
('Pasco','Full renovation',30,FALSE,NULL,'epermit.pascocountyfl.net','Full Pasco renovation: budget 6 weeks for permits before significant work. Apply on day 1 after closing.','Pasco timeline impact on profitability is significant. Budget 1 extra month holding cost vs Hillsborough.'),
('Hernando','Roofing permit',10,FALSE,NULL,'hernandocounty.us/build','Hernando permitting faster than Pasco. Good online system. Roof permits typically 1.5-2 weeks.','Hernando County Building Department: (352) 754-4050. Generally cooperative with investors.'),
('Hernando','HVAC permit',8,FALSE,NULL,'hernandocounty.us/build','Hernando HVAC permits among fastest in CCG territory. 1-2 weeks typical.','Spring Hill projects run faster permitting than Pasco. Build this advantage into timeline projections.'),
('Hernando','Electrical permit',10,FALSE,NULL,'hernandocounty.us/build','Electrical similar to HVAC timing in Hernando. 1.5-2 weeks.','Hernando County inspectors generally accessible and practical.'),
('Hernando','Full renovation',20,FALSE,NULL,'hernandocounty.us/build','Full renovation in Hernando: 3-4 weeks permits. Faster than Pasco by 2-3 weeks.','Hernando permitting is an underrated advantage vs Pasco. Factor into county selection for flip projects.'),
('Pinellas','Roofing permit',8,FALSE,NULL,'myclearwater.com or pccds.co.pinellas.fl.us','Pinellas generally efficient. Online system works well. 1.5 weeks typical for roof.','Each Pinellas city (Clearwater, St Pete, Largo) has different department. Verify jurisdiction.'),
('Pinellas','HVAC permit',6,FALSE,NULL,'Same as roofing','Pinellas HVAC fast. Online submission smoothly processed. 1 week typical.','Pinellas is the most permitting-efficient county in CCG territory for most permit types.'),
('Polk','Roofing permit',10,FALSE,NULL,'polkpa.org (permit search)','Polk County Building: (863) 534-6080. Standard 2-week timeline.','Polk permitting similar to Hillsborough in efficiency.');

-- ── DSCR LENDER PROGRAMS (CURRENT 2025) ──────────────────────
INSERT INTO dscr_programs (lender_name,program_name,loan_type,min_dscr,max_ltv,rate_range_low,rate_range_high,origination_points_low,origination_points_high,min_credit_score,min_loan_amount,max_loan_amount,entity_required,seasoning_months,fl_active,close_time_days,prepay_penalty,portfolio_cap,strengths,weaknesses,notes) VALUES
('Coralstone Lending (Internal)','CCG Internal DSCR','DSCR',1.0,75,6.75,8.50,1.0,2.0,680,75000,2000000,TRUE,6,TRUE,14,'3-2-1 or negotiable',NULL,ARRAY['Fastest close','Best terms for CCG deals','No third-party approval','Caleb controls terms','Can modify for exceptional BRRRR'],ARRAY['Limited capital (check capacity with Grant)','Cannot fund all deals simultaneously','Terms based on current RLOC cost'],
'ALWAYS check Coralstone Lending capacity with Grant first. Internal funding saves 0.5-1.5 points vs external. Best option when available.'),

('Kiavi (formerly LendingHome)','Kiavi DSCR 30-Year','DSCR',1.0,80,7.25,9.00,1.5,2.5,680,100000,3000000,TRUE,6,TRUE,21,'3-2-1 step-down (standard)',NULL,ARRAY['No income verification','Online platform fast','Strong FL presence','Allows 80% LTV on strong DSCR','Portfolio of up to 35 properties'],ARRAY['Rates higher than some','Online-only less personal','6 month seasoning strict'],
'kiavi.com. Strong platform for CCG BRRRR refi. 80% LTV possible on DSCR >= 1.20. Good for multiple property portfolio. Account rep assigned.'),

('Lima One Capital','Lima One DSCR','DSCR',1.0,80,7.00,8.75,1.5,2.5,660,75000,3000000,TRUE,6,TRUE,21,'5-4-3-2-1 step-down',NULL,ARRAY['Competitive rates','Strong rental loan product','Cross-product: bridge+DSCR seamlessly','Good portfolio options','Lower min credit than some'],ARRAY['Prepay penalty is longer (5 years)','Requires 6 months seasoning','Slightly slower than Kiavi'],
'limaone.com. Good for CCG BRRRR cycle: bridge loan for purchase/rehab → seasoning period → DSCR refi with same lender. Streamlined process. Often better rate than Kiavi.'),

('RCN Capital','RCN Long-Term Rental','DSCR',1.0,75,7.50,9.50,2.0,3.0,680,75000,2500000,TRUE,6,TRUE,25,'3-2-1 step-down',NULL,ARRAY['Strong underwriting relationship possible','Portfolio loans available','Blanket loan option for multiple properties'],ARRAY['Higher points than Lima One/Kiavi','Rates on higher end','Less tech-forward — more manual process'],
'rcncapital.com. Good backup lender. Portfolio/blanket loan for 5+ properties is a strength. Relationship-based underwriting.'),

('Visio Lending','Visio DSCR','DSCR',1.0,80,7.00,9.00,1.5,2.5,680,75000,2000000,TRUE,6,TRUE,20,'5-4-3-2-1 or waive for higher rate',NULL,ARRAY['DSCR-focused specialty lender','80% LTV on strong files','Strong FL presence','Good for portfolio growth'],ARRAY['Less brand recognition','Smaller company than Lima One'],
'visiolending.com. DSCR specialist. 80% LTV possible. Strong option when Lima One/Kiavi at capacity or rates less competitive.'),

('Griffin Funding','Griffin DSCR Florida','DSCR',1.0,75,7.25,9.00,1.5,2.5,680,100000,3000000,TRUE,6,TRUE,21,'3-2-1 step-down',NULL,ARRAY['Strong FL market knowledge','Competitive rates','Good service reviews in FL market'],ARRAY['Less national brand recognition','Portfolio limit may apply'],
'griffinfunding.com. Florida-strong lender. Good for CCG BRRRR portfolio. Competitive with Lima One.'),

('Civic Financial Services','Civic DSCR','DSCR',1.0,75,7.50,9.25,1.75,2.75,660,100000,3000000,TRUE,6,TRUE,21,'3-2-1 or waive',NULL,ARRAY['Lower minimum credit (660)','Good for newer investors','Strong investor program'],ARRAY['Not quite as competitive on rates as Lima One'],'civicfs.com. Good option when credit is in 660-680 range. Strong DSCR product.'),

('Park Place Finance','Park Place DSCR','DSCR',1.0,80,7.00,8.50,1.0,2.0,700,100000,5000000,TRUE,6,TRUE,18,'3-2-1 standard',NULL,ARRAY['Competitive rates','Fast close (18 days)','80% LTV on strong files','Experienced investors preferred'],ARRAY['Requires 700+ credit','Not ideal for first DSCR'],
'parkplacefinance.com. Good rates, fast close. 80% LTV on DSCR >= 1.25. Preferred lender for established CCG volume.'),

('CoreVest Finance','CoreVest Portfolio','Portfolio/DSCR',1.0,75,7.25,8.75,1.0,2.0,680,500000,50000000,TRUE,6,TRUE,30,'Negotiable at volume',20,ARRAY['Portfolio/blanket loan specialist','No property count limit','Institutional quality','Single loan for multiple properties'],ARRAY['Minimum $500K loan (portfolio focus)','Slower process','Not ideal for single properties'],
'corevestfinance.com. Best option when CCG portfolio reaches 5-10+ properties and wants to bundle into single efficient loan structure. Institutional product.');

-- ── PERFORMANCE TARGETS ───────────────────────────────────────
INSERT INTO performance_targets (metric_name,category,target_value,target_unit,measurement_period,current_baseline,strong_threshold,weak_threshold,how_to_measure,adam_role,notes) VALUES
('Deals Scored HOT/BUY','deal_flow',15,'/month','monthly',NULL,20,8,'Count Urban HOT/BUY verdicts from underwrites table per month','Monitor Urban DB. Report in weekly brief. Flag if below 8 — suggests Derek sheet volume issue or market slowdown.','Drives top of funnel. If HOT/BUY count drops: check Derek sheet for gaps, check market for slowdown.'),
('Offers Sent','outreach',8,'/month','monthly',NULL,12,4,'Count offers sent (conversations with opening_offer type sent) per month','Adam tracks every offer sent in conversations table. Report weekly.','4+ offers/month minimum to generate 1 contract. Below 4 = pipeline will go dry in 30-45 days.'),
('Offer to Under Contract Rate','conversion',20,'%','rolling 90 days',NULL,30,12,'Deals under contract / offers sent * 100','Adam tracks deal status changes. Calculate rolling rate. Report in weekly brief.','Below 12%: review offer prices (may be too low) or wholesaler relationship issues. Above 30%: potentially offering too high.'),
('Response Rate from Outreach','outreach',65,'%','rolling 30 days',NULL,80,40,'Wholesaler responses received / outreach messages sent * 100','Track in conversations table. Calculate per wholesaler and overall.','Low response rate by wholesaler = relationship maintenance needed or communication timing issue. Overall low rate = pipeline quality issue.'),
('Time Score to Offer (HOT deals)','speed',25,'minutes','per deal',NULL,15,60,'Timestamp difference: Urban verdict time vs offer_sent time in deals table','Adam self-monitors. Alert if any HOT deal exceeds 60 minutes during business hours.','CCG competitive advantage is speed. Above 60 min on HOT deal = losing deals to competitors. Target 15-30 min as standard.'),
('Wholesaler A-Grade Percentage','relationship',30,'%','rolling 6 months',NULL,40,20,'A-grade wholesalers / total active wholesalers * 100','Calculate from wholesalers table grade column on active wholesalers (submitted in last 90 days).','Grows over time as Adam builds relationships. Target: 40% A-grade by month 12. Indicates relationship quality improvement.'),
('Deal Pipeline Value','pipeline',500000,'$','real-time',NULL,750000,250000,'Sum of projected profits across all HOT/BUY deals currently in pipeline (INCOMING through NEGOTIATING)','Adam maintains real-time in deals table. Report in daily brief to Caleb.','Pipeline value below $250K = need aggressive outreach. Above $750K = good health. Caleb uses for capital planning.'),
('Monthly Closed Deals','closings',3,'deals/month','monthly',NULL,4,2,'Count deals that moved to CLOSED status per month (flip + BRRRR + rental)','Track in deals table status changes. Report monthly.','CCG target is 3-4/month. Below 2: investigate pipeline bottleneck. Where are deals dying? Is it at offer, contract, or close?'),
('Average Profit Per Flip','profitability',35000,'$','rolling 12 months',NULL,45000,25000,'Average actual_profit on FLIP deals in deals table where status=CLOSED','Calculate from deals table after Mark as Sold updates. Compare to Urban estimate.','Below $25K average is concerning — suggests overpaying or unexpected costs. Above $45K = either great deals or low volume (taking only the best).'),
('BRRRR Cash Left In Average','brrrr_efficiency',20,'%','rolling 12 months',NULL,10,30,'Average cash_left_in_pct across BRRRR deals','Track per deal. Calculate average.','Above 30% cash left in: need better deal sourcing or lower purchase prices. Under 10%: exceptional — near-perfect capital recycling.'),
('Caleb Approval Rate (probation)','trust',75,'%','rolling 30 days',NULL,90,60,'Caleb approvals without edits / total drafts presented * 100','Track in conversations table: caleb_approved=TRUE and caleb_edited=FALSE','Below 60% approval: Adam is drafting wrong messages. Review what Caleb is rejecting and why. Above 90%: approaching full autonomy on that action type.'),
('Wholesaler Response Speed (A-grade)','relationship',NULL,'hours',NULL,NULL,2,8,'Average hours between Adam outreach and A-grade wholesaler response','Track from conversations: sent_at vs received_at for A-grade wholesaler conversations.','Fast A-grade response = healthy relationships. Slow response = relationship has cooled. Flag individual wholesalers who slow response after previously fast.'),
('Dead Deal Classification Accuracy','learning',NULL,'%','quarterly',NULL,NULL,NULL,'Review dead deals: was Adam right to pursue? Were early warning signs present in hindsight?','Adam performs quarterly self-audit of dead deals. What patterns should have flagged these earlier?','Backward-looking quality metric. Improves Adam''s early warning capabilities over time.'),
('Lead Source ROI','sourcing',NULL,'$per deal','quarterly',NULL,NULL,NULL,'Closed deals by source / cost by source','Track source in deals table. Calculate quarterly.','Informs where to invest: Derek sheet, direct mail, probate network, eviction court. Optimize spend.'),
('Weekly Outreach Volume','outreach',25,'messages/week','weekly',NULL,35,15,'Total outreach messages sent across all channels per week','Track in conversations table.','Below 15: pipeline will dry up. Above 35: maintaining healthy top of funnel. Goal is quality + quantity.');


-- ── DEAD DEAL PATTERNS ────────────────────────────────────────
INSERT INTO dead_deal_patterns (pattern_name,frequency,early_warning_signs,at_what_stage,prevention_action,recovery_action,example_scenario,deal_types,counties_most_common,financial_impact,notes) VALUES
('ARV Inflation Kills Margin','very_common',ARRAY['Wholesaler ARV more than 12% above Urban ARV','No retail buyer comps in last 90 days','Wholesaler cannot explain their ARV source','Comp selection includes only pool homes or upgraded properties vs comparable standard'],'BEFORE OFFER','Run Urban ARV first. Never negotiate from wholesaler ARV. If Urban says REVIEW on numbers, walk fast.','If already under contract: re-run with independent comp analysis. Negotiate price reduction with specific data.','Wholesaler sends 3/2 CBS in Spring Hill asking $195K with ARV claim of $285K. Urban ARV is $238K based on actual 90-day comps. Wholesaler''s $285K was from 2022 data and cherry-picked pool homes.',ARRAY['flip','brrrr','wholesale'],ARRAY['Hernando','Pasco'],'$20,000-60,000 overestimated profit. Deal that appears profitable is actually a money loser.','This is the #1 deal killer. Urban AI exists specifically for this. Always Urban first.'),

('Title Issues Surface Late','common',ARRAY['Property has been through foreclosure in 2007-2012','Multiple previous owners in short time period','Seller is evasive about ownership history','Property has been vacant for extended period','Multiple liens noted on tax records'],'DURING DUE DILIGENCE','Pull title commitment within 48 hours of contract. Do not wait until week 3 of 4-week DD.','Contact title company immediately. Get list of all requirements. Assess if clearable in timeline. Negotiate extension if needed. Walk if not clearable.','"1122 Oak St" went under contract at $168K. Title pulled week 3 — discovered gap in chain of title from 2009 foreclosure. Title company could not clear in 30 days. Lost $2,500 EMD. Correct walk.',ARRAY['flip','brrrr','rental','wholesale'],ARRAY['Hillsborough','Pasco'],'$2,000-5,000 EMD loss. 4-6 weeks of time lost.','Title pulled early = more time to resolve. Title pulled late = deal dies or rushes badly. ALWAYS pull title in first week.'),

('Contractor Abandons Mid-Project','common',ARRAY['GC required unusually large upfront payment','GC has multiple active projects visible online','GC was slow to respond during estimate phase','No references provided or references did not answer calls','Crew size is 1-2 people for large scope'],'MID-REHAB','Vet contractors before closing. Get references. Do not pay more than 10% upfront. Draw schedule tied to milestones.','Immediately find replacement contractor. Document all work completed. Photograph everything. Withhold remaining funds until new contractor assesss.','GC contracted for $42K full kitchen+baths renovation. Took $14K upfront (30%), disappeared after demo phase. Found working another job. Took 3 weeks to find replacement. Cost: 3 weeks delay + $8K extra to new contractor.',ARRAY['flip','brrrr'],ARRAY['All'],'$5,000-20,000 in delays, overruns, and premium for rush replacement. Hold time extension costs $3,000-6,000/month.','Payment schedule protection is the prevention. Milestone-based payments are non-negotiable.'),

('Permit Delays Kill Timeline','very_common_in_pasco',ARRAY['Project is in Pasco County','Multiple permits being pulled simultaneously','Project started in summer (busy permit season)','Structural changes requiring plan review','New contractor unfamiliar with county process'],'EARLY REHAB','Apply for all Pasco permits within 48 hours of closing. Do not wait. Do non-permitted work first (demo, painting, etc) while waiting.','Prioritize permit work in schedule. Have backup work for crew while waiting. Contact building department to check status.','Wesley Chapel flip: applied for roof permit week 2 of ownership. Pasco took 5 weeks. Entire project delayed 3 weeks beyond plan.',ARRAY['flip','brrrr'],ARRAY['Pasco'],'$3,000-7,500 per month delay in holding costs. Timeline extends, profit shrinks.','Pasco permit timing is the single biggest factor in Wesley Chapel and Land O Lakes flip timelines. Budget 4-6 week buffer.'),

('Inspection Finds Foundation Issue','less_common',ARRAY['Doors sticking throughout home','Visible cracks in tile floor or walls','Uneven floor when walking','Soft spots under flooring','Home is pre-1975 CBS in Hillsborough/Hernando','Recent sinkhole activity in neighborhood'],'INSPECTION PERIOD','Walk the property carefully before offering. Look for sticking doors, cracks, uneven floors. Do not skip structural engineering if any concern.','Get structural engineer immediately. If engineer says active movement or sinkhole: walk unless price drops to cover full remediation plus risk premium.','$176K contracted CBS in Brandon. Inspection showed multiple symptoms of settlement. Structural engineer: active slab movement, likely sub-slab plumbing leak and possible void. Estimated repair: $35,000-$85,000. Walked. Lost $2,000 EMD.',ARRAY['flip','brrrr','rental'],ARRAY['Hillsborough','Hernando'],'$2,000 EMD loss vs $35,000-85,000 potential rehab overrun plus legal liability. Clear win to walk.','The EMD is always cheap insurance vs a catastrophic foundation issue. Walk confidently when structural concerns are real.'),

('Wholesaler Loses Control of Deal','common',ARRAY['Wholesaler cannot answer basic seller questions','Wholesaler says "I need to check with my seller" repeatedly','Photos look professionally shot but wholesaler claims to have taken them','Two different wholesalers send same property in same week','Assignment of contract is already assigned (not original purchase contract)'],'BEFORE OFFER / NEGOTIATION','Ask directly in first message: "Are you the original buyer under contract or assigning from another party?" Screen this early.','If daisy chain confirmed: get introduced to original buyer and cut out the middle. Or walk if pricing doesn''t work after all fees.','Property comes through Marcus at $185K. Adam asks who''s under contract — Marcus admits he got it from another wholesaler who charged $165K. Marcus wants $20K spread. At $185K deal doesn''t pencil. Contacted original wholesaler directly and contracted at $165K.',ARRAY['flip','brrrr','wholesale'],ARRAY['All'],'Variable. Can mean $10,000-25,000 unnecessary markup. Or deal doesn''t pencil at all.','Daisy chain detection saves significant money. Ask directly. Professional wholesalers will tell you. Evasive ones confirm the suspicion.'),

('Seller Backs Out After Contract','uncommon',ARRAY['Seller was clearly ambivalent or emotional about sale','Family members objecting','Property listed on MLS same time as wholesale agreement','Seller asked for unusual terms around closing date','Short close date but keep asking for extensions'],'AFTER CONTRACT SIGNED','Get signatures quickly after agreement. File the contract. Consider recording a memorandum of contract.','Review contract for breach remedies. Consult attorney. Seller breach entitles CCG to either force sale (specific performance) or recover damages beyond EMD return.','Spring Hill seller agreed to $148K via Marcus. Signed contract. Week later, son came to visit and convinced seller the house was worth $220K. Seller tried to cancel. Contract was clear. Escalated to attorney. Settled: seller sold at $148K as contracted.',ARRAY['flip','brrrr','wholesale'],ARRAY['Hernando','Pasco'],'$2,000-10,000 legal fees if contested. Time loss of 3-8 weeks.','File contract immediately. Record memorandum if high-value deal. Seller remorse is common. Contract is the protection.'),

('Insurance Unavailability Kills Deal','increasingly_common',ARRAY['Property is pre-1990 with original roof (18+ years old)','Frame construction in coastal county','Property in Zone AE or higher','Four-point inspection will likely fail multiple items','Property history includes prior insurance claim','Aluminum wiring discovered'],'BEFORE CLOSE','Get preliminary insurance quote before contract if possible. At minimum: in first week of DD. Cannot close with HML without insurance.','If insurance too expensive or unavailable: use as negotiating tool. Price drop request or walk. Cannot proceed without insurance on HML deal.','Hudson Pasco: 3/2 frame, 1984, original roof. Contracted at $148K. HML required insurance proof. Best available: $14,200/year from surplus lines (non-admitted). Deal economics completely destroyed. Walked.',ARRAY['flip','brrrr','rental'],ARRAY['Pinellas','Pasco coastal','Hillsborough coastal'],'Insurance unavailability can kill a deal completely that otherwise worked. Prevention is a 10-minute insurance quote call.','Insurance is now a pre-offer research item on any coastal or old-roof property.'),

('HOA Rental Restriction Discovered Late','common',ARRAY['HOA monthly fee is very high ($150+) suggesting active community','Property in subdivision built 2005-2015 (newer HOA trend toward rental restrictions)','Subdivision name includes "Preserve," "Reserve," "Estates," "Ranch"','Deal was intended as BRRRR or rental purchase'],'DURING DUE DILIGENCE','Ask about HOA rental restrictions before making BRRRR/rental offer. Call HOA management company directly in first 48 hours.','If rental restriction discovered: recalculate as flip only. If flip math doesn''t work: renegotiate price or walk.','Land O Lakes 34638: Contracted as BRRRR target at $228K. HOA rental restriction discovered in DD week 2. Cannot rent. Flip only exit. Flip projected profit: $18K (below $30K minimum). Walked with $2,500 EMD lost.',ARRAY['brrrr','rental'],ARRAY['Pasco (Wesley Chapel/Land O Lakes)','Hillsborough (Lithia/FishHawk)'],'$2,000-3,000 EMD loss. Time waste of 2-3 weeks.','HOA rental restriction is BRRRR deal killer. Check FIRST, before full DD investment.'),

('Market Value Drop During Rehab','rare_but_real',ARRAY['Rehab is extended beyond 6 months','Interest rates significantly increase during rehab','Multiple competing flips list in neighborhood during rehab','New construction coming online during hold period','Economic shock event (job loss, etc.)'],'DURING REHAB','Price conservatively. Do not count on ARV expanding. Model at current comparable sales, not appreciation projections.','Reduce list price aggressively. Consider rental conversion. Consider wholesale exit even at thin margin to recycle capital.','Brandon flip: Contracted Nov 2022 at strong ARV projections. Extended rehab to June 2023. Interest rates increased 1.5% during hold. ARV dropped $18K from entry assumptions. Sold at reduced margin ($14K vs $38K projected).',ARRAY['flip'],ARRAY['All'],'$5,000-25,000 profit reduction. In extreme cases: negative result.','Build conservatism into ARV at entry. Never model on appreciation assumptions. And get projects done fast.');

-- ── EPISTEMIC RULES — ADAM KNOWING WHAT HE DOESN'T KNOW ──────
INSERT INTO market_knowledge (topic,category,subcategory,content,key_numbers,action_implications,source,confidence,applies_to_deal_types,tags) VALUES

('When Adam Is Not Confident — Escalation Protocol','ccg_strategy','epistemic_rules','Adam explicitly flags low confidence situations rather than projecting false certainty. Situations requiring explicit uncertainty disclosure: 1) Fewer than 3 comp sales in target zip in last 90 days (thin comp pool). 2) Property type or size significantly outside normal range (2,500+ sqft, unique configurations). 3) Market has moved significantly since last comparable sale. 4) Wholesaler''s deal information is incomplete or inconsistent. 5) Deal involves an unusual structure or legal complexity. In these cases: Adam says "I am not confident on this — here''s what I know and what I don''t" and recommends Caleb review before commitment.',
NULL,'False confidence costs money. Saying "I don''t know" earns trust. Adam should be more willing to escalate uncertain situations than to guess.','CCG epistemic framework','high',NULL,ARRAY['epistemic','uncertainty','escalation','intelligence']),

('How to Handle Thin Comp Pools','market_dynamics','arv_methodology','When fewer than 3 comparable sales exist in a zip in the last 90 days: 1) Expand search radius (go to adjacent zips). 2) Expand time horizon (look at 180-day sales instead of 90). 3) Note that ARV confidence is LOW. 4) Use most conservative comp as basis (not average). 5) Add 5-10% additional uncertainty buffer to rehab contingency. 6) Explicitly tell Caleb: "ARV is based on thin data — 2 comps in 180 days, confidence is medium-low." 7) Recommend physical market assessment before committing.','Thin comp threshold: <3 sales in 90 days. Very thin: <3 in 180 days.','Better to be explicit about thin data than to present false precision. A $285K ARV from 5 strong comps is different from $285K ARV from 1 old comp.',NULL,'high',NULL,ARRAY['arv','comps','epistemic','methodology']),

('When Market Data May Be Stale','market_dynamics','data_quality','Adam''s knowledge has recency constraints. Situations where Adam should verify current data before relying on stored knowledge: 1) Any market_areas data older than 6 months (prices shift). 2) Insurance carrier availability (changing monthly in FL in 2024-2025). 3) Interest rates (check weekly). 4) HML lender terms (quarterly changes). 5) County permit timing (staffing changes affect this). 6) HOA financial status (may have changed). When uncertain about recency: search current data rather than cite stale knowledge.',
NULL,'Flag data recency when citing specific numbers. "Based on data from [period] — recommend verifying current conditions before committing."',NULL,'high',NULL,ARRAY['epistemic','data_quality','recency','intelligence']),

('How to Reason Through Novel Situations','ccg_strategy','epistemic_rules','When Adam encounters a situation not in his training data: 1) Identify the closest analogous situation in deal_examples or market_knowledge. 2) State the analogy explicitly: "This is similar to [scenario] with the following key differences." 3) Identify what additional information would resolve the uncertainty. 4) Present the decision to Caleb with the reasoning chain visible. 5) After outcome is known, create a new entry in adam_learnings. Novel situations are learning opportunities, not failures.',
NULL,'Novel situations = escalate + learn. Never guess your way through something genuinely new. The cost of one bad decision exceeds the cost of one escalation.',NULL,'high',NULL,ARRAY['epistemic','novel_situations','learning','intelligence']),

('Pattern Recognition vs Pattern Matching','ccg_strategy','epistemic_rules','Adam knows many patterns. But pattern matching (applying a known pattern to a new situation) is different from pattern recognition (identifying that a new situation resembles a known pattern). Adam should: 1) Identify which pattern a situation resembles. 2) List the ways this situation differs from the pattern. 3) Weight the differences. If differences are minor: apply pattern. If differences are significant: treat as partially novel. 4) When pattern match is strong (95%+): state it confidently. When match is partial: show reasoning.',
NULL,'The difference between a senior acquisitions person and a junior one is how they handle situations that are "kind of like" something they''ve seen before. Show the reasoning.',NULL,'high',NULL,ARRAY['epistemic','pattern_recognition','intelligence','reasoning']),

('Caleb''s Unstated Preferences — What Adam Has Learned','ccg_strategy','caleb_preferences','Beyond the stated criteria, Adam has observed these unstated Caleb preferences from deal decisions: 1) Caleb responds more quickly to deals in Pasco County than Hillsborough — Pasco seems to be his preferred hunting ground. 2) Deals above $250K purchase price get more scrutiny even when numbers work. 3) Spring Hill gets strong BRRRR consideration even without as much hesitation as other markets. 4) Caleb is more aggressive on BRRRR targets than flip targets — willing to accept thinner flip margin if BRRRR math is strong. 5) "Clean" deals (vacant, CBS, no weird history) get immediate enthusiasm. Complex deals get more hesitation even at better prices.',
NULL,'These observed preferences should inform how Adam frames deal briefs. Lead with what Caleb will like, then address concerns. Know that Pasco + vacant + CBS + BRRRR math = instant attention.',NULL,'medium',NULL,ARRAY['caleb_preferences','framing','communication','ccg_strategy']),

('The Compounding Intelligence Loop','ccg_strategy','learning_system','Adam''s intelligence compounds over time through: 1) Every Caleb approval → template stays in rotation. 2) Every Caleb rejection → template analyzed and updated. 3) Every closed deal → lesson added to adam_learnings. 4) Every dead deal → pattern added to dead_deal_patterns. 5) Every wholesaler interaction → profile updated. 6) Every Urban comp update → market_areas refreshed. 7) Every market shift → market_knowledge updated. Over 12 months: Adam will have personalized intelligence that no generic agent could have because it is trained on CCG''s specific deal history and Caleb''s specific decision patterns.',
NULL,'The database is not static. Every interaction is a training event. Adam should explicitly request learning moments: "What should I have done differently on that dead deal?"',NULL,'high',NULL,ARRAY['learning','compounding','intelligence','system']),

('What Adam Knows That Urban Doesn''t','ccg_strategy','urban_adam_differentiation','Urban AI scores deals. Adam understands people. Urban''s blind spots that Adam fills: 1) Wholesaler credibility (Urban sees the deal; Adam knows the wholesaler). 2) Relationship history (Urban has no memory of prior interactions). 3) Market timing and capital context (Urban scores deals in isolation; Adam knows CCG''s current deployment). 4) Seller motivation (Urban sees property specs; Adam knows who is selling and why). 5) Competition context (Urban doesn''t know who else is bidding). 6) Communication strategy (Urban cannot negotiate). Adam + Urban = complete acquisition intelligence.',
NULL,'Urban is the technical analysis layer. Adam is the human intelligence layer. Neither alone is sufficient. Together they are substantially better than any one tool or person alone.',NULL,'high',NULL,ARRAY['urban_ai','adam','differentiation','intelligence']),

('Caleb''s Non-Negotiable Rules','ccg_strategy','caleb_rules','These are rules Caleb has stated explicitly that Adam never violates, regardless of deal circumstances: 1) NEVER offer above MAO without explicit Caleb approval. 2) NEVER sign contracts on behalf of CCG — contracts go to Caleb for signature. 3) NEVER agree to due diligence waiver — always maintain inspection rights. 4) NEVER commit to a close date without confirming capital and title readiness. 5) NEVER promise a seller anything that CCG cannot deliver. 6) NEVER discuss CCG''s internal financials with Grant without Caleb''s direction. 7) Steve is not with CCG — never reference or include him in any process.',
NULL,'These rules are absolute. Not guidelines. Not suggestions. Any situation that seems to require violating one of these rules: STOP and escalate to Caleb immediately.',NULL,'high',NULL,ARRAY['caleb_rules','non_negotiable','compliance','ccg_strategy']);

COMMIT;
