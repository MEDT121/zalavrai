#!/usr/bin/env node
// ══════════════════════════════════════════════════════════════════
//  Migration d'une école vers le projet Supabase central (PRODELI)
// ══════════════════════════════════════════════════════════════════
//  Étape 4 du TODO de supabase_multitenant_migration.sql : copie les
//  41 tables métier d'un ancien projet Supabase dédié à une école vers
//  le projet central (celui d'admin.html), en ajoutant school_id sur
//  chaque ligne. Idempotent (upsert) — peut être relancé sans risque.
//
//  Pré-requis avant de lancer :
//    1. supabase_multitenant_migration.sql déjà exécuté sur le projet
//       central (school_id + RLS posées sur les 41 tables).
//    2. Une ligne existe dans `schools` (central) pour cette école,
//       avec son license_key — récupérer son `id` (= SCHOOL_ID ci-dessous).
//
//  Usage :
//    OLD_SUPA_URL=https://xxx.supabase.co \
//    OLD_SUPA_KEY=<clé anon ou service de l'ancien projet> \
//    NEW_SUPA_URL=https://vcifxatmlgzueavalfks.supabase.co \
//    NEW_SUPA_SERVICE_KEY=<service_role key du projet central — PAS la clé publique> \
//    SCHOOL_ID=<id de la ligne schools correspondante> \
//    [DRY_RUN=1] \
//    node scripts/migrate-school-to-central.mjs
//
//  NEW_SUPA_SERVICE_KEY doit être la clé service_role (Project Settings
//  → API), pas la clé publishable/anon — sinon RLS bloque l'écriture
//  (is_prodeli_admin() ne peut pas être vrai sans JWT signé applicatif).
//  Ne jamais committer cette clé ni la mettre dans index.html.

const OLD_SUPA_URL = process.env.OLD_SUPA_URL;
const OLD_SUPA_KEY = process.env.OLD_SUPA_KEY;
const NEW_SUPA_URL = process.env.NEW_SUPA_URL;
const NEW_SUPA_SERVICE_KEY = process.env.NEW_SUPA_SERVICE_KEY;
const SCHOOL_ID = process.env.SCHOOL_ID;
const DRY_RUN = process.env.DRY_RUN === '1';

if (!OLD_SUPA_URL || !OLD_SUPA_KEY || !NEW_SUPA_URL || !NEW_SUPA_SERVICE_KEY || !SCHOOL_ID) {
  console.error('Variables manquantes. Voir l\'en-tête de ce script pour l\'usage.');
  process.exit(1);
}

// Même liste que supabase_multitenant_migration.sql — garder synchronisée.
const TABLES = [
  'users','classes','students','payments','attendance','scan_log',
  'conduct','grades','absences','notifs','events','messages','aps',
  'daily_records','daily_expenses','daily_reports','devoirs',
  'cahier_texte','matieres','rattrapages','convocations','timetables',
  'settings','approbations','teacher_notes','audit_log',
  'teacher_absences','medical','tenafep','evaluations','salaries',
  'advances','sanctions','cantine','cantine_menus','cantine_presence',
  'activites','activites_inscriptions','appreciations',
  'medical_visits','inscriptions',
];

const PAGE_SIZE = 1000;
const WRITE_BATCH = 500;

async function fetchAllRows(table) {
  const rows = [];
  let from = 0;
  for (;;) {
    const r = await fetch(`${OLD_SUPA_URL}/rest/v1/${table}?select=*`, {
      headers: {
        apikey: OLD_SUPA_KEY,
        Authorization: `Bearer ${OLD_SUPA_KEY}`,
        Range: `${from}-${from + PAGE_SIZE - 1}`,
        Prefer: 'count=exact',
      },
    });
    if (r.status === 404) return null; // table absente sur l'ancien projet
    if (!r.ok) throw new Error(`GET ${table} (old) → HTTP ${r.status}: ${await r.text()}`);
    const page = await r.json();
    rows.push(...page);
    if (page.length < PAGE_SIZE) break;
    from += PAGE_SIZE;
  }
  return rows;
}

async function upsertRows(table, rows) {
  for (let i = 0; i < rows.length; i += WRITE_BATCH) {
    const batch = rows.slice(i, i + WRITE_BATCH).map(row => ({ ...row, school_id: SCHOOL_ID }));
    const r = await fetch(`${NEW_SUPA_URL}/rest/v1/${table}`, {
      method: 'POST',
      headers: {
        apikey: NEW_SUPA_SERVICE_KEY,
        Authorization: `Bearer ${NEW_SUPA_SERVICE_KEY}`,
        'Content-Type': 'application/json',
        Prefer: 'resolution=merge-duplicates,return=minimal',
      },
      body: JSON.stringify(batch),
    });
    if (!r.ok) throw new Error(`POST ${table} (new) → HTTP ${r.status}: ${await r.text()}`);
  }
}

async function main() {
  console.log(`Migration école school_id=${SCHOOL_ID} : ${OLD_SUPA_URL} → ${NEW_SUPA_URL}${DRY_RUN ? ' (DRY RUN — aucune écriture)' : ''}\n`);
  let totalRows = 0;
  const errors = [];

  for (const table of TABLES) {
    process.stdout.write(`  ${table.padEnd(24)}`);
    try {
      const rows = await fetchAllRows(table);
      if (rows === null) {
        console.log('absente sur l\'ancien projet, ignorée');
        continue;
      }
      if (rows.length === 0) {
        console.log('0 ligne');
        continue;
      }
      if (!DRY_RUN) await upsertRows(table, rows);
      totalRows += rows.length;
      console.log(`${rows.length} ligne(s)${DRY_RUN ? ' (non écrites — dry run)' : ' migrée(s)'}`);
    } catch (e) {
      console.log(`ERREUR — ${e.message}`);
      errors.push({ table, error: e.message });
    }
  }

  console.log(`\nTotal : ${totalRows} ligne(s)${DRY_RUN ? ' trouvées' : ' migrées'}.`);
  if (errors.length) {
    console.log(`\n${errors.length} table(s) en erreur :`);
    errors.forEach(e => console.log(`  - ${e.table}: ${e.error}`));
    process.exit(1);
  }
}

main().catch(e => { console.error(e); process.exit(1); });
