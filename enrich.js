#!/usr/bin/env node
// ============================================================
// ADAM BRAIN ENRICHMENT — Deep JSONB extraction from Urban
// Pulls deal-level intelligence from Urban's full underwrite data
// Run AFTER migrate.js has already run
//
// Required: DATABASE_URL, URBAN_DATABASE_URL
// ============================================================

require('dotenv').config({ path: '.env' });
const { Client } = require('pg');

let adamDb, urbanDb;

async function connect() {
  adamDb = new Client({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
  await adamDb.connect();
  console.log('✅ Adam DB connected');

  if (!process.env.URBAN_DATABASE_URL) {
    console.log('⚠️  URBAN_DATABASE_URL not set — skipping enrichment');
    process.exit(0);
  }
  urbanDb = new Client({ connectionString: process.env.URBAN_DATABASE_URL, ssl: { rejectUnauthorized: false } });
  await urbanDb.connect();
  console.log('✅ Urban DB connected');
}

// ── EXTRACT DEEP DEAL INTELLIGENCE ───────────────────────────
async function extractDealIntelligence() {
  console.log('\n── Deep Deal Intelligence ─────────────────────────');

  const { rows } = await urbanDb.query(`
    SELECT uid, address, city, county, zip, beds, sqft, verdict, score,
           worth_brrrr, cash_flow_est, actual_profit, sale_price, buyer_type,
           sold_at, data, updated_at
    FROM underwrites
    WHERE data IS NOT NULL AND verdict IS NOT NULL
    ORDER BY score DESC NULLS LAST
  `);

  console.log(`  Processing ${rows.length} fully underwritten deals...`);

  let lessonCount = 0;
  let knowledgeCount = 0;
  const rehabPatterns = {}; // zip -> [{scope, estimate}]
  const arvPatterns = {};   // zip -> [{wsArv, urbanArv}]
  const riskFlagCounts = {}; // flag name -> count

  for (const row of rows) {
    const d = row.data || {};
    const zip = row.zip || d.deal?.zip || '';
    const county = row.county || d.deal?.county || '';

    // ── RISK FLAG INTELLIGENCE ──────────────────────────────
    const flags = d.riskFlags || [];
    for (const flag of flags) {
      const name = flag.flag || flag.name || '';
      if (!name) continue;
      if (!riskFlagCounts[name]) riskFlagCounts[name] = { count: 0, highCount: 0, details: new Set() };
      riskFlagCounts[name].count++;
      if (flag.severity === 'HIGH') riskFlagCounts[name].highCount++;
      if (flag.detail && riskFlagCounts[name].details.size < 3) {
        riskFlagCounts[name].details.add(flag.detail.slice(0, 100));
      }
    }

    // ── REHAB SCOPE PATTERNS ────────────────────────────────
    if (zip && d.rehab?.scopeLevel && d.rehab?.urbanEstimate > 0) {
      if (!rehabPatterns[zip]) rehabPatterns[zip] = [];
      rehabPatterns[zip].push({
        scope: d.rehab.scopeLevel,
        estimate: d.rehab.urbanEstimate,
        sqft: row.sqft || 0,
        verdict: row.verdict,
      });
    }

    // ── ARV ACCURACY PATTERNS ───────────────────────────────
    if (zip && d.arv?.urbanARV > 0 && d.arv?.wholesalerARV > 0) {
      if (!arvPatterns[zip]) arvPatterns[zip] = [];
      arvPatterns[zip].push({
        urbanArv: d.arv.urbanARV,
        wsArv: d.arv.wholesalerARV,
        inflation: ((d.arv.wholesalerARV - d.arv.urbanARV) / d.arv.urbanARV) * 100,
        verdict: row.verdict,
      });
    }

    // ── SOLD DEAL LESSONS ───────────────────────────────────
    if (row.actual_profit && row.sale_price) {
      const urbanEstProfit = d.financials?.netProfitAtAsking;
      const accuracy = urbanEstProfit
        ? ((row.actual_profit - urbanEstProfit) / Math.abs(urbanEstProfit) * 100).toFixed(1)
        : null;

      await adamDb.query(`
        INSERT INTO adam_learnings (type, context, lesson, confidence, created_at)
        VALUES ($1, $2, $3, $4, $5) ON CONFLICT DO NOTHING
      `, [
        'deal_outcome',
        `Sold deal: ${row.address}, ${row.city}`,
        `CLOSED: ${row.address} sold for $${row.sale_price?.toLocaleString()}. ` +
        `Actual profit: $${row.actual_profit?.toLocaleString()}. ` +
        (row.buyer_type ? `Buyer type: ${row.buyer_type}. ` : '') +
        (accuracy ? `Urban estimated ${accuracy > 0 ? 'less' : 'more'} by ${Math.abs(parseFloat(accuracy)).toFixed(0)}%. ` : '') +
        `Score was ${row.score}/10. Verdict: ${row.verdict}. ZIP: ${zip}.`,
        'high',
        row.sold_at || new Date(),
      ]);
      lessonCount++;
    }

    // ── RECOMMENDATION INTELLIGENCE ─────────────────────────
    if (d.recommendation && d.recommendation.length > 50 && zip) {
      await adamDb.query(`
        INSERT INTO adam_learnings (type, context, lesson, confidence)
        VALUES ($1, $2, $3, $4) ON CONFLICT DO NOTHING
      `, [
        'urban_recommendation',
        `Urban recommendation for ${row.address} (${row.verdict} ${row.score}/10)`,
        `For ${row.city} ${zip} (${row.verdict} score ${row.score}): ${d.recommendation.slice(0, 400)}`,
        'medium',
      ]);
      lessonCount++;
    }

    // ── BRRRR-SPECIFIC INTELLIGENCE ─────────────────────────
    if (row.worth_brrrr && d.rental?.brrrr) {
      const brrrr = d.rental.brrrr;
      await adamDb.query(`
        INSERT INTO adam_learnings (type, context, lesson, confidence)
        VALUES ($1, $2, $3, $4) ON CONFLICT DO NOTHING
      `, [
        'brrrr_analysis',
        `BRRRR analysis: ${row.address} (${zip})`,
        `BRRRR viable for ${row.city} ${zip}. ` +
        (brrrr.cashLeftIn != null ? `Cash left in: $${Math.round(brrrr.cashLeftIn).toLocaleString()}. ` : '') +
        (brrrr.cashFlow != null ? `Monthly cash flow: $${Math.round(brrrr.cashFlow)}. ` : '') +
        (d.arv?.urbanARV ? `ARV: $${d.arv.urbanARV.toLocaleString()}. ` : '') +
        `Score: ${row.score}/10.`,
        'high',
      ]);
      lessonCount++;
    }
  }

  console.log(`  Extracted ${lessonCount} deal-specific lessons`);

  // ── ZIP-LEVEL REHAB PATTERNS ─────────────────────────────
  let rehabKnowledgeAdded = 0;
  for (const [zip, patterns] of Object.entries(rehabPatterns)) {
    if (patterns.length < 2) continue;

    const byScope = {};
    for (const p of patterns) {
      const s = p.scope?.toUpperCase() || 'MEDIUM';
      if (!byScope[s]) byScope[s] = [];
      byScope[s].push(p.estimate);
    }

    const content = `Real rehab data from Urban underwriting for ZIP ${zip}. ` +
      Object.entries(byScope).map(([scope, ests]) => {
        const avg = Math.round(ests.reduce((a, b) => a + b, 0) / ests.length);
        const min = Math.min(...ests);
        const max = Math.max(...ests);
        return `${scope} scope: avg $${avg.toLocaleString()} (range $${min.toLocaleString()}-$${max.toLocaleString()})`;
      }).join('. ') +
      `. Based on ${patterns.length} underwritten deals.`;

    await adamDb.query(`
      INSERT INTO market_knowledge (topic, category, subcategory, content, source, confidence, tags, last_verified)
      VALUES ($1, $2, $3, $4, $5, $6, $7, CURRENT_DATE) ON CONFLICT DO NOTHING
    `, [
      `Rehab Patterns: ZIP ${zip}`,
      'construction',
      'real_rehab_data',
      content,
      'Urban AI underwrite database',
      patterns.length >= 5 ? 'high' : 'medium',
      ['rehab', 'real_data', zip, 'urban_data'],
    ]);
    rehabKnowledgeAdded++;
  }
  console.log(`  Added ${rehabKnowledgeAdded} zip-level rehab pattern entries`);

  // ── ARV ACCURACY BY ZIP ──────────────────────────────────
  let arvKnowledgeAdded = 0;
  for (const [zip, patterns] of Object.entries(arvPatterns)) {
    if (patterns.length < 2) continue;

    const avgInflation = patterns.reduce((a, b) => a + b.inflation, 0) / patterns.length;
    const inflationLabel = avgInflation > 15 ? 'consistently inflated' :
      avgInflation > 7 ? 'slightly inflated' : 'generally accurate';

    await adamDb.query(`
      INSERT INTO market_knowledge (topic, category, subcategory, content, key_numbers, source, confidence, tags, last_verified)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, CURRENT_DATE) ON CONFLICT DO NOTHING
    `, [
      `ARV Accuracy: ZIP ${zip}`,
      'market_dynamics',
      'arv_accuracy',
      `Wholesaler ARV accuracy in ZIP ${zip}: ${inflationLabel}. ` +
      `Average wholesaler ARV inflation vs Urban: ${avgInflation > 0 ? '+' : ''}${avgInflation.toFixed(1)}%. ` +
      `Based on ${patterns.length} deals analyzed.`,
      `Avg WS inflation: ${avgInflation.toFixed(1)}% | ${patterns.length} data points`,
      'Urban AI underwrite database',
      patterns.length >= 5 ? 'high' : 'medium',
      ['arv_accuracy', 'wholesaler', zip, 'urban_data'],
    ]);
    arvKnowledgeAdded++;
  }
  console.log(`  Added ${arvKnowledgeAdded} ARV accuracy entries by zip`);

  // ── TOP RISK FLAGS ───────────────────────────────────────
  const topFlags = Object.entries(riskFlagCounts)
    .sort((a, b) => b[1].count - a[1].count)
    .slice(0, 30);

  for (const [flagName, data] of topFlags) {
    await adamDb.query(`
      INSERT INTO market_knowledge (topic, category, subcategory, content, key_numbers, source, confidence, tags, last_verified)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, CURRENT_DATE) ON CONFLICT DO NOTHING
    `, [
      `Common Risk Flag: ${flagName}`,
      'market_dynamics',
      'risk_patterns',
      `Risk flag "${flagName}" has appeared in Urban analysis ${data.count} times total, ` +
      `${data.highCount} times as HIGH severity. ` +
      (data.details.size > 0 ? `Example context: "${[...data.details][0]}"` : ''),
      `Occurrences: ${data.count} | HIGH severity: ${data.highCount}`,
      'Urban AI risk flag database',
      data.count >= 5 ? 'high' : 'medium',
      ['risk_flag', 'urban_data', flagName.toLowerCase().replace(/\s+/g, '_')],
    ]);
  }
  console.log(`  Added ${topFlags.length} common risk flag entries`);
}

// ── EXTRACT WHOLESALER QUALITY FROM DEAL OUTCOMES ────────────
async function enrichWholesalerProfiles() {
  console.log('\n── Wholesaler Intelligence Enrichment ─────────────');

  // Get all deals with wholesaler data and actual outcomes
  const { rows } = await urbanDb.query(`
    SELECT 
      data->>'deal' as deal_json,
      verdict, score, actual_profit, sale_price, worth_brrrr,
      zip, county, city
    FROM underwrites
    WHERE data IS NOT NULL
    AND (data->'deal'->>'contact1Name' IS NOT NULL OR data->'deal'->>'wholesalerCompany' IS NOT NULL)
  `);

  const wsOutcomes = {};

  for (const row of rows) {
    let deal;
    try { deal = typeof row.deal_json === 'string' ? JSON.parse(row.deal_json) : row.deal_json; }
    catch { continue; }

    const wsName = (deal?.wholesalerCompany || deal?.contact1Company || deal?.contact1Name || '').trim();
    if (!wsName) continue;

    const key = wsName.toLowerCase();
    if (!wsOutcomes[key]) wsOutcomes[key] = {
      name: wsName, company: deal?.wholesalerCompany, deals: 0, hotBuy: 0, pass: 0,
      scores: [], closedDeals: 0, totalProfit: 0, zips: new Set(),
    };

    const w = wsOutcomes[key];
    w.deals++;
    if (['HOT','BUY'].includes(row.verdict)) w.hotBuy++;
    if (['PASS','HARD NO'].includes(row.verdict)) w.pass++;
    if (row.score) w.scores.push(row.score);
    if (row.actual_profit) { w.closedDeals++; w.totalProfit += row.actual_profit; }
    if (row.zip) w.zips.add(row.zip);
  }

  let updated = 0;
  for (const [key, w] of Object.entries(wsOutcomes)) {
    const avgScore = w.scores.length > 0
      ? (w.scores.reduce((a, b) => a + b, 0) / w.scores.length).toFixed(1) : null;
    const hitRate = w.deals > 0 ? Math.round((w.hotBuy / w.deals) * 100) : 0;
    const avgProfit = w.closedDeals > 0 ? Math.round(w.totalProfit / w.closedDeals) : null;

    await adamDb.query(`
      UPDATE wholesalers SET
        adam_notes = $1,
        updated_at = NOW()
      WHERE LOWER(name) = $2 OR LOWER(company) = $2
    `, [
      `Urban data: ${w.deals} deals, ${hitRate}% HOT/BUY rate` +
      (avgScore ? `, avg score ${avgScore}/10` : '') +
      (avgProfit ? `, avg profit $${avgProfit.toLocaleString()} on closed` : '') +
      `. Zips: ${[...w.zips].slice(0,5).join(',')}`,
      key,
    ]);
    updated++;
  }

  console.log(`  Updated ${updated} wholesaler profiles with deal outcome data`);
}

// ── MARKET PERFORMANCE BY SCORE TIER ─────────────────────────
async function analyzeScoreTierPerformance() {
  console.log('\n── Score Tier Performance Analysis ────────────────');

  const { rows } = await urbanDb.query(`
    SELECT
      CASE
        WHEN score >= 9 THEN 'EXCEPTIONAL (9-10)'
        WHEN score >= 8 THEN 'STRONG (8-8.9)'
        WHEN score >= 7 THEN 'GOOD (7-7.9)'
        WHEN score >= 6 THEN 'MARGINAL (6-6.9)'
        ELSE 'WEAK (<6)'
      END as tier,
      verdict,
      COUNT(*) as cnt,
      AVG(score) as avg_score,
      COUNT(CASE WHEN actual_profit > 0 THEN 1 END) as closed_count,
      AVG(actual_profit) as avg_profit
    FROM underwrites
    WHERE score IS NOT NULL AND verdict IS NOT NULL
    GROUP BY 1, 2
    ORDER BY 1, 2
  `);

  if (rows.length > 0) {
    const content = 'Urban AI score tier performance analysis:\n' +
      rows.map(r =>
        `${r.tier} + ${r.verdict}: ${r.cnt} deals` +
        (r.closed_count > 0 ? `, ${r.closed_count} closed, avg profit $${Math.round(r.avg_profit || 0).toLocaleString()}` : '')
      ).join('. ');

    await adamDb.query(`
      INSERT INTO market_knowledge (topic, category, content, source, confidence, tags, last_verified)
      VALUES ($1, $2, $3, $4, $5, $6, CURRENT_DATE) ON CONFLICT DO NOTHING
    `, [
      'Urban Score Performance By Tier',
      'ccg_strategy',
      content,
      'Urban AI database analysis',
      'high',
      ['score_tiers', 'urban_ai', 'performance', 'deal_analysis'],
    ]);
    console.log('  Score tier analysis added');
  }
}

// ── EXTRACT RECOMMENDATION PATTERNS ──────────────────────────
async function extractRecommendationPatterns() {
  console.log('\n── Offer Strategy Pattern Extraction ──────────────');

  const { rows } = await urbanDb.query(`
    SELECT
      county, zip, verdict, score,
      data->'arv'->>'urbanARV' as arv,
      data->'financials'->>'mao' as mao,
      data->>'recommendation' as recommendation,
      data->>'offerStrategy' as offer_strategy,
      data->'financials'->>'netProfitAtAsking' as profit
    FROM underwrites
    WHERE data->>'offerStrategy' IS NOT NULL
    AND verdict IN ('HOT','BUY')
    AND score >= 8
    LIMIT 200
  `);

  console.log(`  Found ${rows.length} high-score deal strategies to analyze`);

  // Group by county to find patterns
  const countyStrategies = {};
  for (const row of rows) {
    if (!row.county || !row.offer_strategy) continue;
    if (!countyStrategies[row.county]) countyStrategies[row.county] = [];
    countyStrategies[row.county].push({
      verdict: row.verdict, score: row.score,
      arv: parseFloat(row.arv), mao: parseFloat(row.mao),
      strategy: row.offer_strategy.slice(0, 200),
    });
  }

  for (const [county, strategies] of Object.entries(countyStrategies)) {
    if (strategies.length < 3) continue;
    const avgArv = Math.round(strategies.reduce((a, b) => a + (b.arv || 0), 0) / strategies.length);
    const avgMao = Math.round(strategies.reduce((a, b) => a + (b.mao || 0), 0) / strategies.length);

    await adamDb.query(`
      INSERT INTO market_knowledge (topic, category, subcategory, content, key_numbers, source, confidence, applies_to_counties, tags, last_verified)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, CURRENT_DATE) ON CONFLICT DO NOTHING
    `, [
      `HOT/BUY Deal Patterns: ${county} County`,
      'ccg_strategy',
      'deal_patterns',
      `Analysis of ${strategies.length} HOT/BUY deals (score 8+) in ${county} County. ` +
      `Average ARV: $${avgArv.toLocaleString()}. Average MAO: $${avgMao.toLocaleString()}. ` +
      `Typical offer strategy: ${strategies.slice(0,3).map(s => s.strategy).join(' | ')}`,
      `Avg ARV: $${avgArv.toLocaleString()} | Avg MAO: $${avgMao.toLocaleString()} | ${strategies.length} deals`,
      'Urban AI HOT/BUY analysis',
      'high',
      [county],
      ['hot_buy_patterns', county.toLowerCase(), 'deal_analysis', 'offer_strategy'],
    ]);
  }
  console.log(`  Added offer patterns for ${Object.keys(countyStrategies).length} counties`);
}

// ── PRINT FINAL BRAIN STATUS ──────────────────────────────────
async function printStatus() {
  const tables = [
    'market_areas','market_knowledge','adam_learnings',
    'wholesalers','deals','rehab_costs',
    'negotiation_playbook','message_templates',
  ];

  console.log('\n── ADAM BRAIN STATUS AFTER ENRICHMENT ────────────');
  let total = 0;
  for (const t of tables) {
    const r = await adamDb.query(`SELECT COUNT(*) FROM ${t}`);
    const n = parseInt(r.rows[0].count);
    total += n;
    console.log(`  ${String(n).padStart(5)}  ${t}`);
  }
  console.log(`  ─────────────────────────────────────────────`);
  console.log(`  ${String(total).padStart(5)}  TOTAL (key tables)`);
  console.log('──────────────────────────────────────────────────');
  console.log('\n✅ Enrichment complete. Adam is loaded with real deal intelligence.\n');
}

async function main() {
  console.log('=== ADAM BRAIN DEEP ENRICHMENT ===\n');
  await connect();
  await extractDealIntelligence();
  await enrichWholesalerProfiles();
  await analyzeScoreTierPerformance();
  await extractRecommendationPatterns();
  await printStatus();
  if (adamDb) await adamDb.end();
  if (urbanDb) await urbanDb.end();
}

main().catch(e => {
  console.error('Enrichment failed:', e.message);
  process.exit(1);
});
