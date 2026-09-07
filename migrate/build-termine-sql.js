#!/usr/bin/env node
'use strict';

// Erzeugt db/seed-termine-<jahr>.sql aus einem bereits mit buildModel()
// (siehe lib.js) aufbereiteten Modell {raeume, musiker, termine, warnings}.
//
// Anders als applyToDatabase() in migrate.js schreibt dieses Skript KEIN
// SQL direkt in eine Datenbank (diese Sandbox hat keinen DB-Zugriff auf
// den Produktions-VPS) -- es erzeugt stattdessen eine SQL-Datei nach dem
// gleichen Muster wie db/seed-raeume.sql / db/seed-werke-2026.sql, die
// Rafi über die etablierte ssh+docker-compose-Befehlsfolge selbst
// anwendet.
//
// Wichtig: Räume werden HIER NICHT angelegt/aktualisiert -- das macht
// bereits db/seed-raeume.sql (muss vorher gelaufen sein). Dieses Skript
// setzt nur voraus, dass jeder in den Termine referenzierte Raumname
// bereits in der Saison existiert (sonst schlägt der Insert mit "Raum
// nicht gefunden" gezielt fehl statt still falsche Daten zu schreiben).
//
// Idempotent im Sinn von "Re-Import ersetzt den kompletten Terminplan
// der Saison": DELETE FROM termine WHERE saison_id = ... am Anfang,
// danach frischer INSERT aus dem Modell. Das passt zum Anwendungsfall
// "der laufende Plan ändert sich noch" -- bei Bedarf einfach das Sheet
// neu exportieren und dieses Skript erneut laufen lassen.
//
// Nutzung:
//   node migrate/build-termine-sql.js <model.json> <jahr> <ausgabedatei.sql>

const fs = require('fs');

function sqlString(value) {
  if (value === null || value === undefined) return 'NULL';
  return `'${String(value).replace(/'/g, "''")}'`;
}

function sqlStringArray(values) {
  if (!values || values.length === 0) return 'NULL';
  return `ARRAY[${values.map(sqlString).join(',')}]`;
}

function main() {
  const [, , modelPath, jahrArg, outPath] = process.argv;
  if (!modelPath || !jahrArg || !outPath) {
    console.error('Nutzung: node migrate/build-termine-sql.js <model.json> <jahr> <ausgabedatei.sql>');
    process.exit(1);
  }
  const jahr = Number(jahrArg);
  const model = JSON.parse(fs.readFileSync(modelPath, 'utf8'));

  const lines = [];
  lines.push(`-- ZwT Probeplan — Terminplan-Import Saison ${jahr}`);
  lines.push('-- Automatisch erzeugt aus dem Google-Sheet "ZwT 2026 - Probeplan",');
  lines.push('-- Tab "Master" (per Google-Drive-Export als .xlsx, dann mit openpyxl');
  lines.push('-- gelesen -- der Google-Drive-Connector selbst liefert bei diesem');
  lines.push('-- grossen Sheet nur einen abgeschnittenen Teil, siehe REFERENCE.md');
  lines.push('-- Abschnitt "Terminplan-Import"). Erzeugt mit');
  lines.push('-- migrate/build-termine-sql.js.');
  lines.push('--');
  lines.push('-- WICHTIG: Re-Import-Semantik -- dieses Skript ERSETZT beim Anwenden');
  lines.push('-- ALLE Termine der Saison durch den Stand aus dem Export (DELETE +');
  lines.push('-- INSERT). Bewusst so, weil "der laufende Plan" sich vor dem');
  lines.push('-- Festival noch ändert -- bei einer neuen Version des Sheets dieses');
  lines.push('-- Skript einfach mit einem neuen Export erneut laufen lassen. Räume');
  lines.push('-- werden NICHT verändert (siehe db/seed-raeume.sql, muss vorher');
  lines.push('-- gelaufen sein); Musiker:innen werden nur ERGÄNZT, nie überschrieben');
  lines.push('-- (ON CONFLICT DO NOTHING -- bereits erfasste Vollnamen bleiben');
  lines.push('-- erhalten).');
  lines.push('--');
  lines.push('-- Anwenden auf dem VPS (nach seed-raeume.sql/seed-werke-2026.sql):');
  lines.push('--   docker compose exec -T db sh -c \'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"\' \\');
  lines.push(`--     < ../db/seed-termine-${jahr}.sql`);
  lines.push('');
  lines.push('BEGIN;');
  lines.push('');
  lines.push(`-- Neue Musiker:innen-Kürzel ergänzen, die im Export auftauchen, aber`);
  lines.push('-- noch nicht erfasst sind (z.B. Sammel-Kürzel wie "Helpers" ohne');
  lines.push('-- Vollnamen). Bestehende Einträge bleiben unangetastet.');
  const sortedMusiker = [...model.musiker].sort((a, b) => a.kuerzel.localeCompare(b.kuerzel));
  for (const m of sortedMusiker) {
    lines.push(
      `INSERT INTO musiker (kuerzel, name, saison_id) VALUES (${sqlString(m.kuerzel)}, ${sqlString(m.name)}, (SELECT id FROM saisons WHERE jahr = ${jahr})) ON CONFLICT (kuerzel, saison_id) DO NOTHING;`
    );
  }
  lines.push('');
  lines.push(`-- Bisherige Termine der Saison ${jahr} verwerfen (termin_musiker fällt`);
  lines.push('-- automatisch per ON DELETE CASCADE mit weg) und frisch aus dem Export');
  lines.push('-- aufbauen.');
  lines.push(`DELETE FROM termine WHERE saison_id = (SELECT id FROM saisons WHERE jahr = ${jahr});`);
  lines.push('');

  let anzahl = 0;
  for (const t of model.termine) {
    anzahl += 1;
    lines.push(`-- ${t.wochentag} ${t.datum} ${t.anfangszeit}-${t.endzeit} ${t.werk}`);
    lines.push('WITH neuer_termin AS (');
    lines.push('  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)');
    lines.push('  SELECT');
    lines.push(`    ${sqlString(t.wochentag)}, ${sqlString(t.datum)}, ${sqlString(t.anfangszeit)}, ${sqlString(t.endzeit)},`);
    lines.push(`    r.id, ${sqlString(t.typ)}, ${sqlString(t.werk)}, ${sqlString(t.bemerkungen)}, s.id`);
    lines.push('  FROM raeume r, saisons s');
    lines.push(`  WHERE r.name = ${sqlString(t.raumName)} AND r.saison_id = s.id AND s.jahr = ${jahr}`);
    lines.push('  RETURNING id');
    lines.push(')');
    if (t.teilnehmer.length > 0) {
      lines.push('INSERT INTO termin_musiker (termin_id, musiker_id)');
      lines.push('SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s');
      lines.push(`WHERE m.kuerzel = ANY(${sqlStringArray(t.teilnehmer)}) AND m.saison_id = s.id AND s.jahr = ${jahr};`);
    } else {
      lines.push('SELECT 1 FROM neuer_termin;');
    }
    lines.push('');
  }

  lines.push('COMMIT;');
  lines.push('');
  lines.push(`-- ${anzahl} Termine erzeugt.`);
  if (model.warnings.length) {
    lines.push(`-- ${model.warnings.length} Warnung(en) beim Aufbau des Modells (siehe Konsolen-Ausgabe von build-termine-sql.js):`);
    for (const w of model.warnings) lines.push(`--   - ${w}`);
  }

  fs.writeFileSync(outPath, lines.join('\n') + '\n', 'utf8');
  console.log(`Geschrieben: ${outPath} (${anzahl} Termine, ${model.musiker.length} Musiker:innen referenziert, ${model.warnings.length} Warnungen)`);
  for (const w of model.warnings) console.log('  WARNUNG:', w);
}

main();
