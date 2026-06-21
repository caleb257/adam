#!/usr/bin/env node
// ============================================================
// ADAM BRAIN SETUP
// Runs schema + seed data against Railway Postgres
// Usage: node setup.js
//        node setup.js --seed-only   (skip schema, just reseed)
//        node setup.js --schema-only (just schema)
// ============================================================

require('dotenv').config({ path: '.env' });
const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

const SCHEMA_FILE = path.join(__dirname, 'schema.sql');
const SEED_FILE   = path.join(__dirname, 'seed.sql');

const args = process.argv.slice(2);
const seedOnly   = args.includes('--seed-only');
const schemaOnly = args.includes('--schema-only');

async function run() {
  const client = new Client({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

  try {
    console.log('Connecting to Adam Brain database...');
    await client.connect();
    console.log('Connected.');

    if (!seedOnly) {
      console.log('\nRunning schema...');
      const schema = fs.readFileSync(SCHEMA_FILE, 'utf8');
      await client.query(schema);
      console.log('Schema complete.');
    }

    if (!schemaOnly) {
      console.log('\nSeeding brain with Tampa Bay market data...');
      const seed = fs.readFileSync(SEED_FILE, 'utf8');
      await client.query(seed);
      console.log('Seed complete.');
    }

    // Verify row counts
    const tables = [
      'market_areas', 'hud_fmr', 'rehab_costs', 'buy_criteria',
      'negotiation_playbook', 'message_templates', 'adam_trust_scores',
      'market_knowledge', 'property_tax_data', 'insurance_data',
      'adam_learnings', 'ccg_entities', 'title_companies', 'hard_money_lenders'
    ];

    console.log('\n── ADAM BRAIN STATUS ─────────────────────────────');
    for (const t of tables) {
      const r = await client.query(`SELECT COUNT(*) FROM ${t}`);
      const count = r.rows[0].count.padStart(4);
      console.log(`  ${count} rows  ${t}`);
    }
    console.log('──────────────────────────────────────────────────');
    console.log('\nAdam brain is loaded. Ready to build the agent layer.\n');

  } catch (err) {
    console.error('Setup error:', err.message);
    if (err.detail) console.error('Detail:', err.detail);
    process.exit(1);
  } finally {
    await client.end();
  }
}

run();
