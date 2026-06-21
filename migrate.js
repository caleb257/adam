#!/usr/bin/env node
// ============================================================
// ADAM BRAIN MIGRATION
// Pulls live data from Urban's Postgres + Derek's Google Sheet
// and loads it into Adam's brain database
//
// Required env vars:
//   DATABASE_URL          — Adam's Postgres
//   URBAN_DATABASE_URL    — Urban's Postgres
//   GOOGLE_SHEET_ID       — Derek's sheet ID
//   GOOGLE_CREDENTIALS    — Service account JSON (stringified)
//   GOOGLE_CLIENT_EMAIL   — Service account email
//   GOOGLE_PRIVATE_KEY    — Service account private key
// ============================================================

require('dotenv').config({ path: '.env' });
const { Client } = require('pg');
const { google } = require('googleapis');

const SHEET_ID = process.env.GOOGLE_SHEET_ID || '1las1OYRL2ZgIZjq5_K4bcMM9dAhGxgMOBghfyR29ynU';

let adamDb, urbanDb;

// ── CONNECT ──────────────────────────────────────────────────
async function connect() {
  adamDb = new Client({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
  await adamDb.connect();
  console.log('✅ Connected to Adam DB');

  if (process.env.URBAN_DATABASE_URL) {
    urbanDb = new Client({ connectionString: process.env.URBAN_DATABASE_URL, ssl: { rejectUnauthorized: false } });
    await urbanDb.connect();
    console.log('✅ Connected to Urban DB');
  } else {
    console.log('⚠️  URBAN_DATABASE_URL not set — skipping Urban migration');
  }
}

// ── GOOGLE SHEETS ────────────────────────────────────────────
async function getSheets() {
  const auth = new google.auth.GoogleAuth({
    credentials: process.env.GOOGLE_CREDENTIALS ? JSON.parse(process.env.GOOGLE_CREDENTIALS) : {
      client_email: process.env.GOOGLE_CLIENT_EMAIL,
      private_key: (process.env.GOOGLE_PRIVATE_KEY || '').replace(/\\n/g, '\n'),
    },
    scopes: ['https://www.googleapis.com/auth/spreadsheets.readonly'],
  });
  return google.sheets({ version: 'v4', auth: await auth.getClient() });
}

// ── MIGRATE URBAN UNDERWRITES ─────────────────────────────────
async function migrateUnderwrites() {
  if (!urbanDb) return;
  console.log('\n── Urban Underwrites ──────────────────────────────');

  const { rows } = await urbanDb.query(`
    SELECT uid, address, city, county, zip, beds, sqft, verdict, score,
           worth_brrrr, cash_flow_est, sale_price, actual_profit, buyer_type,
           sold_at, data, updated_at
    FROM underwrites
    WHERE data IS NOT NULL
    ORDER BY updated_at DESC
  `);

  console.log(`  Found ${rows.length} underwritten deals`);

  // Extract zip-level patterns
  const zipStats = {};
  const wholesalerStats = {};

  for (const row of rows) {
    const d = row.data || {};
    const zip = row.zip || d.deal?.zip;
    const county = row.county || d.deal?.county;
    const arv = d.arv?.urbanARV;
    const rehab = d.rehab?.urbanEstimate;
    const asking = parseFloat(d.deal?.askingPrice);
    const verdict = row.verdict;
    const score = row.score;
    const wsName = d.deal?.wholesalerCompany || d.deal?.contact1Company || d.deal?.contact1Name;

    if (zip) {
      if (!zipStats[zip]) zipStats[zip] = {
        zip, county, city: row.city,
        deals: 0, hotBuy: 0, pass: 0,
        totalArv: 0, totalRehab: 0, totalAsking: 0, totalScore: 0,
        arvCount: 0, rehabCount: 0, askCount: 0, scoreCount: 0,
      };
      const z = zipStats[zip];
      z.deals++;
      if (['HOT','BUY'].includes(verdict)) z.hotBuy++;
      if (['PASS','HARD NO'].includes(verdict)) z.pass++;
      if (arv > 0) { z.totalArv += arv; z.arvCount++; }
      if (rehab > 0) { z.totalRehab += rehab; z.rehabCount++; }
      if (asking > 0) { z.totalAsking += asking; z.askCount++; }
      if (score > 0) { z.totalScore += score; z.scoreCount++; }
    }

    if (wsName) {
      const wsKey = wsName.toLowerCase().trim();
      if (!wholesalerStats[wsKey]) wholesalerStats[wsKey] = {
        name: wsName, company: d.deal?.wholesalerCompany,
        phone: d.deal?.contact1Phone, email: d.deal?.contact1Email,
        deals: 0, hotBuy: 0, pass: 0,
        totalArvInflation: 0, inflationCount: 0,
        zips: new Set(), counties: new Set(),
      };
      const ws = wholesalerStats[wsKey];
      ws.deals++;
      if (['HOT','BUY'].includes(verdict)) ws.hotBuy++;
      if (['PASS','HARD NO'].includes(verdict)) ws.pass++;
      if (arv && d.arv?.wholesalerARV && d.arv.wholesalerARV > 0) {
        const inflation = ((d.arv.wholesalerARV - arv) / arv) * 100;
        ws.totalArvInflation += inflation;
        ws.inflationCount++;
      }
      if (zip) ws.zips.add(zip);
      if (county) ws.counties.add(county);
    }
  }

  // Insert zip intelligence into market_knowledge
  const zipEntries = Object.values(zipStats).filter(z => z.deals >= 2);
  console.log(`  Processing ${zipEntries.length} zips with real underwrite data`);

  for (const z of zipEntries) {
    const avgArv = z.arvCount > 0 ? Math.round(z.totalArv / z.arvCount) : null;
    const avgRehab = z.rehabCount > 0 ? Math.round(z.totalRehab / z.rehabCount) : null;
    const avgScore = z.scoreCount > 0 ? (z.totalScore / z.scoreCount).toFixed(1) : null;
    const hotRate = z.deals > 0 ? Math.round((z.hotBuy / z.deals) * 100) : 0;

    const content = `Real underwrite data from ${z.deals} deals Urban has analyzed in ${z.zip}.` +
      (avgArv ? ` Average Urban ARV: $${avgArv.toLocaleString()}.` : '') +
      (avgRehab ? ` Average rehab estimate: $${avgRehab.toLocaleString()}.` : '') +
      (avgScore ? ` Average deal score: ${avgScore}/10.` : '') +
      ` HOT/BUY rate: ${hotRate}%. ${z.hotBuy} deals recommended, ${z.pass} passed.`;

    const keyNumbers = [
      avgArv ? `Avg ARV: $${avgArv.toLocaleString()}` : null,
      avgRehab ? `Avg rehab: $${avgRehab.toLocaleString()}` : null,
      avgScore ? `Avg score: ${avgScore}` : null,
      `HOT/BUY rate: ${hotRate}%`,
      `Total deals: ${z.deals}`,
    ].filter(Boolean).join(' | ');

    await adamDb.query(`
      INSERT INTO market_knowledge (topic, category, subcategory, content, key_numbers, confidence, applies_to_counties, tags, source, last_verified)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, CURRENT_DATE)
      ON CONFLICT DO NOTHING
    `, [
      `Urban Real Data: ZIP ${z.zip}`,
      'market_dynamics',
      'real_underwrite_data',
      content,
      keyNumbers,
      z.deals >= 5 ? 'high' : 'medium',
      z.county ? [z.county] : null,
      ['urban_data', 'real_data', 'zip_intelligence', z.zip],
      'Urban AI underwrite database',
    ]);

    // Also update market_areas if zip exists
    if (avgArv) {
      await adamDb.query(`
        UPDATE market_areas SET
          median_sale_price = COALESCE($1, median_sale_price),
          updated_at = NOW()
        WHERE zip_code = $2
      `, [avgArv, z.zip]);
    }
  }

  // Insert wholesaler profiles from real data
  const wsEntries = Object.values(wholesalerStats).filter(w => w.deals >= 1);
  console.log(`  Processing ${wsEntries.length} wholesaler profiles from real deal data`);

  for (const ws of wsEntries) {
    const avgInflation = ws.inflationCount > 0 ? (ws.totalArvInflation / ws.inflationCount).toFixed(1) : '0';
    const hotRate = ws.deals > 0 ? Math.round((ws.hotBuy / ws.deals) * 100) : 0;
    let grade = 'unknown';
    if (ws.deals >= 3) {
      if (hotRate >= 30 && parseFloat(avgInflation) <= 10) grade = 'A';
      else if (hotRate >= 15 && parseFloat(avgInflation) <= 20) grade = 'B';
      else grade = 'C';
    }

    await adamDb.query(`
      INSERT INTO wholesalers (name, company, phone, email, grade, total_deals_submitted, hot_buy_deals,
        avg_arv_inflation_pct, primary_zips, primary_counties, arv_accuracy_rating, relationship_status, adam_notes)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
      ON CONFLICT (phone) DO UPDATE SET
        total_deals_submitted = EXCLUDED.total_deals_submitted,
        hot_buy_deals = EXCLUDED.hot_buy_deals,
        avg_arv_inflation_pct = EXCLUDED.avg_arv_inflation_pct,
        grade = EXCLUDED.grade,
        adam_notes = EXCLUDED.adam_notes,
        updated_at = NOW()
    `, [
      ws.name,
      ws.company || ws.name,
      ws.phone || null,
      ws.email || null,
      grade,
      ws.deals,
      ws.hotBuy,
      parseFloat(avgInflation),
      [...ws.zips].slice(0, 20),
      [...ws.counties].slice(0, 10),
      parseFloat(avgInflation) <= 10 ? 'accurate' : parseFloat(avgInflation) <= 20 ? 'slightly_inflated' : 'consistently_inflated',
      ws.deals >= 2 ? 'active' : 'new',
      `From Urban data: ${ws.deals} deals submitted, ${ws.hotBuy} HOT/BUY (${hotRate}% hit rate), avg ARV inflation ${avgInflation}%. Grade: ${grade}.`
    ]).catch(() => {
      // If phone conflict fails, try without phone constraint
      return adamDb.query(`
        INSERT INTO wholesalers (name, company, email, grade, total_deals_submitted, hot_buy_deals,
          avg_arv_inflation_pct, primary_zips, primary_counties, arv_accuracy_rating, relationship_status, adam_notes)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
        ON CONFLICT DO NOTHING
      `, [
        ws.name, ws.company || ws.name, ws.email || null,
        grade, ws.deals, ws.hotBuy, parseFloat(avgInflation),
        [...ws.zips].slice(0, 20), [...ws.counties].slice(0, 10),
        parseFloat(avgInflation) <= 10 ? 'accurate' : 'slightly_inflated',
        'active', `Urban data: ${ws.deals} deals, ${hotRate}% hit rate`
      ]);
    });
  }

  console.log(`  ✅ Underwrites migrated: ${zipEntries.length} zip profiles, ${wsEntries.length} wholesaler profiles`);
}

// ── MIGRATE URBAN BRAIN STORE ─────────────────────────────────
async function migrateUrbanBrain() {
  if (!urbanDb) return;
  console.log('\n── Urban Brain Store ──────────────────────────────');

  const { rows } = await urbanDb.query(`SELECT key, value FROM brain_store`);
  console.log(`  Found ${rows.length} brain store entries`);

  for (const row of rows) {
    const brain = row.value;

    // Import lessons
    const lessons = brain?.lessons || [];
    console.log(`  Importing ${lessons.length} lessons from Urban brain`);
    for (const lesson of lessons) {
      if (!lesson.text || lesson.text.length < 20) continue;
      await adamDb.query(`
        INSERT INTO adam_learnings (type, context, lesson, confidence, created_at)
        VALUES ($1, $2, $3, $4, $5)
        ON CONFLICT DO NOTHING
      `, [
        lesson.type || 'urban_brain_lesson',
        lesson.address ? `Deal: ${lesson.address}` : 'Urban brain',
        lesson.text,
        'high',
        lesson.ts ? new Date(lesson.ts) : new Date(),
      ]);
    }

    // Import market insights
    const marketInsights = brain?.marketInsights || brain?.market || [];
    for (const insight of (Array.isArray(marketInsights) ? marketInsights : [])) {
      if (!insight || typeof insight !== 'string') continue;
      await adamDb.query(`
        INSERT INTO market_knowledge (topic, category, content, source, confidence, last_verified)
        VALUES ($1, $2, $3, $4, $5, CURRENT_DATE)
        ON CONFLICT DO NOTHING
      `, [
        `Urban Brain: Market Insight`,
        'market_dynamics',
        insight,
        'Urban AI brain store',
        'medium',
      ]);
    }

    // Import wholesaler insights if present
    const wsInsights = brain?.wholesalerInsights || brain?.wholesalers || {};
    for (const [wsName, data] of Object.entries(wsInsights)) {
      if (!wsName || !data) continue;
      await adamDb.query(`
        INSERT INTO market_knowledge (topic, category, subcategory, content, source, confidence, tags, last_verified)
        VALUES ($1, $2, $3, $4, $5, $6, $7, CURRENT_DATE)
        ON CONFLICT DO NOTHING
      `, [
        `Urban Brain: Wholesaler ${wsName}`,
        'market_dynamics',
        'wholesaler_intelligence',
        `Urban AI has observed: ${JSON.stringify(data).slice(0, 500)}`,
        'Urban AI brain store',
        'medium',
        ['wholesaler', wsName.toLowerCase()],
      ]);
    }
  }

  console.log('  ✅ Urban brain imported');
}

// ── MIGRATE URBAN SOLD COMPS ──────────────────────────────────
async function migrateUrbanComps() {
  if (!urbanDb) return;
  console.log('\n── Urban Sold Comps ───────────────────────────────');

  const { rows } = await urbanDb.query(`
    SELECT zip, county, city, COUNT(*) as cnt,
           AVG(sold_price) as avg_price,
           PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY sold_price) as median_price,
           AVG(ppsf) as avg_ppsf,
           AVG(dom) as avg_dom,
           MIN(sold_date) as oldest_comp,
           MAX(sold_date) as newest_comp,
           COUNT(CASE WHEN pool THEN 1 END) as pool_count,
           AVG(sqft) as avg_sqft
    FROM sold_comps
    WHERE sold_price > 50000
    GROUP BY zip, county, city
    HAVING COUNT(*) >= 3
    ORDER BY cnt DESC
  `);

  console.log(`  Found comp data for ${rows.length} zip codes`);

  for (const row of rows) {
    const content = `Real sold comp data from Urban's database for ZIP ${row.zip} (${row.city}, ${row.county} County). ` +
      `${row.cnt} comparable sales on record. ` +
      `Median sold price: $${Math.round(row.median_price).toLocaleString()}. ` +
      `Average price/sqft: $${Math.round(row.avg_ppsf)}/sf. ` +
      `Average DOM: ${Math.round(row.avg_dom)} days. ` +
      `Average sqft: ${Math.round(row.avg_sqft)} sf. ` +
      `Pool prevalence: ${Math.round((row.pool_count / row.cnt) * 100)}% of sales. ` +
      `Data spans ${row.oldest_comp} to ${row.newest_comp}.`;

    await adamDb.query(`
      INSERT INTO market_knowledge (topic, category, subcategory, content, key_numbers, source, confidence, applies_to_counties, tags, last_verified)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, CURRENT_DATE)
      ON CONFLICT DO NOTHING
    `, [
      `Real Comp Data: ZIP ${row.zip}`,
      'market_dynamics',
      'comp_intelligence',
      content,
      `Median: $${Math.round(row.median_price).toLocaleString()} | PPSF: $${Math.round(row.avg_ppsf)}/sf | DOM: ${Math.round(row.avg_dom)} days | ${row.cnt} comps`,
      'Urban AI sold comps database',
      row.cnt >= 10 ? 'high' : 'medium',
      row.county ? [row.county] : null,
      ['comp_data', 'real_data', row.zip, 'sold_comps'],
    ]);

    // Update market_areas with real comp data
    await adamDb.query(`
      UPDATE market_areas SET
        median_sale_price = $1,
        avg_price_per_sqft = $2,
        avg_days_on_market = $3,
        updated_at = NOW()
      WHERE zip_code = $4
    `, [Math.round(row.median_price), Math.round(row.avg_ppsf), Math.round(row.avg_dom), row.zip]);
  }

  // Pull actual individual comps for notable zips
  const topComps = await urbanDb.query(`
    SELECT zip, address, city, county, beds, baths, sqft, year_built,
           sold_price, sold_date, ppsf, pool, garage, subdivision, nbhc
    FROM sold_comps
    WHERE sold_price > 100000 AND sqft > 800 AND sold_date >= NOW() - INTERVAL '18 months'
    ORDER BY sold_date DESC
    LIMIT 500
  `);

  console.log(`  Got ${topComps.rows.length} individual comps for market intelligence`);

  // Group by zip and create detailed comp notes
  const compsByZip = {};
  for (const c of topComps.rows) {
    if (!compsByZip[c.zip]) compsByZip[c.zip] = [];
    compsByZip[c.zip].push(c);
  }

  for (const [zip, comps] of Object.entries(compsByZip)) {
    if (comps.length < 3) continue;
    const sample = comps.slice(0, 5);
    const compText = sample.map(c =>
      `${c.address} (${c.beds}bd/${c.baths}ba, ${c.sqft}sf, ${c.year_built || '?'}) — $${c.sold_price.toLocaleString()} on ${c.sold_date}`
    ).join('; ');

    await adamDb.query(`
      INSERT INTO market_knowledge (topic, category, subcategory, content, source, confidence, applies_to_counties, tags, last_verified)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, CURRENT_DATE)
      ON CONFLICT DO NOTHING
    `, [
      `Recent Comps Sample: ZIP ${zip}`,
      'market_dynamics',
      'recent_comps',
      `Recent sold comps in ZIP ${zip}: ${compText}. ${comps.length} total recent comps available.`,
      'Urban AI sold comps database',
      'high',
      comps[0].county ? [comps[0].county] : null,
      ['comp_data', 'real_data', zip, 'recent_sales'],
    ]);
  }

  console.log('  ✅ Sold comps migrated');
}

// ── MIGRATE URBAN MARKET DATA ─────────────────────────────────
async function migrateUrbanMarketData() {
  if (!urbanDb) return;
  console.log('\n── Urban Market Data ──────────────────────────────');

  const { rows } = await urbanDb.query(`
    SELECT zip_code, city, county, median_sold, avg_ppsf, median_dom, sold_count,
           trend_pct, flip_margin_pct, rehab_light, rehab_medium, rehab_heavy,
           prop_tax_rate, insurance_mo, notes
    FROM market_data
    WHERE median_sold > 0
    ORDER BY sold_count DESC
  `);

  console.log(`  Found market data for ${rows.length} zip codes`);

  for (const row of rows) {
    // Update market_areas with Urban's real market data
    await adamDb.query(`
      UPDATE market_areas SET
        median_sale_price = COALESCE($1, median_sale_price),
        avg_price_per_sqft = COALESCE($2, avg_price_per_sqft),
        avg_days_on_market = COALESCE($3, avg_days_on_market),
        yoy_appreciation_pct = COALESCE($4, yoy_appreciation_pct),
        updated_at = NOW()
      WHERE zip_code = $5
    `, [
      row.median_sold, row.avg_ppsf, row.median_dom,
      row.trend_pct, row.zip_code
    ]);

    // Insert zip as knowledge entry if it has useful data
    if (row.rehab_light || row.rehab_medium || row.rehab_heavy) {
      await adamDb.query(`
        INSERT INTO market_knowledge (topic, category, subcategory, content, key_numbers, source, confidence, applies_to_counties, tags, last_verified)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, CURRENT_DATE)
        ON CONFLICT DO NOTHING
      `, [
        `Urban Market Data: ZIP ${row.zip_code}`,
        'market_dynamics',
        'urban_market_data',
        `Urban AI market data for ZIP ${row.zip_code} (${row.city}, ${row.county}). ` +
        `Median sold: $${row.median_sold?.toLocaleString() || 'N/A'}. ` +
        `Avg $/sqft: $${row.avg_ppsf || 'N/A'}. ` +
        `Median DOM: ${row.median_dom || 'N/A'} days. ` +
        `${row.sold_count || 0} sales on record. ` +
        (row.rehab_light ? `Light rehab benchmark: $${row.rehab_light.toLocaleString()}. ` : '') +
        (row.rehab_medium ? `Medium rehab benchmark: $${row.rehab_medium.toLocaleString()}. ` : '') +
        (row.rehab_heavy ? `Heavy rehab benchmark: $${row.rehab_heavy.toLocaleString()}. ` : '') +
        (row.prop_tax_rate ? `Property tax rate: ${(row.prop_tax_rate * 100).toFixed(2)}%. ` : '') +
        (row.insurance_mo ? `Est. monthly insurance: $${row.insurance_mo}. ` : '') +
        (row.notes || ''),
        `Median: $${row.median_sold?.toLocaleString() || 'N/A'} | PPSF: $${row.avg_ppsf || 'N/A'} | DOM: ${row.median_dom || 'N/A'}`,
        'Urban AI market data',
        'high',
        row.county ? [row.county] : null,
        ['market_data', 'urban_data', row.zip_code || ''],
      ]);
    }
  }

  console.log('  ✅ Urban market data migrated');
}

// ── MIGRATE DEREK'S SHEET ─────────────────────────────────────
async function migrateDerekSheet() {
  let sheets;
  try {
    sheets = await getSheets();
  } catch (e) {
    console.log('\n── Derek Sheet ────────────────────────────────────');
    console.log('  ⚠️  Google Sheets auth not configured — skipping sheet migration');
    console.log('  (Set GOOGLE_CLIENT_EMAIL + GOOGLE_PRIVATE_KEY env vars to enable)');
    return;
  }

  console.log('\n── Derek Sheet ────────────────────────────────────');

  let rows, headers;
  try {
    const res = await sheets.spreadsheets.values.get({
      spreadsheetId: SHEET_ID,
      range: 'Active Deals!A1:CV1000',
    });
    rows = res.data.values || [];
    if (rows.length <= 1) { console.log('  No data in sheet'); return; }
    headers = rows[0];
    rows = rows.slice(1).filter(r => r[headers.indexOf('Address')]?.trim());
  } catch (e) {
    console.log('  ⚠️  Could not read sheet:', e.message);
    return;
  }

  const col = {};
  headers.forEach((h, i) => { col[h.trim()] = i; });

  console.log(`  Found ${rows.length} deals in Derek's sheet`);

  // Extract wholesaler intelligence from sheet
  const wsMap = {};
  let dealsImported = 0;

  for (const row of rows) {
    const address   = row[col['Address']] || '';
    const city      = row[col['City']] || '';
    const state     = row[col['State']] || 'FL';
    const zip       = row[col['Zip']] || row[col['ZIP']] || '';
    const county    = row[col['County']] || '';
    const beds      = parseInt(row[col['Beds']] || '0');
    const baths     = parseFloat(row[col['Baths']] || '0');
    const sqft      = parseInt(row[col['Sqft']] || row[col['SqFt']] || '0');
    const asking    = parseFloat((row[col['Asking Price']] || '0').replace(/[$,]/g, '')) || 0;
    const wsArv     = parseFloat((row[col['Wholesaler ARV']] || '0').replace(/[$,]/g, '')) || 0;
    const company   = row[col['Company']] || row[col['Wholesaler Company']] || row[col['Contact 1 Company']] || '';
    const contactName = row[col['Contact 1 Name']] || row[col['Contact Name']] || '';
    const phone     = row[col['Contact 1 Phone']] || row[col['Phone']] || '';
    const email     = row[col['Contact 1 Email']] || row[col['Email']] || '';
    const propType  = row[col['Property Type']] || '';
    const yearBuilt = parseInt(row[col['Year Built']] || '0');
    const construction = row[col['Construction']] || '';
    const condition = row[col['Overall Condition']] || row[col['Condition']] || '';
    const floodZone = row[col['Flood Zone']] || '';
    const hoa       = row[col['HOA']] || '';

    // Track wholesaler data
    const wsKey = (company || contactName || '').toLowerCase().trim();
    if (wsKey) {
      if (!wsMap[wsKey]) wsMap[wsKey] = {
        name: contactName, company, phone, email,
        deals: 0, zips: new Set(), counties: new Set(), cities: new Set(),
        propertyTypes: new Set(), askingPrices: [], wsArvs: [],
      };
      const ws = wsMap[wsKey];
      ws.deals++;
      if (zip) ws.zips.add(zip);
      if (county) ws.counties.add(county);
      if (city) ws.cities.add(city);
      if (propType) ws.propertyTypes.add(propType);
      if (asking > 0) ws.askingPrices.push(asking);
      if (wsArv > 0) ws.wsArvs.push(wsArv);
    }

    // Insert deal into Adam deals table (pending, needs Urban score)
    if (address && !address.includes('XXXX')) {
      await adamDb.query(`
        INSERT INTO deals (uid, address, city, county, zip, state, beds, baths, sqft, year_built,
          property_type, construction_type, flood_zone, asking_price, wholesaler_arv, status,
          date_received)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, NOW())
        ON CONFLICT (uid) DO UPDATE SET
          asking_price = EXCLUDED.asking_price,
          updated_at = NOW()
      `, [
        `sheet-${address}-${zip}`.replace(/\s+/g, '-').toLowerCase().slice(0, 100),
        address, city, county, zip, state,
        beds || null, baths || null, sqft || null, yearBuilt || null,
        propType || null,
        construction.toLowerCase().includes('block') ? 'concrete_block' :
          construction.toLowerCase().includes('frame') ? 'frame' : null,
        floodZone || null, asking || null, wsArv || null, 'INCOMING',
      ]).catch(() => {}); // Ignore conflicts on uid
      dealsImported++;
    }
  }

  // Insert/update wholesaler profiles from sheet data
  const wsEntries = Object.values(wsMap).filter(w => w.deals >= 1);
  console.log(`  Processing ${wsEntries.length} wholesalers from sheet`);

  for (const ws of wsEntries) {
    const avgAsking = ws.askingPrices.length > 0
      ? Math.round(ws.askingPrices.reduce((a, b) => a + b, 0) / ws.askingPrices.length) : null;

    await adamDb.query(`
      INSERT INTO wholesalers (name, company, phone, email, total_deals_submitted,
        primary_zips, primary_counties, relationship_status, adam_notes)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
      ON CONFLICT DO NOTHING
    `, [
      ws.name || ws.company || 'Unknown',
      ws.company || ws.name || 'Unknown',
      ws.phone || null,
      ws.email || null,
      ws.deals,
      [...ws.zips].slice(0, 20),
      [...ws.counties].slice(0, 10),
      'active',
      `From Derek sheet: ${ws.deals} deals. ` +
      (avgAsking ? `Avg asking price: $${avgAsking.toLocaleString()}. ` : '') +
      `Works in: ${[...ws.cities].slice(0, 5).join(', ')}.`,
    ]).catch(() => {});
  }

  console.log(`  ✅ Sheet migrated: ${dealsImported} deals, ${wsEntries.length} wholesalers`);
}

// ── MIGRATE NEIGHBORHOOD ARV STATS ───────────────────────────
async function migrateNbhcStats() {
  if (!urbanDb) return;
  console.log('\n── Neighborhood ARV Stats ─────────────────────────');

  const { rows } = await urbanDb.query(`
    SELECT nbhc, county, count, median_sold, avg_ppsf, median_dom,
           beds_mix, zip_codes
    FROM nbhc_arv_stats
    WHERE count >= 3
    ORDER BY count DESC
    LIMIT 200
  `).catch(() => ({ rows: [] }));

  console.log(`  Found ${rows.length} neighborhood ARV profiles`);

  for (const row of rows) {
    if (!row.nbhc) continue;
    await adamDb.query(`
      INSERT INTO market_knowledge (topic, category, subcategory, content, key_numbers, source, confidence, applies_to_counties, tags, last_verified)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, CURRENT_DATE)
      ON CONFLICT DO NOTHING
    `, [
      `Neighborhood ARV: ${row.nbhc}`,
      'market_dynamics',
      'neighborhood_arv',
      `Real ARV data for neighborhood "${row.nbhc}" in ${row.county || 'FL'}. ` +
      `Based on ${row.count} sales. Median sold price: $${(row.median_sold || 0).toLocaleString()}. ` +
      `Average $/sqft: $${Math.round(row.avg_ppsf || 0)}/sf. ` +
      `Median DOM: ${row.median_dom || 'N/A'} days.`,
      `Median: $${(row.median_sold || 0).toLocaleString()} | PPSF: $${Math.round(row.avg_ppsf || 0)} | ${row.count} sales`,
      'Urban AI HCPA/PCPAO neighborhood stats',
      row.count >= 10 ? 'high' : 'medium',
      row.county ? [row.county] : null,
      ['neighborhood', 'arv', 'real_data', row.nbhc?.toLowerCase().replace(/\s+/g, '_') || ''],
    ]);
  }

  console.log('  ✅ Neighborhood stats migrated');
}

// ── PRINT FINAL STATS ─────────────────────────────────────────
async function printStats() {
  const tables = [
    'market_areas', 'market_knowledge', 'wholesalers', 'cash_buyers',
    'deals', 'adam_learnings', 'negotiation_playbook', 'message_templates',
    'rehab_costs', 'adam_trust_scores', 'buy_criteria', 'hud_fmr',
  ];

  console.log('\n── ADAM BRAIN STATUS POST-MIGRATION ──────────────');
  let total = 0;
  for (const t of tables) {
    const r = await adamDb.query(`SELECT COUNT(*) FROM ${t}`);
    const count = parseInt(r.rows[0].count);
    total += count;
    console.log(`  ${String(count).padStart(5)} rows  ${t}`);
  }
  console.log(`  ───────────────────────────────────────────────`);
  console.log(`  ${String(total).padStart(5)} rows  TOTAL`);
  console.log('──────────────────────────────────────────────────');
  console.log('\n✅ Adam brain migration complete. He\'s ready.\n');
}

// ── MAIN ──────────────────────────────────────────────────────
async function main() {
  console.log('=== ADAM BRAIN MIGRATION ===\n');

  await connect();
  await migrateUnderwrites();
  await migrateUrbanBrain();
  await migrateUrbanComps();
  await migrateUrbanMarketData();
  await migrateNbhcStats();
  await migrateDerekSheet();
  await printStats();

  if (adamDb) await adamDb.end();
  if (urbanDb) await urbanDb.end();
}

main().catch(e => {
  console.error('Migration failed:', e.message);
  process.exit(1);
});
