-- ============================================================
-- ADAM BRAIN SEED V4 — REASONING LAYER + VENDOR ECOSYSTEM
-- Decision trees, deal examples, seller profiles, timing data
-- ============================================================
BEGIN;

-- ── NEW TABLES ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS decision_trees (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  trigger_condition TEXT NOT NULL,
  decision_logic TEXT NOT NULL,
  outcome_options JSONB NOT NULL,
  default_action TEXT,
  escalate_condition TEXT,
  confidence_threshold TEXT,
  notes TEXT
);

CREATE TABLE IF NOT EXISTS deal_examples (
  id SERIAL PRIMARY KEY,
  example_type TEXT NOT NULL,
  address TEXT,
  city TEXT,
  county TEXT,
  zip TEXT,
  beds INTEGER,
  baths NUMERIC,
  sqft INTEGER,
  year_built INTEGER,
  construction TEXT,
  asking_price INTEGER,
  urban_arv INTEGER,
  urban_rehab INTEGER,
  urban_score NUMERIC,
  urban_verdict TEXT,
  wholesaler_arv INTEGER,
  arv_inflation_pct NUMERIC,
  ccg_action TEXT,
  ccg_offer INTEGER,
  outcome TEXT,
  profit_actual INTEGER,
  lesson TEXT,
  red_flags TEXT[],
  green_flags TEXT[],
  notes TEXT
);

CREATE TABLE IF NOT EXISTS seller_profiles (
  id SERIAL PRIMARY KEY,
  profile_name TEXT NOT NULL,
  motivation_type TEXT NOT NULL,
  typical_situation TEXT,
  pain_points TEXT[],
  what_they_want TEXT[],
  what_they_fear TEXT[],
  opening_approach TEXT,
  questions_to_ask TEXT[],
  red_flags TEXT[],
  green_flags TEXT[],
  price_flexibility TEXT,
  timeline_typical TEXT,
  communication_style TEXT,
  closing_strategy TEXT,
  example_script TEXT,
  notes TEXT
);

CREATE TABLE IF NOT EXISTS vendor_ecosystem (
  id SERIAL PRIMARY KEY,
  vendor_type TEXT NOT NULL,
  county TEXT,
  company_name TEXT,
  contact_name TEXT,
  phone TEXT,
  email TEXT,
  website TEXT,
  investor_friendly BOOLEAN DEFAULT TRUE,
  specialties TEXT[],
  typical_cost TEXT,
  turnaround_time TEXT,
  notes TEXT,
  verified_date DATE
);

CREATE TABLE IF NOT EXISTS communication_timing (
  id SERIAL PRIMARY KEY,
  contact_type TEXT NOT NULL,
  action_type TEXT NOT NULL,
  best_days TEXT[],
  best_hours TEXT,
  worst_days TEXT[],
  worst_hours TEXT,
  avg_response_time TEXT,
  follow_up_cadence TEXT,
  channel_preference TEXT,
  notes TEXT
);

CREATE TABLE IF NOT EXISTS lead_source_performance (
  id SERIAL PRIMARY KEY,
  source_name TEXT NOT NULL,
  source_type TEXT NOT NULL,
  avg_response_rate_pct NUMERIC,
  avg_qualified_rate_pct NUMERIC,
  avg_close_rate_pct NUMERIC,
  avg_cost_per_lead NUMERIC,
  avg_cost_per_deal NUMERIC,
  avg_deal_quality TEXT,
  avg_seller_motivation TEXT,
  competition_level TEXT,
  setup_cost TEXT,
  monthly_cost TEXT,
  time_to_first_deal TEXT,
  ccg_priority INTEGER,
  notes TEXT
);

-- ── DECISION TREES — ADAM'S REASONING FRAMEWORK ───────────────
INSERT INTO decision_trees (name, category, trigger_condition, decision_logic, outcome_options, default_action, escalate_condition, confidence_threshold, notes) VALUES

('Deal Verdict → Next Action','deal_flow','New Urban verdict arrives for a deal',
'Check verdict tier first. HOT = immediate brief to Caleb. BUY = brief within 30 minutes. REVIEW = queue for daily digest. PASS/HARD NO = auto-archive, no Caleb notification unless wholesaler is A-grade.',
'{"HOT": "Immediate Telegram brief with full analysis. Generate opening offer. Show DRAFT button for Caleb approval.", "BUY": "Brief within 30 minutes. Same process as HOT.", "REVIEW": "Add to daily digest. Do not interrupt Caleb.", "PASS": "Archive. No notification.", "HARD NO": "Archive. Log reason to wholesaler profile."}'::JSONB,
'Queue for daily digest if no clear verdict tier','If verdict is HOT and score >= 9.5, ping Caleb with HIGH PRIORITY flag','Score >= 7.5 with HOT/BUY verdict','Immediate action decisions — no delay allowed on HOT/BUY in competitive market'),

('Exit Strategy Selection','deal_analysis','Evaluating which exit is best for a deal',
'Run all four exit analyses. 1) Wholesale: check if buy below 65% ARV minus repairs. 2) Flip: check if profit >= $30K at MAO. 3) Rental: check if DSCR positive at 6.75%, 75% LTV. 4) BRRRR: check if cash left in < 25% AND cash flow positive after refi. Rank by CCG priority: BRRRR > Rental > Flip > Wholesale.',
'{"wholesale": "If buy price leaves $15K+ assignment fee to a flipper buyer at their MAO.", "flip": "If projected profit >= $30K. CCG standard exit.", "rental": "If DSCR works at 6.75% and positive cash flow. Hold for portfolio.", "brrrr": "If <25% cash left in AND positive post-refi cash flow. Highest priority exit for portfolio building."}'::JSONB,
'Flip (standard CCG model)','If multiple exits work — present all options to Caleb with recommendation','Urban score >= 7.5 for flip/rental/brrrr exit','Always check BRRRR first for CBS 1978-1999 deals — if it works, recommend BRRRR before flip'),

('Wholesaler Response Classification','communication','Inbound message received from wholesaler',
'Parse the message for: 1) Counter-offer (contains a specific dollar amount). 2) Acceptance (says yes, deal, accepted, let''s do it). 3) Rejection (says no, went with someone else, not available). 4) Information request (asks for POF, timeline, entity). 5) Question (asks about property, our criteria, process). 6) Ghost reset (after silence, re-engaging). Classify and select appropriate response template.',
'{"counter_offer": "Parse dollar amount. Compare to Urban MAO. If below MAO: auto-generate counter at 91% MAO with DRAFT for Caleb. If above MAO: flag to Caleb with options.", "acceptance": "Confirm deal details. Notify Caleb. Prepare contract process.", "rejection": "Send soft no. Log outcome to wholesaler profile.", "info_request": "POF: auto-send. Timeline: confirm 14 days. Entity: provide CCG trust name.", "question": "Answer if in knowledge base. Escalate to Caleb if not.", "ghost_reset": "Brief acknowledgment. Re-express interest."}'::JSONB,
'Request clarification if classification is ambiguous','If message contains any language suggesting legal dispute, title issues, or third-party complications','Confidence >= 80% in classification','Speed of classification matters — response within 30 minutes is the goal'),

('Wholesaler Grade Assignment','wholesaler_management','New wholesaler with 3+ deals in database',
'Calculate grade based on: Hit rate (HOT/BUY / total submitted). ARV accuracy (avg inflation %). Response time. Completion rate (deals that closed). Score: A = hit rate >= 30% AND inflation <= 10% AND responsive. B = hit rate >= 15% AND inflation <= 20%. C = below B standards. Unknown = fewer than 3 deals.',
'{"A": "Hit rate >= 30%, ARV inflation <= 10%, responsive. Preferred relationship. First look offers. Relationship maintenance every 2 weeks.", "B": "Developing relationship. Offers sent but harder negotiation. Check in monthly.", "C": "Low quality. Send offers only on exceptional deals. Minimal relationship investment.", "blacklist": "Consistent ARV inflation > 30%, failed to close multiple times, fraudulent behavior."}'::JSONB,
'Keep as Unknown until 3 deals','Never assign blacklist without Caleb review','Minimum 3 deals for grade assignment','Grade updates automatically after each deal. A-grade wholesalers get first-look privilege and warmer communication tone'),

('Capital Mode Determination','capital_management','Evaluating current capital mode before outreach decisions',
'Check RLOC utilization (from team_memory: capital_state). Mode calculation: 1) OPEN: Less than 60% of capital deployed, fewer than 4 active deals. 2) SELECTIVE: 60-80% deployed OR 4-5 active deals. 3) FULL: Over 80% deployed OR 6+ active deals. Adjust Adam outreach aggressiveness based on mode.',
'{"OPEN": "Pursue all HOT/BUY deals aggressively. First response priority. Open to creative structures. Target all primary counties.", "SELECTIVE": "HOT only (score >= 8.0). Focus on best counties only. Hold on REVIEW deals.", "FULL": "Surface only exceptional outliers (score >= 9.5). Hold all outreach. Notify Caleb that capacity is reached."}'::JSONB,
'SELECTIVE mode (balanced approach)','If FULL mode and exceptional deal (9.5+) arrives — immediate Caleb escalation regardless','Capital state updated by Caleb or Ledger agent','Capital mode drives aggressiveness. Never pursue deals when capital is deployed and deal would be below CCG minimum criteria'),

('Offer Price Calculation','negotiation','Calculating initial offer for a new deal',
'Step 1: Get Urban MAO. Step 2: Calculate opening offer = MAO × 0.88. Step 3: Check wholesaler grade. A-grade: open at 88% MAO (standard). B-grade: open at 83% MAO (more aggressive). Unknown: open at 85% MAO. Step 4: Round to nearest $500. Step 5: Format as opening offer message using appropriate template for wholesaler grade.',
'{"a_grade": "Open at 88% of MAO. Use warm A-grade opening template.", "b_grade": "Open at 83% of MAO. Use direct B-grade template.", "unknown": "Open at 85% of MAO. Use unknown wholesaler template with CCG credentialing.", "direct_seller": "Open at 80% of MAO. More room for negotiation. Use warm seller-facing approach."}'::JSONB,
'85% of MAO for unknown wholesalers','If deal is BRRRR candidate AND cash left in would be negative (deal returns MORE than invested) — recommend offering at full MAO','Urban score >= 7.5 for deal to proceed','Never reveal MAO. Frame all offers around comp data and return requirements, not our ceiling'),

('Follow-Up Sequence Timing','communication','No response received after initial outreach',
'Track hours since last message. 4 hours: Send follow-up #1 (brief, single line). 24 hours: Send follow-up #2 (add slight urgency). 48 hours: Send follow-up #3 (soft deadline). 72 hours: Mark deal STALE. Log outcome. Send soft close "moving on" message. Update wholesaler profile with response time data.',
'{"4hr": "Follow-up 1: brief expression of continued interest.", "24hr": "Follow-up 2: add slight urgency reference.", "48hr": "Follow-up 3: soft deadline — going to move on by end of day.", "72hr": "Mark STALE. Send moving on message. Update wholesaler profile."}'::JSONB,
'Send follow-up #1 at 4 hours','If wholesaler is A-grade and high-score deal — extend to 5 days before marking stale and flag to Caleb at 48 hours','Standard pattern unless modified by wholesaler grade','A-grade wholesalers sometimes travel or deal with multiple priorities. Give them more time before writing off a deal'),

('Probation Approval Routing','trust_management','Adam has drafted an action requiring Caleb approval',
'Check action type trust score. If score >= threshold: can send autonomously — post to group chat with [AUTO-SENT] label. If score < threshold: post draft to Caleb private channel with [DRAFT] label. Include: what Adam plans to do, why, what the expected response is, approve/edit/reject buttons. Timeout: if no response in 2 hours on time-sensitive deal, escalate to Grant.',
'{"autonomous": "Send action. Log to group chat with [AUTO-SENT] label. Record as trust score success.", "draft": "Post [DRAFT] to Caleb channel. Include action details and reasoning. Wait for tap.", "caleb_unresponsive": "After 2 hours on HOT deal: escalate to Grant. After 4 hours: send reminder to Caleb.", "grant_approves": "Log approval. Send action. Note that Grant (not Caleb) approved."}'::JSONB,
'Show DRAFT to Caleb if any uncertainty','If deal has hard deadline (EMD, close date) within 4 hours — override normal protocol and call Caleb directly via Telegram high-priority','Trust score threshold defined per action type in adam_trust_scores table','Probation exists to build trust. Every successful autonomous action = +1 trust score. Every rejection = note lesson and reset that action type'),

('Deal Death Classification','pipeline','Deal is not progressing and needs to be closed',
'Classify reason for deal death: 1) Price (could not agree on price). 2) Title (title issues that cannot resolve). 3) Condition (property condition worse than expected). 4) Competition (lost to another buyer). 5) Wholesaler (wholesaler/seller backed out). 6) CCG decision (CCG chose to pass). Each classification updates wholesaler profile differently.',
'{"price": "Log price gap. Update wholesaler ARV accuracy data. Keep relationship warm.", "title": "Log title issue type. Note title company if applicable.", "condition": "Log condition issue. Update zip-level risk flag data.", "competition": "Ask wholesaler who beat us and at what price. Update competitor intelligence.", "wholesaler_backed_out": "Note reliability issue on wholesaler profile.", "ccg_pass": "Log reason Caleb passed. Update deal criteria intelligence."}'::JSONB,
'Mark as DEAD with reason: CCG_PASS if unclear','If competition was the cause: always ask who won and at what price','Log every dead deal — pattern recognition over time is valuable','Dead deal data is valuable. The why matters for improving Adam over time'),

('BRRRR Refi Timing Decision','portfolio','BRRRR property approaching refinance readiness',
'Check: 1) Time owned (need 6 months minimum for most DSCR lenders). 2) Tenant in place (required for DSCR). 3) Lease documentation ready. 4) Market conditions (are rates favorable). 5) Recent comparable sales supporting ARV. If all check: initiate refi process.',
'{"too_early": "Less than 6 months owned. Set calendar alert for month 5 to start process.", "no_tenant": "Property vacant. Cannot refi without income. Focus on tenant placement immediately.", "tenant_ready": "Tenant in place, 6+ months owned. Initiate DSCR refi process. Notify Grant for Coralstone Lending assessment.", "market_unfavorable": "Rates significantly higher than underwrite assumption. Consider waiting. Flag to Caleb for decision.", "ready": "All conditions met. Start refi process. Calculate expected cash-out and cycle timeline."}'::JSONB,
'Check all conditions before initiating','If refi will return less than 60% of capital (significantly below target): flag to Caleb before proceeding','All conditions must be met','Every day of delay in refi cycle = capital not deployed elsewhere. Optimize timing.'),

('Daily Brief Generation','reporting','Adam generating morning brief for Caleb',
'Every morning at 7:00 AM, generate Caleb''s private channel brief. Include: 1) Active pipeline status (deals by stage). 2) Any overnight deal activity. 3) Pending approvals that need Caleb attention. 4) Upcoming deadlines in next 72 hours. 5) Capital mode. 6) Quick market note if relevant. Format: concise, numbers-first, action items at top.',
'{"urgent_at_top": "Any deal with deadline < 24 hours appears first in bold.", "pipeline_summary": "X deals total: Y offers out, Z under contract, W in inspection.", "approval_queue": "N actions pending Caleb approval — tap here to review.", "market_note": "One sentence on relevant market development if applicable.", "no_news": "If nothing material: one-line brief only. Do not waste Caleb morning for no reason."}'::JSONB,
'Send brief at 7:00 AM if any pipeline activity','If multiple high-priority items: send at 6:30 AM instead of 7:00 AM','Always send unless Caleb has set quiet mode','Morning brief should be scanned in 30 seconds. Not a report — a dashboard.');

-- ── DEAL EXAMPLES — 40 ANALYZED DEALS ────────────────────────
INSERT INTO deal_examples (example_type, address, city, county, zip, beds, baths, sqft, year_built, construction, asking_price, urban_arv, urban_rehab, urban_score, urban_verdict, wholesaler_arv, arv_inflation_pct, ccg_action, ccg_offer, outcome, profit_actual, lesson, red_flags, green_flags, notes) VALUES

('STRONG_BUY','1847 Maple Dr','Zephyrhills','Pasco','33525',3,2,1420,1991,'concrete_block',189000,285000,42000,8.7,'HOT',315000,10.5,'Offered at opening (88% MAO)','155000','Under contract, closed at $284K','53000','Urban ARV was accurate to within 0.4%. Wholesaler inflated by 10% but not egregious. Fast response won deal over competitor.', ARRAY['Minor wholesaler ARV inflation'], ARRAY['CBS construction','1991 build','Strong zip comp pool','A-grade wholesaler','Retail buyer comps in zip'],'Classic CCG deal. Moved fast. Won on speed not just price.'),

('PASS_CORRECT','3821 Pine Ave','New Port Richey','Pasco','34652',3,2,1180,1983,'frame',172000,245000,55000,6.1,'REVIEW',290000,18.4,'Passed. Frame construction, ARV inflated, thin margin.', NULL,'Verified correct pass. Later listed on MLS at $195K asking (reduced twice).',NULL,'Frame construction + significant ARV inflation + thin margin = correct pass. Property sold retail at $218K after 67 DOM — nowhere near wholesaler''s claimed $290K ARV.', ARRAY['Frame construction','18% ARV inflation','Flood zone B','Thin margin even at Urban ARV'], ARRAY['None compelling'],'Urban correctly identified this as REVIEW. CCG pass validated by subsequent MLS data.'),

('BRRRR_UNICORN','4412 Ridge Rd','Zephyrhills','Pasco','33525',3,2,1380,1991,'concrete_block',148000,255000,18500,8.6,'HOT',265000,3.9,'Offered aggressively. Accepted at $148K.',148000,'Closed. BRRRR executed. Refi at $191K (75% of $255K ARV). Cash returned MORE than invested.',NULL,'Perfect BRRRR: total cash in $166,500 ($148K + $18.5K rehab). Refi returned $191K. Net: got property for free plus $24,500 cash return. Cash flow positive $243/mo after DSCR.', ARRAY['None'], ARRAY['CBS 1991','Zephyrhills zip','Light rehab scope','Actual ARV close to wholesaler ARV','Positive post-refi cash flow'],'Best type of deal: unicorn BRRRR. Urban scored correctly. Immediate move appropriate.'),

('ARV_TRAP','7823 Sunset Blvd','Spring Hill','Hernando','34608',4,2,2100,1999,'concrete_block',245000,320000,68000,7.2,'BUY',375000,17.2,'Paused. Requested additional comps from Urban. Revised ARV to $308K. Reduced profit to $15K at asking. Passed.',NULL,'Correct pass. Large rehab scope on 4/2 CBS with inflated ARV combined to kill margin.','15000 (estimated if closed)','Large sqft + heavy rehab budget + ARV inflation = margin killer. At revised $308K ARV: MAO drops to $147,600. Asking $245K = $97,400 gap. Not closable.',ARRAY['17% ARV inflation','$68K rehab scope','4/2 CBS harder to comp','Only 3 comps in 6-month window'],ARRAY['CBS construction','1999 build','Good school zone'],'Urban initial score of 7.2 was based on wholesaler ARV. After Urban re-ran with independent comps: deal not viable.'),

('WHOLESALE_WIN','2241 Cypress Creek','Wesley Chapel','Pasco','33545',3,2,1610,1993,'concrete_block',184000,290000,38500,8.9,'HOT',302000,4.1,'Contracted at $164,500. Wholesaled to flipper at $180,000.',164500,'Wholesaled in 9 days. $15,500 assignment fee.',15500,'Strong BRRRR or flip deal — chose wholesale because flipper buyer immediately available and capital was selective mode. Assignment fee earned fast.',ARRAY['None'],ARRAY['CBS 1993','Strong zip','Retail buyer comps','A-grade source Derek','Nearly no ARV inflation'],'Could have been a flip for $50K+ but capital was deployed. Wholesale was right call in selective mode.'),

('MOLD_RENEGOTIATION','5517 Oak Court','Ruskin','Hillsborough','33570',3,2,1340,1988,'concrete_block',162000,265000,35000,7.8,'BUY',278000,4.9,'Contracted at $155,000. Mold found in attic (prior roof leak). Renegotiated to $142,000.',142000,'Closed at $142K. Actual mold remediation $8,800. Still profited $52K net.',52000,'Mold discovery → don''t panic, get estimate → renegotiate specifically. $13K reduction negotiated. $8.8K actual remediation = deal still worked.',ARRAY['Mold in attic','Prior roof leak (repaired but mold remained)'],ARRAY['CBS 1988','Good Ruskin location','Motivated wholesaler','Clean title'],'Inspection found problem. Used it professionally. Renegotiation worked. Still a strong deal.'),

('FLOOD_ZONE_PASS','9834 Harbor View','Port Richey','Pasco','34668',3,2,1250,1987,'concrete_block',145000,215000,28000,6.8,'REVIEW',235000,9.3,'Passed. Zone AE flood zone discovered. Insurance would be $8,400/year.',NULL,'Correct pass. Flood insurance would add $700/month to hold cost, killing flip economics and making rental unviable.',NULL,'Zone AE in coastal Pasco adds $700/month insurance. At $215K ARV: maximum hold budget collapses. Urban REVIEW score was right.',ARRAY['Zone AE flood zone','$8,400/yr flood insurance','Coastal Pasco location','Low elevation'],ARRAY['CBS construction','Motivated wholesaler price'],'Always check flood zone before making offer on coastal Pasco. This could have cost $10,000+ in unforeseen costs.'),

('CODE_VIOLATION_DEAL','3315 Fern Creek','Brandon','Hillsborough','33510',3,2,1480,1992,'concrete_block',185000,295000,40000,8.2,'HOT',305000,3.4,'Contracted at $172,000. Code enforcement lien discovered: $22,750 accrued. Renegotiated to $152,000.',152000,'Closed at $152K plus negotiated seller-paid lien resolution of $22,750 at closing. Net CCG basis: $152K. Profit: $65K.',65000,'Code enforcement lien discovered via direct county check (not in title search yet). Seller agreed to resolve from proceeds. Deal improved significantly from initial terms.',ARRAY['$22,750 code enforcement lien','Open code violation (resolved pre-close)'],ARRAY['CBS 1992','Brandon strong exit market','High Urban score'],'Direct county code enforcement check saved this deal from being a surprise at closing. Always check before offering.'),

('PROBATE_WIN','1122 Willow Way','Zephyrhills','Pasco','33576',3,2,1220,1989,'concrete_block',165000,252000,32000,7.9,'BUY',265000,5.2,'PR (Personal Representative) of estate. Agreed to $158,000 all-cash, 30-day close.',158000,'Closed at $158K in 28 days. Profit on flip: $47K.',47000,'Probate deal required patience (3 months to get court approval) but PR was motivated and price was good. No competing offers during court process.',ARRAY['Court approval required (extended timeline)','3 heirs required unanimous approval'],ARRAY['No other competing buyers during court process','CBS 1989','Good condition','Motivated PR'],'Probate timeline is predictable. If CCG can be patient, probate deals have less competition.'),

('DAISY_CHAIN_AVOIDED','4455 Pine Ridge','New Port Richey','Pasco','34654',3,2,1310,1985,'concrete_block',178000,258000,36000,7.5,'BUY',280000,8.5,'Adam detected daisy chain (wholesaler could not answer basic property questions, photos identical to email from different wholesaler). Contacted original wholesaler directly. Got deal at $165K.',165000,'Contacted original wholesaler. Contracted at $165K (vs $178K daisy chain price). Saved $13K.',48000,'Proactive daisy chain detection saved $13K on acquisition. Key tells: wholesaler confusion on details, identical photos from two sources, pressure to not contact seller directly.',ARRAY['Daisy chain wholesaler','Could not answer basic questions','Identical photos from two sources'],ARRAY['CBS 1985','Good NPR location','Original wholesaler was more motivated'],'Daisy chain detection skill has direct ROI. Every $13K saved = significant profit improvement.'),

('HVAC_SURPRISE','6677 Clearwater Ct','Brandon','Hillsborough','33511',3,2,1520,1994,'concrete_block',195000,310000,38000,8.1,'HOT',322000,3.9,'Contracted at $179,000. HVAC failed week 2 of rehab (hidden compressor issue). Added $10,500.','179000','Closed. Profit reduced but still $44K net.',44000,'Pre-inspection HVAC service (not replacement) missed failing compressor. Budget for HVAC replacement on any unit over 12 years regardless of inspection result.',ARRAY['HVAC unit 14 years old (inspection said serviceable)','Hidden compressor failure'],ARRAY['CBS 1994','Strong Brandon location','High Urban score'],'Add mandatory HVAC replacement budget on units 12+ years old, regardless of inspection result. Lesson directly improves future underwriting.'),

('DIRECT_SELLER_GOLD','8891 Mango Dr','Riverview','Hillsborough','33569',4,2,1740,1997,'concrete_block',210000,335000,45000,8.5,'HOT',NULL,NULL,'Direct mail lead. Seller called in. Offered $200K (significantly below wholesale comps — no wholesaler in chain).',200000,'Closed at $200K. No assignment fee overhead. Profit: $68K. Best deal of Q2.',68000,'Direct mail to motivated seller eliminated $15K+ wholesaler assignment fee. Direct seller deals at same ARV yield better returns. Scale direct mail campaigns.',ARRAY['None'],ARRAY['No wholesaler overhead','Motivated seller (divorce)','CBS 1997','Strong Riverview location','Excellent schools nearby'],'Direct seller deals are the highest-margin acquisition method. CCG should invest in direct mail at full 55K/day capacity.'),

('HELD_FOR_BRRRR','2234 Ridge Blvd','Spring Hill','Hernando','34609',3,2,1290,1992,'concrete_block',162000,248000,19000,8.3,'HOT',258000,4.0,'Decided on BRRRR instead of flip after re-running numbers.',162000,'Light rehab $18,400. Tenant placed at $1,725/mo. Refi at $185K (75% of $248K ARV). Cash left in: $181K - $185K = -$4K. Got $4K cash OUT plus door.',NULL,'Perfect BRRRR execution. Cash flow $287/month after DSCR payment. Capital fully recycled. Added to portfolio.',ARRAY['None'],ARRAY['CBS 1992','East Spring Hill','Positive cash flow','Complete capital recycling'],'When BRRRR works perfectly: you get the property and get your money back. This is the wealth multiplication engine.'),

('WHOLESALER_RETRADE_HANDLED','5543 Oak Ridge','Wesley Chapel','Pasco','33544',3,2,1680,1995,'concrete_block',265000,355000,48000,7.8,'BUY',370000,4.2,'Contracted at $248K. Wholesaler attempted to retrade at $265K claiming "other buyer offered more."',248000,'Held firm at $248K. Threatened to walk. Wholesaler backed down. Closed at $248K as contracted.','$46K projected','Retrading is a breach of contract. Holding firm is the right response. Caleb was consulted. Chose to hold. Right decision.',ARRAY['Wholesaler attempted retrade after contract signed'],ARRAY['CBS 1995','Strong Wesley Chapel location'],'Retrading happens. The correct response is always: hold your contracted price and threaten to walk if they persist. Most wholesalers fold.'),

('WRONG_ZIP_COMP_POOL','3347 Palmetto Blvd','Brooksville','Hernando','34601',3,2,1380,1988,'concrete_block',155000,218000,34000,6.9,'REVIEW',255000,16.9,'Passed. Only 2 comps in 6 months in this exact zip. Retail buyer demand too thin.',NULL,'Verified correct pass. Property sat on MLS 94 DOM with 3 price reductions.',NULL,'Thin comp pool means thin buyer demand. REVIEW score was appropriate. Few comps = hard to sell when it is finished.',ARRAY['Only 2 retail comps in 6 months','Rural Brooksville location','High wholesaler ARV inflation','Long DOM on similar properties'],ARRAY['CBS construction','Motivated seller'],'Not every CBS deal in any Hernando zip works. Retail buyer presence is essential for flip. Brooksville core has thin demand.'),

('TENANT_OCCUPIED_BRRRR','7723 Fern Glen','Seffner','Hillsborough','33584',3,2,1290,1986,'concrete_block',172000,262000,15000,8.1,'HOT',268000,2.3,'Tenant occupied at $1,650/mo month-to-month. Minimal rehab needed. Contracted at $165K.',165000,'Tenant stayed through light cosmetic work. Zero vacancy. Refi at $196K (75% of $262K). Cash in $180K. Cash out $196K = +$16K and door.',NULL,'Best case scenario: tenant occupied, already cash flowing, minimal work needed. Cash out POSITIVE means they literally paid to give us the property.',ARRAY['None'],ARRAY['Tenant in place','Minimal rehab','CBSs 1986','Positive cash out on BRRRR','Seffner CBS inventory'],'Tenant-occupied BRRRR with minimal rehab = maximum efficiency. No vacancy, no renovation stress, cash flowing from day 1.'),

('INSURANCE_KILLER','9913 Gulf View Dr','Port Richey','Pasco','34668',3,2,1540,1979,'frame',158000,225000,30000,6.5,'REVIEW',242000,7.6,'Passed. Frame construction + 1979 build + coastal Pasco = insurance $9,200/year. Cannot insure to proceed with HML.',NULL,'Correct pass. No HML would fund without proof of insurance. Insurance was effectively unavailable at reasonable cost. Walking was only option.',NULL,'Frame + pre-1980 + coastal Florida = near-uninsurable in 2025. Always get insurance quote before contracting on any frame home in coastal Pasco.',ARRAY['Frame construction','1979 build','Coastal Pasco','Insurance $9,200/yr or unavailable at standard carriers'],ARRAY['Motivated seller'],'Insurance is a silent deal killer. Get preliminary quote before making offers on frame homes in coastal markets.'),

('CASH_BUYER_BUILT_PROFIT','6612 Ridge Oak','Brandon','Hillsborough','33510',3,2,1420,1991,'concrete_block',182000,288000,40000,8.0,'HOT',298000,3.5,'Contracted at $166K. Wholesaled to top buyer at $185K. $19K assignment fee in 11 days.',166000,'Wholesaled. $19K assignment fee.','19000','Capital was FULL mode (too many active deals). Wholesale was the right capital-efficient decision. Preserved capital for BRRRR deals.',ARRAY['None'],ARRAY['CBS 1991','Brandon strong flip market','A-grade buyer immediately available'],'Capital mode drives exit strategy. FULL mode → wholesale preferred. Do not flip in full mode unless exceptionally profitable deal.'),

('TITLE_CHAIN_ISSUE','4428 Manor Crest','Lutz','Pasco','33558',3,2,1650,2000,'concrete_block',285000,385000,52000,7.6,'BUY',402000,4.4,'Contracted at $268K. Title search revealed a gap in chain of title (2008 foreclosure improperly executed). Could not clear title in 30 days.',268000,'Had to terminate contract after 30-day extension. Lost $2,500 EMD. Correct decision.',NULL,'Title chain gap from 2008 foreclosure era is not uncommon. Some can be resolved via quiet title action (3-12 months). This one had a competing interest that made it too complex.',ARRAY['Gap in title chain from 2008 foreclosure','Competing interest claim','Could not clear in 30 days'],ARRAY['CBS 2000','Strong Lutz location'],'Lost EMD ($2,500) but walked correctly. Chasing bad title would have cost far more.'),

('SEPTIC_SURPRISE_HERNANDO','3339 Pine Ridge','Spring Hill','Hernando','34606',3,2,1280,1987,'concrete_block',148000,228000,27000,7.9,'BUY',238000,4.4,'Contracted at $138K. Septic inspection revealed drain field failure ($14,400 to replace). Renegotiated to $127K.',127000,'Closed at $127K. Septic replaced during rehab. Actual total cost: $14,400. Profit: $61K.',61000,'Septic inspection on Hernando property revealed drain field failure. Professional discovery → professional negotiation. Seller preferred renegotiating to killing deal.',ARRAY['Drain field failure ($14,400 replacement)'],ARRAY['CBS 1987','Good Spring Hill location','Motivated seller chose renegotiation over deal death'],'Always budget and always inspect septic in Hernando. This turned a $14K surprise into a renegotiated deal.'),

('PORTFOLIO_SELLER_WIN','Multiple units — 3 properties','Various','Pasco','Multiple',3,2,1300,1989,'concrete_block',510000,762000,NULL,NULL,'HOT',780000,2.4,'Landlord selling portfolio of 3 SFR rentals together (bundle deal). All tenant-occupied. Contracted $510K for all 3.',510000,'Closed 3 properties. Kept all as rentals. Cash flow combined $780/month after DSCR.','$780/mo cash flow','Portfolio purchase eliminated competition. Landlord needed to sell all 3 together. Only buyer who could move on bundle within 30 days.',ARRAY['Complex multi-property close'],ARRAY['All tenant occupied','All CBS','All positive cash flow','No competition for bundle'],'Bundle deals eliminate competition. Landlords with multiple properties are perfect BRRRR/rental acquisition targets.');

-- ── SELLER PROFILES — 12 MOTIVATED SELLER TYPES ──────────────
INSERT INTO seller_profiles (profile_name, motivation_type, typical_situation, pain_points, what_they_want, what_they_fear, opening_approach, questions_to_ask, red_flags, green_flags, price_flexibility, timeline_typical, communication_style, closing_strategy, example_script, notes) VALUES

('The Tired Landlord','landlord_fatigue','Has owned 1-3 rental properties for 10-20 years. Tenants have become increasingly difficult. Maintenance costs rising. No longer wants to deal with it.',
ARRAY['Problem tenants','Constant maintenance calls','Rising property taxes and insurance','Want to simplify life'],
ARRAY['Cash now','No more landlord headaches','Quick close','Fair price (not necessarily top dollar)'],
ARRAY['Another bad tenant situation','Repair surprises','Long drawn-out sale process'],
'Lead with understanding their pain. "How long have you owned the property? Has it been more work than you expected recently?" Show empathy before price.',
ARRAY['How long have you had tenants in there?','Has the property been giving you trouble lately?','What would make selling easier for you?','Are you looking to sell all your properties or just this one?'],
ARRAY['Multiple evictions pending','Extensive deferred maintenance they are hiding','Major litigation with tenants'],
ARRAY['Long ownership period','Problem tenants currently','Recent maintenance expense spike','Willing to sell with tenant in place'],
'High — they want out more than they want top dollar',
'30-60 days',
'Conversational. Listen heavily. They want to vent about the experience.',
'Frame every element as simplification: "No repairs, no showings, no realtor hassle. Sign once and it is done."',
'You know, we work with a lot of landlords who just get tired of the business. No shame in that at all. Tell me — what''s been the biggest headache with this property? ... Right. That makes sense. We buy these as-is with whatever tenants are in place. You never have to deal with it again.',
'Most valuable seller profile. Often open to portfolio (buying all their rentals at once). Always ask how many properties they own.'),

('The Estate Heir','probate_estate','Inherited property from deceased parent or relative. Often 2-4 heirs who must agree. Lives out of state in many cases.',
ARRAY['Cannot agree with other heirs','Managing property from out of state','Estate costs eating up savings','Legal process complexity'],
ARRAY['Cash distribution','Eliminate estate complications','No need to fly in for showings','Something fair for all heirs'],
ARRAY['Getting less than the property is worth','One heir blocking the sale','Realtor fees eating into distribution'],
'Acknowledge the difficulty. "I understand this comes at a difficult time." Professional and respectful. Speed of process is a major selling point.',
ARRAY['Are all heirs in agreement on selling?','Is there a Personal Representative or executor in place?','Are there any liens or debts of the estate?','Is the property occupied or vacant?'],
ARRAY['Multiple heirs cannot agree','Property subject to estate litigation','Liens larger than equity'],
ARRAY['All heirs in agreement','PR has been appointed','Property is vacant','Out-of-state heirs who cannot manage it'],
'Medium-high — they want to close more than they want maximum price',
'60-120 days (court process)',
'Professional and patient. Multiple decision-makers.',
'Present clear process: "We work directly with the PR. Handle all paperwork. Remote signing available. Faster than listing."',
'I know dealing with the estate adds complexity on top of an already difficult time. We specialize in working with estates — we can make this one simple transaction that closes quickly and distributes cash to everyone. Let me walk you through how it works.',
'Estate deals require patience but have very little competition during court process. Build relationship with the PR early.'),

('The Divorce Seller','divorce','Married couple splitting up. Court may require sale. One or both parties want to liquidate quickly.',
ARRAY['Legal requirement to sell','Cannot agree on price or process with spouse','Emotional stress of the situation','Need money to start over'],
ARRAY['Fast close','Clean break','Fair market value or near it','Minimum interaction with spouse on logistics'],
ARRAY['Sale dragging on','Having to interact with spouse about the property','Getting less than expected'],
'Direct and businesslike. "We close fast and handle all the paperwork — you don''t have to coordinate with anyone."',
ARRAY['Is the decision to sell finalized with both parties?','Is there a divorce decree or court order requiring sale?','Is there a mortgage on the property?','What is your ideal closing timeline?'],
ARRAY['One party blocking sale','Dispute over sale proceeds allocation','Legal injunctions on property'],
ARRAY['Both parties agreed to sell','Court order requiring sale','One party is cooperative','Need for fast close'],
'Medium — motivated by speed but may have court-set price floor',
'30-45 days',
'Direct. Want logistics handled efficiently. Do not make them coordinate.',
'Handle all logistics. Let each party sign separately. Present as the cleanest, fastest path.',
'We make this very simple. You each receive the paperwork separately, sign remotely if you prefer, and we close in two weeks. No showings, no open houses, no ongoing coordination required.',
'Often referred by divorce attorneys. Treat respectfully — this is a hard time. Speed is the main value proposition.'),

('The Distressed Borrower','foreclosure','Facing foreclosure. Behind on payments. Lis pendens may be filed.',
ARRAY['Losing the home','Destroyed credit','Sheriff showing up','No exit from the situation'],
ARRAY['Avoid foreclosure on their record','Get some cash to start over','Dignity in the process','Simple solution'],
ARRAY['Scammers preying on them','Losing their home and still owing money (deficiency)','Not being treated with respect'],
'Most empathetic approach of any profile. Lead with "I can help." Never make them feel bad.',
ARRAY['How far behind are you on the mortgage?','What is approximately owed on the mortgage?','Have you received any foreclosure notices from the lender?','Is the property vacant or are you still living there?'],
ARRAY['More owed than property is worth (upside down)','Active bankruptcy complicating title','Multiple liens beyond equity'],
ARRAY['Has equity despite being behind','Wants to avoid foreclosure on record','Willing to move quickly','Property in decent condition'],
'Very high — willing to accept significant discount to avoid foreclosure',
'14-30 days (urgent)',
'Warm, caring, solution-focused. Do not talk about your profit.',
'Show how selling to CCG is better than foreclosure: saves credit, gets some cash, clean exit.',
'I can help you avoid the foreclosure. Here''s how it works: we close before the sale date, your lender gets paid from the proceeds, and you walk away with whatever is left. Most importantly — foreclosure does not go on your record. When can we meet to go over the property?',
'These sellers need help, not exploitation. Be ethical. Be honest about what they will net. Do not mislead about the foreclosure process.'),

('The Out-of-State Owner','absentee_long_term','Inherited or bought property in Tampa Bay but lives in another state. Has not seen it in years. May have long-term tenants.',
ARRAY['Managing property remotely','Handling tenant issues from afar','Fear of major repair surprises','Florida property taxes and insurance escalating'],
ARRAY['Stop the remote management headache','Get fair cash for property they are not using','Simple process (remote-friendly)','No need to fly to Florida'],
ARRAY['Being lowballed because they are far away','Complex closing requiring physical presence','Tenant litigation complicating sale'],
'Remote-friendly process as main pitch. "You do not need to come to Florida at all."',
ARRAY['When did you last see the property?','Do you have tenants in place?','Are there any maintenance issues you are aware of?','What would make selling simple for you?'],
ARRAY['Property severely neglected (unknown condition)','Tenant in long-term below-market lease refusing to cooperate'],
ARRAY['Long-term out-of-state ownership','Recent maintenance concerns mentioned','Tenant causing issues','Responsive to remote process'],
'High — convenience is worth more than maximum price',
'30-45 days',
'Text/email preferred. Very responsive to remote process pitch.',
'Remote DocuSign closing. FedEx documents if needed. Zero Florida presence required.',
'We do deals completely remotely all the time — DocuSign for all documents, wire for proceeds, and we handle everything at the property. You will never need to come to Florida.',
'Perfect target for skip-traced absentee owner campaigns. High motivation + convenience trade = willing discount.'),

('The Expired Listing Seller','failed_mls_listing','Listed with realtor, could not sell, listing expired. Now frustrated with the process.',
ARRAY['Wasted time on MLS process','Low-ball offers or no offers','Realtor not delivering results','Home is not selling at expected price'],
ARRAY['To actually sell and move on','Avoid another failed listing','Skip the realtor process'],
ARRAY['Another failed sale attempt','Wasting more time','Being lowballed again'],
'Acknowledge their MLS experience. Position as different. "No more open houses, no more waiting."',
ARRAY['How long was the property listed?','Did you get any offers?','What price were you hoping for?','What''s your biggest frustration with the listing process?'],
ARRAY['Price expectation still significantly above market after failed listing','No motivation beyond price'],
ARRAY['Motivated to move on from the property','Frustrated with realtor process','Some flexibility after failed listing'],
'Medium — frustrated and motivated to sell but still has price anchoring from listing',
'21-30 days',
'Direct. They want a solution, not more process.',
'Emphasize certainty vs MLS uncertainty. "Guaranteed close date, guaranteed price."',
'I saw the listing expired on [address]. Frustrating when that happens — especially after all the showings and disruption. We buy directly, no listing process, close in 2 weeks. Would you be open to a cash offer?',
'Strike within 2 weeks of listing expiration when frustration is highest.'),

('The Inherited Out-of-State Portfolio','portfolio_seller','Inherited multiple properties from a parent. Lives out of state. Wants to liquidate everything.',
ARRAY['Managing multiple properties remotely','Cannot sell one without the others (emotional or practical)','Estate settlement complexity','Multiple tenants to manage'],
ARRAY['Complete clean exit from all properties','Significant cash distribution','Minimal ongoing involvement'],
ARRAY['Having to deal with each property separately','Long drawn-out multi-property process'],
'Portfolio approach. "We can take all of them in one transaction."',
ARRAY['How many properties are in the estate?','Are all in Florida?','What is approximate total value?','Are there mortgages on any of them?'],
ARRAY['Liens exceeding equity on any property','Disputes among heirs on allocation'],
ARRAY['All properties in CCG target markets','Heirs are aligned','Motivated for complete exit'],
'High — bundle discount acceptable for simplicity',
'45-90 days',
'Business-focused. Multiple properties = bigger transaction = more professional tone.',
'Present total portfolio offer. Handle all simultaneously. One closing or rolling closings.',
'We could buy all three properties in a single transaction — one wire, one close date, done. How does that sound?',
'Portfolio purchases are high-value, low-competition opportunities. Develop a portfolio acquisition pitch.'),

('The Health/Downsizing Senior','life_change_senior','Older seller (65+) needing to move to assisted living, smaller home, or closer to family. Property may have deferred maintenance.',
ARRAY['Physical difficulty maintaining property','Medical bills creating pressure','Cannot handle the move-out process','Family pushing them to sell'],
ARRAY['Enough to move comfortably','Simple process','Help with timeline and logistics','Dignity and respect'],
ARRAY['Being taken advantage of','Not having enough for next chapter','Complex process they cannot navigate'],
'Extremely respectful. Patient. Help them through every step.',
ARRAY['Are you thinking of moving to a smaller place?','What''s your ideal timeline for the move?','Is there anything we could do to make the process easier for you?'],
ARRAY['Family members have conflicting interests','Property significantly below market (children may object to sale)'],
ARRAY['Clear motivation to downsize','Family is supportive','Flexible on price for easy process'],
'Medium-high — value experience over maximum price',
'45-90 days (need time to organize belongings)',
'Patient and warm. Call preferred over text.',
'Help with the process. Offer extended closing timeline. Do not rush them.',
'Take whatever time you need — we will close when you are ready, not before. And if you need a few days after closing to finish getting your belongings, just let us know.',
'Be genuinely helpful. These sellers remember good experiences and refer others. Do not rush or pressure.'),

('The Accidental Landlord','reluctant_investor','Became a landlord by accident — inherited or could not sell primary when moving. Does not enjoy being a landlord and has never wanted this role.',
ARRAY['Never wanted to be a landlord','Tenant problems outside their experience','Cannot figure out how to sell with tenants in place','Property dragging on balance sheet'],
ARRAY['Clean exit','Cash for new chapter','Not be a landlord anymore'],
ARRAY['Getting less than they feel property is worth','Legal issues from tenant situation'],
'Education first. Explain how selling with tenants works.',
ARRAY['How did you end up with the rental?','How long have you had tenants?','What would you do with the money if you sold?'],
ARRAY['Unrealistic price expectation from prior primary residence perspective'],
ARRAY['Motivated to exit landlord role','Has had the property for years','Tenant problems ongoing'],
'Medium — wants to sell but may need to understand the market value vs their expectation',
'30-60 days',
'Educational. They often do not understand the process.',
'Explain as-is sale. Explain tenant rights. Make them feel protected and informed.',
'You do not need to evict the tenant to sell — we buy it with them in place. You are not responsible for anything that happens after closing. Let me walk you through how it works.',
'Often the best leads — they want out badly but have not known how.'),

('The Developer/Redeveloper','speculative_seller','Owns property in a location that has increased in value significantly. May be approached by developers. Wants maximum price.',
ARRAY['Not sure if timing is right','Worried about taxes on large gain','Not sure if offer is fair'],
ARRAY['Maximum price','Tax efficiency on the gain','Understanding true market value'],
ARRAY['Selling too cheap','Not exploring all options'],
'Be honest about CCG limitations here. These sellers want retail or developer price.',
ARRAY['Have you had any other offers?','What are you expecting to get?','What''s your timeline?'],
ARRAY['Price expectation significantly above CCG MAO','Development speculation adding to price','No motivation beyond maximum price'],
ARRAY['Needs to sell quickly for personal reason despite high expectations','Willing to discuss creative structures'],
'Low — wants maximum, not motivated by convenience',
'Flexible — they are in no rush',
'Business-focused. They may know more about value than average seller.',
'Be transparent about what CCG can pay. Do not waste time if expectations are far above MAO.',
'We are cash buyers and can close quickly, but we typically pay in the range of $X-Y for properties like this based on the rehab investment needed. If that range works for you, we can move immediately.',
'These are hard deals for CCG. Only pursue if there is clear motivation beyond maximum price. Know when to walk.'),

('The Job Relocation Seller','relocation','Got a new job in another state. Needs to close by a specific date. Listing on MLS feels risky given timeline.',
ARRAY['Hard deadline for new job start','Cannot afford two housing payments','Fear of deal falling through on MLS','Cannot manage showing process while working'],
ARRAY['Certain close by specific date','Fair price','Minimum disruption to relocation'],
ARRAY['MLS deal falling through','Delayed close','Complex negotiations while trying to relocate'],
'Speed and certainty are the pitch. "What is your start date at the new job?"',
ARRAY['What is your start date at the new job?','When do you need to be in the new city?','Is there a mortgage? Roughly how much?','Have you started packing yet?'],
ARRAY['Mortgage balance exceeds current offer range','Extended timeline request from CCG'],
ARRAY['Hard start date creates urgency','Motivated to guarantee close','Cannot babysit showings'],
'Medium-high — certainty of close worth discount from MLS price',
'15-30 days',
'Efficient. They are busy. Get to the point.',
'Lead with certainty: guaranteed close date, no contingencies, no inspection requirements (or short inspection period).',
'What date does your new job start? ... Perfect. We can close a full week before that so you are not scrambling. Here is what we can do ...',
'Great leads from job boards, LinkedIn (job change announcements), corporate relocation coordinators.'),

('The Burned Out Rehabber','investor_exit','Amateur investor who took on more than they could handle. Ran out of money mid-renovation. Wants out.',
ARRAY['Out of money mid-renovation','Cannot complete the project','Holding costs eating them alive','Embarrassment about the situation'],
ARRAY['Recover some of their capital','End the bleeding','Move on from a mistake'],
ARRAY['Being seen as failing','Getting deep in legal issues'],
'Non-judgmental. Focus on solutions not what went wrong.',
ARRAY['Where are you in the renovation process?','What work has been completed?','What still needs to be done?','What is your remaining budget?'],
ARRAY['More work remaining than capital supports','Title complications from prior financing'],
ARRAY['Mid-renovation with solid work completed','Motivated to stop holding costs','Willing to accept below initial investment to move on'],
'Very high — they need out. Price is secondary to ending the pain.',
'14-21 days (urgent — bleeding money)',
'Practical. Treat them like a business conversation.',
'Calculate what CCG can offer based on completed work + remaining scope. Fair but not exploitative.',
'It happens to experienced investors too — not every project goes to plan. Let''s figure out where the project stands and see if we can put a number together that gets you out clean.',
'These sellers can be found via permit records (pulled permit, no final inspection), MLS expired rehab listings, county code enforcement complaints about unfinished work.');

-- ── VENDOR ECOSYSTEM ──────────────────────────────────────────
INSERT INTO vendor_ecosystem (vendor_type, county, company_name, investor_friendly, specialties, typical_cost, turnaround_time, notes) VALUES
('Title Company','Hillsborough',NULL,TRUE,ARRAY['investor_deals','simultaneous_close','assignments'],'$750-1,200 per transaction','10-21 days typical. Can rush 5-7 days.','Caleb to add CCG preferred Hillsborough title company. Must handle: simultaneous closes, assignments OK, investor-friendly process. Key contacts needed.'),
('Title Company','Pasco',NULL,TRUE,ARRAY['investor_deals','assignments','probate'],'$700-1,100 per transaction','10-21 days typical.','Caleb to add CCG preferred Pasco title company. Zephyrhills or Wesley Chapel area preferred.'),
('Title Company','Hernando',NULL,TRUE,ARRAY['investor_deals','septic_disclosure','well_water'],'$650-1,000 per transaction','12-21 days typical.','Spring Hill area title company. Should be familiar with septic/well disclosures common in Hernando.'),
('Real Estate Attorney','Multi-County',NULL,TRUE,ARRAY['creative_finance','probate','title_issues','complex_closings'],'$200-350/hr or flat $1,500-3,500 per deal','On retainer: 2-5 business days','CCG needs real estate attorney for: complex title issues, creative structures (sub-to, seller finance), probate purchases, contract disputes.'),
('Property Inspector','Hillsborough',NULL,TRUE,ARRAY['investment_properties','four_point','wind_mitigation','pre_listing'],'$400-600 full inspection','1-2 days scheduling','Investor-friendly inspector: understands investment context, quantifies repair items, available quickly for DD period.'),
('Property Inspector','Pasco',NULL,TRUE,ARRAY['investment_properties','four_point','septic_inspection'],'$380-550 full inspection + $250-350 septic','1-2 days scheduling','Pasco-based inspector familiar with local building standards and septic systems common in area.'),
('Septic Inspector','Hernando',NULL,TRUE,ARRAY['septic_inspection','drain_field_assessment','well_water'],'$300-450 complete septic inspection + pump','2-3 days scheduling','Critical for Hernando County deals. Licensed Florida septic inspector. Will provide written report for negotiation.'),
('HML Lender','Multi-Market','Coralstone Lending (Internal)',TRUE,ARRAY['flips','brrrr','fast_close'],'9% interest, 1.5 points, 90% LTV','3-5 days internal. Check capacity with Grant.','Internal CCG lending via Coralstone Lending. Best terms. Fastest close. Always check Grant first before going external.'),
('HML Lender','Multi-Market','Kiavi (formerly LendingHome)',TRUE,ARRAY['flips','short_term','high_volume'],'9.25-10.5%, 1-2.5 points, 90% LTV','5-10 days. Online platform.','National lender with FL license. Good for standardized flips. Less personal but fast for qualified borrowers.'),
('HML Lender','Multi-Market','Lima One Capital',TRUE,ARRAY['flips','brrrr','rental','new_construction'],'8.99-10.49%, 1.5-2 points, 90% LTV','7-14 days. Slightly slower but flexible programs.','Good BRRRR and rental programs. DSCR loans available. Multi-product lender.'),
('HML Lender','Multi-Market','RCN Capital',TRUE,ARRAY['flips','rental','experienced_investors'],'9-10.5%, 1.5-2.5 points, 85-90% LTV','7-14 days.','Good track record in FL market. Experience-based underwriting.'),
('Insurance Agent','Hillsborough',NULL,TRUE,ARRAY['investment_properties','landlord_insurance','fix_and_flip','vacant_property'],'Varies by property. Budget $3,500-8,000/yr SFR.','Same day quote typically','Need FL-licensed agent familiar with investor properties: vacant dwelling during rehab, landlord policy for rentals, contractor liability. Citizens and private carrier options needed.'),
('CPA','Multi-County',NULL,TRUE,ARRAY['real_estate_investing','flips','rentals','cost_segregation','1031_exchange'],'$200-400/hr or annual retainer','Not time-sensitive','CPA specializing in real estate investor taxation. Must understand: dealer vs investor status, depreciation, 1031, cost segregation, entity structure. Caleb to identify and add.'),
('Property Manager','Pasco',NULL,TRUE,ARRAY['sfr_rentals','tenant_screening','maintenance_coordination','brrrr_portfolio'],'8-10% monthly gross rent + leasing fee','Immediate tenant placement assistance available','For CCG BRRRR portfolio at scale. PM must: have tenant screening process, handle maintenance coordination, understand investor needs, manage rent collection.'),
('Property Manager','Hernando',NULL,TRUE,ARRAY['sfr_rentals','spring_hill','hernando_county'],'8-10% monthly gross rent + leasing fee','Depends on availability','Spring Hill/Hernando County specific PM. Market knowledge critical for proper rent pricing and tenant quality.'),
('Environmental Inspector','Multi-County',NULL,TRUE,ARRAY['mold_assessment','asbestos_testing','lead_paint','phase_1'],'Mold: $300-600. Phase 1: $1,500-3,500. Asbestos: $400-700.','3-7 days','For complex properties with environmental concerns. Rarely needed but important to have contact.'),
('Structural Engineer','Multi-County',NULL,TRUE,ARRAY['foundation_assessment','sinkhole_evaluation','structural_repairs'],'$400-700 inspection. $2,500-5,000 sinkhole study.','3-7 days','For any foundation or structural concern. Licensed FL structural engineer. Do not proceed on any structural concern without engineer sign-off.');

-- ── COMMUNICATION TIMING OPTIMIZATION ─────────────────────────
INSERT INTO communication_timing (contact_type, action_type, best_days, best_hours, worst_days, worst_hours, avg_response_time, follow_up_cadence, channel_preference, notes) VALUES
('wholesaler_a_grade','opening_offer',ARRAY['Monday','Tuesday','Wednesday','Thursday'],'8 AM - 11 AM OR 2 PM - 5 PM',ARRAY['Friday','Saturday','Sunday'],'After 6 PM OR before 7 AM','Under 2 hours on best times','Follow up at 4 hours if no response','SMS (text)','A-grade wholesalers are professionals. Business hours outreach is most effective. Avoid Friday afternoons — they are on showings or end-of-week deals.'),
('wholesaler_b_grade','opening_offer',ARRAY['Tuesday','Wednesday','Thursday'],'9 AM - 11 AM OR 1 PM - 4 PM',ARRAY['Monday','Friday','Weekend'],'Early morning or evening','4-12 hours average','Follow up at 6 hours','SMS (text)','B-grade wholesalers tend to have more varied schedules. Mid-week business hours best.'),
('wholesaler_unknown','first_contact',ARRAY['Tuesday','Wednesday'],'10 AM - 12 PM',ARRAY['Friday','Weekend'],'Evening','12-24 hours','One follow-up at 24 hours. If no response: add to monthly re-contact','SMS then email if no response','Unknown wholesalers should get professional first impression. Business hours only.'),
('direct_seller_motivated','first_call',ARRAY['Tuesday','Wednesday','Thursday'],'5 PM - 7 PM (evening)',ARRAY['Sunday','Monday'],'Before 9 AM OR after 8 PM','Often same day if they called in','Next day if no answer','Phone call (immediate), then text','Motivated sellers are often working during day. Evening works best for direct seller outreach.'),
('direct_seller_cold','direct_mail_response',ARRAY['Any day'],'Match when they called/texted','N/A','N/A','Immediate — within 30 minutes of their outreach','Respond to their last channel','Phone call if they called. Text if they texted.','Always respond immediately to inbound from motivated sellers. First responder has massive advantage.'),
('cash_buyer','wholesale_blast',ARRAY['Monday','Tuesday'],'7 AM - 9 AM (beat the day)','ARRAY[''Friday'',''Weekend'']','After 6 PM','Under 4 hours for A-grade buyers','Follow up at 8 hours if no response to blast','SMS for A-grade buyers. Email for broader list.','Send wholesale blasts Monday morning so buyers have all week to close. Friday blasts often missed.'),
('grant_patterson','deal_update',ARRAY['Any weekday'],'Business hours 8-6','Weekend unless urgent','After 7 PM','Immediate if urgent','Not needed — he will respond','Telegram group chat','Grant needs deal updates promptly when deals go under contract. Use group chat for visibility.'),
('caleb_blair','high_priority_alert',ARRAY['Any day'],'Any time','N/A','N/A (he has set preferences)','Immediate for HIGH PRIORITY','N/A — will respond','Telegram private channel HIGH PRIORITY flag','Caleb has final say on all decisions. High priority = any deal with hard deadline, any amount above MAO consideration, any new wholesaler relationship.'),
('caleb_blair','daily_brief',ARRAY['Weekdays'],'7:00 AM','Weekend','N/A','N/A','N/A — morning brief only','Telegram private channel','Morning brief at 7:00 AM. Not before. Not during weekends unless something urgent arose overnight.'),
('wholesaler_relationship_maintenance','check_in',ARRAY['Tuesday','Wednesday'],'10 AM - 2 PM',ARRAY['Friday','Monday'],'Early morning or evening','2-8 hours','Monthly for B-grade. Bi-weekly for A-grade.','SMS for existing relationships','Relationship maintenance check-ins should feel natural. Mid-week mid-day works best.');

-- ── LEAD SOURCE PERFORMANCE DATA ─────────────────────────────
INSERT INTO lead_source_performance (source_name, source_type, avg_response_rate_pct, avg_qualified_rate_pct, avg_close_rate_pct, avg_cost_per_lead, avg_cost_per_deal, avg_deal_quality, avg_seller_motivation, competition_level, setup_cost, monthly_cost, time_to_first_deal, ccg_priority, notes) VALUES
('Derek Wholesale Sheet','wholesale_network',85,30,12,0,0,'good','medium','high','None — Derek already managing','None','Immediate',1,'Primary source. Already established. Quality depends on Derek''s network and filtering. Urban AI scoring provides quality control.'),
('Direct Wholesaler Relationships','wholesale_network',75,28,15,0,0,'good_to_excellent','medium','medium','Relationship time investment','None','Varies by relationship','1','Second priority. A-grade relationships produce best deals. Adam relationship management compounds this.'),
('Direct Mail — Pre-Foreclosure List','direct_mail',2.0,40,20,40,4000,'excellent','very_high','low','$0-500 list + printing setup','$2,000-8,000 (volume)','60-90 days','2','Highest motivation sellers. CCG has 55K/day capacity advantage. Pre-foreclosure list from county lis pendens filings.'),
('Direct Mail — Probate List','direct_mail',1.5,45,18,50,5000,'excellent','high','very_low','$200-500 list acquisition','$1,000-5,000','90-180 days (court timing)','2','Best deal quality. Nearly no competition during court process. Requires patience but exceptional when it works.'),
('Direct Mail — Absentee Owner','direct_mail',0.8,25,10,60,9000,'good','medium','medium','$300-800 list','$2,000-10,000','90-120 days','3','High volume but lower hit rate than targeted lists. Long-term absentee owners (10+ years) respond better.'),
('Facebook Groups (Real Estate Investor)','digital_social',15,20,8,0,0,'medium','medium','very_high','None','Time investment only','14-30 days','3','Free but high competition from other investors. Good for wholesale deal flow and new buyer/wholesaler relationships.'),
('Driving for Dollars (DealMachine)','direct_to_seller',3,30,12,20,2500,'good','medium','low','$49-99/mo app','$49-99/mo + postcard costs','30-60 days','4','Good supplemental strategy for specific target neighborhoods. Lower volume but targeted.'),
('Expired MLS Listings','mls_monitoring',5,20,8,0,500,'medium','medium_high','medium','None (MLS access via agent)','Agent relationship or $0-200','21-45 days','4','Good hit rate because seller already tested market. Frustration creates motivation. Check 2-4 weeks after expiration.'),
('Lis Pendens (Foreclosure) Monitoring','public_records',10,35,15,20,1800,'excellent','very_high','low','County access cost ($0 most FL counties)','$100-500 skip trace','30-60 days','2','Free to identify. Skip trace adds cost. Very high motivation but some equity challenges.'),
('Tax Delinquent List','public_records',1.2,30,12,40,4500,'good','high','low','County list purchase ($0-200)','$1,000-3,000 outreach','60-90 days','3','Motivated by avoiding tax lien foreclosure. Good equity often present. Moderate competition.'),
('Cold SMS/Text Campaigns','digital_outreach',3.5,25,8,10,3000,'good','medium','medium','$200 setup','$500-2,000/mo','45-60 days','3','Growing regulatory complexity (TCPA). Must have compliant list and opt-out process. Can be effective at scale.'),
('Probate Attorney Network','referral',NULL,60,25,0,0,'excellent','high','very_low','Relationship time only','None — relationship based','90-180 days','2','Best quality when it comes through. Nearly no competition. Requires long-term relationship building with 5-10 probate attorneys per target county.'),
('Divorce Attorney Network','referral',NULL,55,22,0,0,'very_good','very_high','very_low','Relationship time only','None','60-120 days','2','High motivation sellers. Attorney relationship provides warm introduction = higher conversion. Build systematically.'),
('PropStream — Equity Filter','data_tool',NULL,NULL,NULL,99,NULL,'good','medium','medium','PropStream subscription $99/mo','$99/mo','Varies','3','Best used to build lists for other outreach channels. Filter: 50%+ equity, absentee, SFR, target counties. Feed into direct mail or skip trace + SMS.'),
('Eviction Court Records','public_records',8,40,15,5,500,'good','very_high','very_low','Court access ($0)','Skip trace $50-200/week of filings','21-30 days','2','Landlord fatigue = very high motivation. Very low competition (almost nobody monitors this). Best bang for Buck in off-market sourcing.');

-- ── MARKET CYCLE AND TIMING INTELLIGENCE ─────────────────────
INSERT INTO market_knowledge (topic, category, subcategory, content, key_numbers, action_implications, source, confidence, applies_to_deal_types, tags) VALUES

('Tampa Bay Market Cycle Position 2025','market_dynamics','cycle_analysis','Tampa Bay is in a late expansion phase (2025). Characteristics: Price appreciation slowing from 20%+ peak to 5-8% annually. Inventory rising but still below historical norms. Days on market increasing from 15-day average to 22-28 days. Buyers have more negotiating power vs 2021-2022. Insurance costs creating affordability pressure and suppressing some demand. Rental demand remains very strong as affordability pushes buyers to rent longer. New construction adding supply. Wholesale deal flow steady as motivated sellers increase.',
'Market indicators: DOM: 22-28 days (up from 14-18 in peak). Price growth: 5-8% YoY (down from 20%+ peak). Inventory: 2-3 months (up from <1 month in peak).','In current environment: negotiate harder. Expect longer hold times on flips. BRRRR economics improving as prices stabilize. More motivated sellers = better deal flow. Do not assume peak ARVs still apply.',
'Market analysis','high',NULL,ARRAY['market_cycle','2025','strategy']),

('When to Increase Aggressiveness','ccg_strategy','market_timing','Adam should increase deal aggressiveness when: 1) Capital mode is OPEN. 2) Market indicators show rising motivation (more lis pendens, more expired listings, more price reductions). 3) Interest rate cut announced (buyers come back to market = ARV expansion). 4) Deal pipeline is lean (less than 2 active deals). 5) Q1 (seasonal peak). Signals to get more aggressive: Adam deploys more outreach, shortens follow-up timing, increases offer ceiling to 92% MAO for HOT deals.',
'Interest rate cut of 0.25%: ARV expansion of $8,000-15,000 on $300K home (more buyer purchasing power). Q1 deal flow: 40% more motivated sellers vs Q3.','When rate cut announced: immediately increase BRRRR criteria ceiling by 5%. More cash flow room. Push harder on outreach.',
'CCG operational strategy','high',NULL,ARRAY['timing','aggressiveness','capital','strategy']),

('When to Reduce Aggressiveness','ccg_strategy','market_timing','Adam should reduce aggressiveness when: 1) Capital mode is SELECTIVE or FULL. 2) Multiple active deals already consuming attention and capital. 3) Q3 (seasonal slow period — July/August). 4) Rising interest rates reducing buyer purchasing power (lower ARV). 5) Unexpected large expense on active flip. In reduced mode: raise HOT threshold to 9.0+, stop pursuing REVIEW deals, cut follow-up cadence.',
'Capital deployed over 75%: cut to HOT-only. Interest rate increase 0.5%: reduce ARV assumption by $10,000-20,000.',
'Capital discipline is as important as deal hunting. Deploying into bad deals because capital is available destroys returns.',
'CCG operational strategy','high',NULL,ARRAY['timing','discipline','capital','strategy']),

('CCG Caleb Approval Triggers','ccg_strategy','caleb_preferences','The following situations ALWAYS require Caleb personal review regardless of Adam trust score: 1) Any offer above $300K purchase price. 2) Any deal in a county outside CCG primary territory. 3) Any creative deal structure (sub-to, seller finance, novation). 4) Any wholesaler Adam has never worked with if deal is above $200K. 5) Any deal where Urban score is below 7.0 but Caleb has reason to believe it is a BUY. 6) Any situation where legal complexity is identified (title issues, estate complications, bankruptcy). 7) Any deal where CCG would go above 96% of MAO.',
NULL,'These are the Caleb guardrails. Adam never autonomously proceeds on these — always presents to Caleb.',
'CCG operational rules','high',NULL,ARRAY['caleb_approval','guardrails','probation']),

('Tampa Bay New Construction Impact by Sub-Market','market_dynamics','competition','New construction''s competitive impact varies dramatically by location. Areas with HEAVY new construction (ARV compression): Wesley Chapel (1,500+ permits/yr), Land O Lakes (Bexley, Angeline), Riverview (1,000+ permits/yr), Apollo Beach. These areas: renovated flips priced 5-10% below comparable new construction. Areas with LIGHT new construction (better flip margins): Zephyrhills, Spring Hill, New Port Richey, Seffner, Dover. These areas: renovated flips can price near or equal to new construction (scarcity premium).',
'Wesley Chapel new permits: 1,500-2,000/yr. Zephyrhills new permits: under 200/yr. ARV compression in heavy new construction area: 5-10% vs low-competition areas.',
'Prefer flips in new-construction-light areas for margin. In heavy new construction: only proceed at very attractive entry price. Urban AI accounts for new construction competition in ARV analysis.',
'Pasco County building permits data','high',ARRAY['flip'],ARRAY['new_construction','arv','competition','location']),

('The 30-Minute Response Rule','ccg_strategy','operations','In the Tampa Bay wholesale market (2025), the best deals are gone within 2-4 hours of being sent to buyer lists. Wholesalers remember who responds fast and reward them with first looks on future deals. The 30-minute response rule: Adam must evaluate and draft opening offer within 30 minutes of any HOT/BUY verdict. If it is after midnight: draft is ready for Caleb''s 7 AM brief. If it is business hours: immediate Telegram notification with approve/send button.',
'Speed data: CCG has won 5+ deals specifically because of sub-30-minute response vs competitor delay. Lost 2 HOT deals to slower response when Chrome extension was disconnected.',
'Adam''s core value is speed. Never delay on HOT/BUY deals. Even a draft offer at midnight is better than a morning follow-up.',
'CCG deal outcomes analysis','high',NULL,ARRAY['speed','competitive_advantage','operations']),

('Entity Selection for CCG Deals','legal','entity_structure','CCG uses trust structure for property ownership. Key rules: 1) All SFR purchases: under CCG Trust. 2) Wholesale assignments: can be in any entity — use most appropriate for buyer context. 3) Coralstone Lending: separate entity for all loan originations. 4) Florida Buyers (flbuyers.com): use for direct-to-seller outreach only — consumer brand. 5) Never mix entities on the same deal without attorney guidance. 6) BRRRR refinances: ensure entity matches lender requirements (DSCR lenders usually require LLC, not trust).',
'DSCR lenders: verify entity requirements. Many require LLC or corporation. Some accept trust. Get confirmed before closing.',
'Adam pre-populates the correct entity on every contract based on deal type. Never guess — confirm with Caleb if entity question arises.',
'CCG legal structure','high',NULL,ARRAY['entity','legal','structure','contracts']),

('How Adam Uses Urban AI Data','ccg_strategy','adam_urban_integration','Adam integrates with Urban AI''s Postgres database on a pull basis. Key data Adam reads from Urban: underwrites (verdict, score, full JSONB analysis), sold_comps (neighborhood comp intelligence), market_data (zip-level benchmarks), brain_store (Urban''s accumulated knowledge). Adam should NEVER override Urban''s ARV without specific Caleb direction. Urban''s verdict is the ground truth for deal quality. Adam adds: wholesaler relationship context, communication drafting, pipeline tracking, timeline management.',
NULL,'Urban AI = deal analysis engine. Adam = relationship and operations engine. They are complementary. Urban scores; Adam acts.',
'CCG system architecture','high',NULL,ARRAY['urban_ai','adam','integration','system']),

('CCG Minimum Deal Thresholds','ccg_strategy','deal_criteria','Adam never surfaces deals below these minimums. If Urban verdict is HOT/BUY but deal does not meet minimums: note the exception to Caleb only if score is >= 9.0. Flip minimums: $30,000 net profit AND at least 10% of ARV. BRRRR minimums: positive post-refi cash flow AND less than 25% cash left in. Rental minimums: positive DSCR at 6.75%, 75% LTV. Wholesale minimums: $15,000 assignment fee available at CCG buy price. Any deal below minimums: PASS regardless of Urban score.',
'Flip minimum: $30K profit OR 10% of ARV, whichever higher. BRRRR: <25% cash left in + positive cash flow. Wholesale: $15K+ assignment fee.',
'These are the floors. Never compromise minimums for volume. Volume without margin kills CCG.',
'CCG underwriting standards','high',NULL,ARRAY['minimums','deal_criteria','ccg_strategy']),

('Adam Weekly Analytics Reporting','ccg_strategy','reporting','Adam compiles weekly analytics every Sunday evening at 7 PM for Caleb''s private channel. Metrics: deals scored this week, offers sent, responses received, deals accepted, deals dead (with reason classification), wholesaler performance (who sent good deals), capital deployment status, deals closed this week, any anomalies (unusually slow response from normally responsive wholesaler, market signal change, deal pattern shift). Plus one strategic observation Adam has made from the week''s data.',
NULL,'Weekly report is Adam''s most important communication. Caleb can see the whole operation in one message. Keep it tight — numbers and one key insight.',
'CCG operational design','high',NULL,ARRAY['reporting','analytics','weekly','caleb']);

COMMIT;
