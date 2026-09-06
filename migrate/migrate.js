#!/usr/bin/env node
'use strict';

// CLI für die Migration des Google-Sheets "ZwT 2026 - Probeplan" in
// Postgres. Siehe REFERENCE.md Abschnitt 11.
//
// Nutzung:
//   node migrate/migrate.js [--master <datei>] [--confraeume <datei>] [--apply]
//
// Ohne --apply: Dry-Run, druckt nur eine Zusammenfassung + Warnungen.
// Mit --apply: erfordert DATABASE_URL in der Umgebung, schreibt
// transaktional nach Postgres (Upsert für raeume/musiker, Insert für
// termine/termin_musiker). Das 'pg'-Modul wird nur in diesem Fall
// geladen, damit der Dry-Run ohne `npm install` funktioniert.

const fs = require('fs');
const path = require('path');
const { buildModel } = require('./lib');

function parseArgs(argv) {
  const args = {
    master: path.join(__dirname, 'sample-master.json'),
    confraeume: path.join(__dirname, 'sample-confraeume.json'),
    apply: false,
  };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--master') args.master = argv[++i];
    else if (a === '--confraeume') args.confraeume = argv[++i];
    else if (a === '--apply') args.apply = true;
    else {
      console.error(`Unbekanntes Argument: ${a}`);
      process.exit(1);
    }
  }
  return args;
}

function loadJson(filePath) {
  const raw = fs.readFileSync(filePath, 'utf8');
  return JSON.parse(raw);
}

async function applyToDatabase(model) {
  if (!process.env.DATABASE_URL) {
    console.error('FEHLER: --apply verlangt die Umgebungsvariable DATABASE_URL.');
    process.exit(1);
  }
  // Absichtlich erst hier geladen, damit der Dry-Run ohne `npm install` läuft.
  const { Client } = require('pg');
  const client = new Client({ connectionString: process.env.DATABASE_URL });
  await client.connect();

  try {
    await client.query('BEGIN');

    const raumIdByName = new Map();
    for (const r of model.raeume) {
      const res = await client.query(
        `INSERT INTO raeume (name, aud_code, erlaubte_tage)
         VALUES ($1, $2, $3)
         ON CONFLICT (name) DO UPDATE
           SET aud_code = COALESCE(raeume.aud_code, EXCLUDED.aud_code),
               erlaubte_tage = EXCLUDED.erlaubte_tage
         RETURNING id`,
        [r.name, r.audCode, r.erlaubteTage.length ? r.erlaubteTage : null]
      );
      raumIdByName.set(r.name, res.rows[0].id);
    }

    const musikerIdByKuerzel = new Map();
    for (const m of model.musiker) {
      const res = await client.query(
        `INSERT INTO musiker (kuerzel, name)
         VALUES ($1, $2)
         ON CONFLICT (kuerzel) DO UPDATE SET name = COALESCE(musiker.name, EXCLUDED.name)
         RETURNING id`,
        [m.kuerzel, m.name]
      );
      musikerIdByKuerzel.set(m.kuerzel, res.rows[0].id);
    }

    for (const t of model.termine) {
      const raumId = raumIdByName.get(t.raumName);
      const res = await client.query(
        `INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
         RETURNING id`,
        [t.wochentag, t.datum, t.anfangszeit, t.endzeit, raumId, t.typ, t.werk, t.bemerkungen]
      );
      const terminId = res.rows[0].id;
      for (const kuerzel of t.teilnehmer) {
        const musikerId = musikerIdByKuerzel.get(kuerzel);
        await client.query(
          `INSERT INTO termin_musiker (termin_id, musiker_id) VALUES ($1, $2)
           ON CONFLICT DO NOTHING`,
          [terminId, musikerId]
        );
      }
    }

    await client.query('COMMIT');
    console.log('Erfolgreich nach Postgres geschrieben.');
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    await client.end();
  }
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const masterBloecke = loadJson(args.master);
  const confRaeume = loadJson(args.confraeume);

  const model = buildModel(masterBloecke, confRaeume);

  console.log(`Räume: ${model.raeume.length}`);
  console.log(`Musiker:innen: ${model.musiker.length}`);
  console.log(`Termine: ${model.termine.length}`);
  if (model.warnings.length) {
    console.log(`\nWarnungen (${model.warnings.length}):`);
    for (const w of model.warnings) console.log(`  - ${w}`);
  }

  if (args.apply) {
    await applyToDatabase(model);
  } else {
    console.log('\n(Dry-Run — mit --apply und gesetztem DATABASE_URL tatsächlich schreiben.)');
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
