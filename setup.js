#!/usr/bin/env node
require('dotenv').config({ path: '.env' });
const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

const args = process.argv.slice(2);
const seedOnly   = args.includes('--seed-only');
const schemaOnly = args.includes('--schema-only');

async function run() {
  const client = new Client({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
  try {
    console.log('Connecting to Adam DB...');
    await client.connect();
    console.log('Connected.\n');

    if (!seedOnly) {
      console.log('Running schema...');
      await client.query(fs.readFileSync(path.join(__dirname, 'schema.sql'), 'utf8'));
      console.log('Schema ✅\n');
    }

    if (!schemaOnly) {
      const seeds = [
        ['seed.sql', 'Base Tampa Bay market data (148 market areas, 40 rehab costs, 23 templates, 26 trust scores)'],
        ['seed-v2.sql', 'Expanded v2 (50+ market areas, legal/construction/finance knowledge, 30 templates, 20 scenarios)'],
        ['seed-v3.sql', 'Maximum intelligence v3 (DD checklist, scope templates, contractor knowledge, deal structures, 30 templates, 15 learnings)'],
        ['seed-v4.sql', 'Reasoning layer v4 (decision trees, deal examples, seller profiles, vendor ecosystem, communication timing, lead source data)'],
      ];

      for (const [file, desc] of seeds) {
        console.log(`Seeding ${file}...`);
        console.log(`  ${desc}`);
        await client.query(fs.readFileSync(path.join(__dirname, file), 'utf8'));
        console.log(`  ✅\n`);
      }
    }

    // Print row counts
    const tables = [
      'market_areas','hud_fmr','rehab_costs','buy_criteria','wholesalers',
      'cash_buyers','deals','negotiation_playbook','message_templates',
      'adam_trust_scores','market_knowledge','adam_learnings',
      'property_tax_data','insurance_data','title_companies',
      'hard_money_lenders','ccg_entities','due_diligence_items',
      'scope_templates','contractor_knowledge','deal_structures',
      'market_benchmarks','competitor_profiles','decision_trees','deal_examples','seller_profiles','vendor_ecosystem','communication_timing','lead_source_performance'
    ];

    console.log('── ADAM BRAIN STATUS ─────────────────────────────');
    let total = 0;
    for (const t of tables) {
      try {
        const r = await client.query(`SELECT COUNT(*) FROM ${t}`);
        const n = parseInt(r.rows[0].count);
        total += n;
        if (n > 0) console.log(`  ${String(n).padStart(5)}  ${t}`);
      } catch { /* table may not exist yet */ }
    }
    console.log(`  ─────────────────────────────────────────────`);
    console.log(`  ${String(total).padStart(5)}  TOTAL STATIC ROWS`);
    console.log('──────────────────────────────────────────────────');
    console.log('\nNext: run migrate.js to load Urban DB + Derek Sheet data');
    console.log('Then: run enrich.js for deep JSONB intelligence extraction\n');
    console.log('Full stack: node migrate.js && node enrich.js\n');
  } catch(e) {
    console.error('Error:', e.message);
    if (e.detail) console.error('Detail:', e.detail);
    process.exit(1);
  } finally {
    await client.end();
  }
}
run();
