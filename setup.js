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
      console.log('Seeding v1 (base Tampa Bay data)...');
      await client.query(fs.readFileSync(path.join(__dirname, 'seed.sql'), 'utf8'));
      console.log('Seed v1 ✅\n');

      console.log('Seeding v2 (expanded: 100+ zips, 40+ rehab items, 50+ knowledge, templates, playbook)...');
      await client.query(fs.readFileSync(path.join(__dirname, 'seed-v2.sql'), 'utf8'));
      console.log('Seed v2 ✅\n');
    }

    // Print row counts
    const tables = [
      'market_areas','hud_fmr','rehab_costs','buy_criteria','wholesalers',
      'cash_buyers','deals','negotiation_playbook','message_templates',
      'adam_trust_scores','market_knowledge','adam_learnings',
      'property_tax_data','insurance_data','title_companies',
      'hard_money_lenders','ccg_entities'
    ];

    console.log('── ADAM BRAIN STATUS ─────────────────────────────');
    let total = 0;
    for (const t of tables) {
      const r = await client.query(`SELECT COUNT(*) FROM ${t}`);
      const n = parseInt(r.rows[0].count);
      total += n;
      console.log(`  ${String(n).padStart(5)}  ${t}`);
    }
    console.log(`  ─────────────────────────────────────────────`);
    console.log(`  ${String(total).padStart(5)}  TOTAL ROWS`);
    console.log('──────────────────────────────────────────────────');
    console.log('\nBase brain ready. Run: node migrate.js to load Urban + Sheet data\n');
  } catch(e) {
    console.error('Error:', e.message);
    if (e.detail) console.error('Detail:', e.detail);
    process.exit(1);
  } finally {
    await client.end();
  }
}
run();
