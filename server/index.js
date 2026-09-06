'use strict';

// Server: Health-Checks (Phase 2), Terminverwaltungs-API (Phase 3,
// siehe REFERENCE.md Abschnitt 1/3/4) + Raumplan-Ansicht (Phase 4,
// siehe REFERENCE.md Abschnitt 6).

const path = require('path');
const express = require('express');
const { Pool } = require('pg');
const {
  SELECT_SAISONS_SQL,
  SELECT_SAISON_BY_JAHR_SQL,
  SELECT_AKTIVE_SAISON_SQL,
  INSERT_SAISON_SQL,
  DEAKTIVIERE_ALLE_SAISONS_SQL,
  AKTIVIERE_SAISON_SQL,
  SELECT_TERMINE_SQL,
  SELECT_TERMIN_BY_ID_SQL,
  SELECT_TERMINE_FUER_KONFLIKTPRUEFUNG_SQL,
  SELECT_RAUM_PUFFER_SQL,
  SELECT_RAUM_SQL,
  SELECT_RAEUME_SQL,
  INSERT_TERMIN_SQL,
  UPSERT_MUSIKER_SQL,
  INSERT_TERMIN_MUSIKER_SQL,
  UPDATE_TERMIN_SQL,
  DELETE_TERMIN_MUSIKER_SQL,
  DELETE_TERMIN_SQL,
  SELECT_TERMIN_SAISON_SQL,
  SPERREN_SQL,
  SELECT_LOCKED_AT_SQL,
  SELECT_WERK_VORSCHLAEGE_SQL,
  groupTermineRows,
} = require('./queries');
const { parseTerminInput, findKonflikte, raumTagErlaubt } = require('./validation');
const { erzeugeGesamtplanPdf, erzeugeMusikerplanPdf, formatiereDatum } = require('./pdf');
const { pruefeOrganisatorAuth } = require('./auth');

const app = express();
const port = process.env.PORT || 3000;

const pool = process.env.DATABASE_URL
  ? new Pool({ connectionString: process.env.DATABASE_URL })
  : null;

app.use(express.json());

// Statische Dateien: eigene Seiten (public/). Bis 06.09.2026 wurde hier
// zusätzlich die vis-timeline-Bibliothek ausgeliefert -- ersetzt durch
// die eigene vertikale Tagesansicht (tagesraster.js, Rafi-Feedback
// 07.09.2026), Abhängigkeit deshalb entfernt (siehe package.json).
app.use(express.static(path.join(__dirname, 'public')));
app.get('/favicon.ico', (req, res) => res.status(204).end());

// Löst den Saison-Query-Parameter (`?saison=<Jahr>`) zu einer Saison-Zeile
// auf; ohne Parameter wird die aktuell AKTIVE Saison verwendet (siehe
// REFERENCE.md "Saison-Verwaltung" -- so funktionieren alle Seiten ohne
// Änderung weiter, solange nur eine Saison existiert). Gibt `null`
// zurück, wenn das Jahr unbekannt ist ODER (ohne Parameter) gerade gar
// keine Saison aktiv ist.
async function resolveSaison(client, jahrParam) {
  if (jahrParam !== undefined && jahrParam !== null && jahrParam !== '') {
    const jahr = Number(jahrParam);
    if (!Number.isInteger(jahr)) return null;
    const result = await client.query(SELECT_SAISON_BY_JAHR_SQL, [jahr]);
    return result.rows[0] || null;
  }
  const result = await client.query(SELECT_AKTIVE_SAISON_SQL);
  return result.rows[0] || null;
}

// Gemeinsame Konfliktprüfung für POST (excludeId=null) und PUT
// (excludeId=eigene ID, siehe REFERENCE.md Abschnitt 4). Muss innerhalb
// der aufrufenden Transaktion (client) laufen, damit Prüfung und
// Schreiben konsistent sind. Prüft DREI Dinge: dass die raumId
// existiert UND zur übergebenen Saison gehört (sonst { raumUnbekannt:
// true }, damit der Aufrufer VOR dem Schreiben sauber 400 antworten
// kann statt sich auf den Foreign-Key-Fehler beim INSERT zu verlassen
// -- seit der Saison-Verwaltung, 07.09.2026, zählt ein Raum aus einer
// ANDEREN Saison ebenfalls als "unbekannt"), und — als Teil der
// zurückgegebenen konflikte-Liste — sowohl die Wochentags-Raumbeschränkung
// (REFERENCE.md Abschnitt 2) als auch Überschneidungen/Pufferzeiten.
async function pruefeKonflikte(client, value, excludeId, saisonId) {
  const raumResult = await client.query(SELECT_RAUM_SQL, [value.raumId]);
  const raum = raumResult.rows[0];
  if (!raum || raum.saison_id !== saisonId) {
    return { raumUnbekannt: true };
  }

  const konflikte = [];
  if (!raumTagErlaubt(raum.erlaubte_tage, value.wochentag)) {
    konflikte.push(
      `Raum "${raum.name}" ist am Wochentag "${value.wochentag}" nicht erlaubt (erlaubte Tage: ${raum.erlaubte_tage.join(', ')})`
    );
  }

  const bestehendeResult = await client.query(SELECT_TERMINE_FUER_KONFLIKTPRUEFUNG_SQL, [
    value.raumId,
    value.datum,
    excludeId,
  ]);
  const pufferResult = await client.query(SELECT_RAUM_PUFFER_SQL, [value.raumId]);
  const pufferMinuten = pufferResult.rows[0]?.puffer_minuten ?? 0;
  konflikte.push(...findKonflikte(bestehendeResult.rows, value, pufferMinuten));

  return { konflikte };
}

// Ersetzt die Teilnehmer eines Termins komplett (löschen + neu einfügen)
// und legt dabei unbekannte Musiker-Kürzel automatisch an -- INNERHALB
// der übergebenen Saison (kuerzel ist seit der Saison-Verwaltung nur
// noch pro Saison eindeutig, siehe queries.js UPSERT_MUSIKER_SQL).
async function setzeTeilnehmer(client, terminId, kuerzelListe, saisonId) {
  await client.query(DELETE_TERMIN_MUSIKER_SQL, [terminId]);
  for (const kuerzel of kuerzelListe) {
    const musikerResult = await client.query(UPSERT_MUSIKER_SQL, [kuerzel, saisonId]);
    await client.query(INSERT_TERMIN_MUSIKER_SQL, [terminId, musikerResult.rows[0].id]);
  }
}

// Einheitliche 403-Antwort, wenn eine Schreibaktion eine archivierte
// (nicht mehr aktive) Saison betreffen würde.
function saisonArchiviertFehler(res, jahr) {
  const bezug = jahr ? `Saison ${jahr}` : 'Diese Saison';
  return res.status(403).json({
    status: 'error',
    message: `${bezug} ist nicht aktiv und kann deshalb nicht bearbeitet werden (nur die aktive Saison ist schreibbar).`,
  });
}

app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'zwt-probeplan-server' });
});

app.get('/health/db', async (req, res) => {
  if (!pool) {
    return res.status(503).json({ status: 'error', message: 'DATABASE_URL nicht gesetzt' });
  }
  try {
    await pool.query('SELECT 1');
    res.json({ status: 'ok' });
  } catch (err) {
    res.status(503).json({ status: 'error', message: err.message });
  }
});

// GET /api/saisons — alle Saisons, neueste zuerst (Grundlage für das
// Jahres-Dropdown, Rafi-Feedback 07.09.2026, siehe REFERENCE.md
// "Saison-Verwaltung"). Offen, kein Auth nötig (Lesen).
app.get('/api/saisons', async (req, res) => {
  if (!pool) {
    return res.status(503).json({ status: 'error', message: 'DATABASE_URL nicht gesetzt' });
  }
  try {
    const result = await pool.query(SELECT_SAISONS_SQL);
    res.json({
      saisons: result.rows.map((s) => ({ jahr: s.jahr, bezeichnung: s.bezeichnung, aktiv: s.aktiv })),
    });
  } catch (err) {
    res.status(500).json({ status: 'error', message: err.message });
  }
});

// POST /api/saisons — legt eine neue Saison an. Bewusst NICHT
// automatisch aktiv (siehe db/migration-saisons.sql/queries.js) --
// Räume/Musiker:innen/Konzerte/Werke müssen danach separat für diese
// Saison angelegt werden (z.B. per Seed-Skript, analog zu
// db/seed-raeume.sql/db/seed-werke-2026.sql), bevor sie über
// POST /api/saisons/:jahr/aktivieren "live" geht.
app.post('/api/saisons', pruefeOrganisatorAuth, async (req, res) => {
  if (!pool) {
    return res.status(503).json({ status: 'error', message: 'DATABASE_URL nicht gesetzt' });
  }
  const jahr = Number(req.body.jahr);
  const bezeichnung = typeof req.body.bezeichnung === 'string' ? req.body.bezeichnung.trim() : '';
  if (!Number.isInteger(jahr) || jahr < 2000 || jahr > 2100) {
    return res.status(400).json({ status: 'error', message: 'jahr muss eine plausible Jahreszahl sein' });
  }
  if (!bezeichnung) {
    return res.status(400).json({ status: 'error', message: 'bezeichnung darf nicht leer sein' });
  }
  try {
    const result = await pool.query(INSERT_SAISON_SQL, [jahr, bezeichnung]);
    const s = result.rows[0];
    res.status(201).json({ saison: { jahr: s.jahr, bezeichnung: s.bezeichnung, aktiv: s.aktiv } });
  } catch (err) {
    if (err.code === '23505') {
      return res.status(400).json({ status: 'error', message: `Saison ${jahr} existiert bereits` });
    }
    res.status(500).json({ status: 'error', message: err.message });
  }
});

// POST /api/saisons/:jahr/aktivieren — schaltet auf diese Saison um
// (macht automatisch alle anderen zu Archiv/inaktiv, siehe
// AKTIVIERE_SAISON_SQL). Bewusst ein expliziter, separater Schritt statt
// "neueste Saison = automatisch aktiv" — sonst würde das Vorbereiten
// einer künftigen Saison die gerade laufende versehentlich einfrieren.
app.post('/api/saisons/:jahr/aktivieren', pruefeOrganisatorAuth, async (req, res) => {
  if (!pool) {
    return res.status(503).json({ status: 'error', message: 'DATABASE_URL nicht gesetzt' });
  }
  const jahr = Number(req.params.jahr);
  if (!Number.isInteger(jahr)) {
    return res.status(400).json({ status: 'error', message: 'Ungültiges Jahr in der URL' });
  }
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const saisonResult = await client.query(SELECT_SAISON_BY_JAHR_SQL, [jahr]);
    const saison = saisonResult.rows[0];
    if (!saison) {
      await client.query('ROLLBACK');
      return res.status(404).json({ status: 'error', message: `Saison ${jahr} nicht gefunden` });
    }
    // Erst ALLE deaktivieren, DANN genau eine aktivieren -- zwei
    // getrennte Anweisungen, siehe Kommentar bei AKTIVIERE_SAISON_SQL in
    // queries.js (eine einzelne "SET aktiv = (id = $1)"-Anweisung
    // verletzte je nach Zeilen-Reihenfolge den Unique-Index).
    await client.query(DEAKTIVIERE_ALLE_SAISONS_SQL);
    await client.query(AKTIVIERE_SAISON_SQL, [saison.id]);
    await client.query('COMMIT');
    res.json({ status: 'ok', jahr });
  } catch (err) {
    await client.query('ROLLBACK');
    res.status(500).json({ status: 'error', message: err.message });
  } finally {
    client.release();
  }
});

// GET /api/termine?datum=YYYY-MM-DD  ODER  ?wochentag=Mo  (beides optional,
// ohne Filter werden alle Termine aller Tage DER GEWÄHLTEN SAISON
// geliefert). Zusätzlich optional ?saison=<Jahr> -- ohne Angabe wird die
// aktuell aktive Saison verwendet (siehe resolveSaison oben), damit
// bestehende Aufrufe ohne den neuen Parameter weiterlaufen.
app.get('/api/termine', async (req, res) => {
  if (!pool) {
    return res.status(503).json({ status: 'error', message: 'DATABASE_URL nicht gesetzt' });
  }
  const saison = await resolveSaison(pool, req.query.saison);
  if (!saison) {
    return res.status(400).json({ status: 'error', message: 'Unbekannte Saison oder keine Saison aktiv' });
  }
  const datum = req.query.datum || null;
  const wochentag = req.query.wochentag || null;
  try {
    const result = await pool.query(SELECT_TERMINE_SQL, [datum, wochentag, saison.id]);
    res.json({ termine: groupTermineRows(result.rows) });
  } catch (err) {
    res.status(500).json({ status: 'error', message: err.message });
  }
});

// GET /api/raeume — ALLE Räume EINER Saison, auch ohne Termin an einem
// bestimmten Tag (im Unterschied zu GET /api/termine, das Räume nur
// implizit über vorhandene Termine liefert). Offen, kein Auth nötig
// (Lesen). Optional ?saison=<Jahr>, siehe GET /api/termine.
app.get('/api/raeume', async (req, res) => {
  if (!pool) {
    return res.status(503).json({ status: 'error', message: 'DATABASE_URL nicht gesetzt' });
  }
  const saison = await resolveSaison(pool, req.query.saison);
  if (!saison) {
    return res.status(400).json({ status: 'error', message: 'Unbekannte Saison oder keine Saison aktiv' });
  }
  try {
    const result = await pool.query(SELECT_RAEUME_SQL, [saison.id]);
    res.json({
      raeume: result.rows.map((r) => ({
        id: r.id,
        name: r.name,
        audCode: r.aud_code,
        erlaubteTage: r.erlaubte_tage || [],
      })),
    });
  } catch (err) {
    res.status(500).json({ status: 'error', message: err.message });
  }
});

// GET /api/werke/vorschlaege?q=<Text> — Autocomplete für das Werk-Feld
// in der Terminverwaltung (Phase 8-Erweiterung, Rafi-Feedback 06.09.2026,
// siehe REFERENCE.md Abschnitt 16): sucht sowohl Konzertstücke (z.B.
// "401" = Konzert 4, 1. Werk) als auch feste Ablaufpunkte (z.B. "3" =
// Dîner), per Nummer-Präfix ODER Namens-Präfix. Liefert je Treffer den
// Standard-Teilnehmerkreis mit, den admin.html dann vorschlägt (bleibt
// änderbar). Offen, kein Auth nötig (Lesen, wie GET /api/raeume).
// Optional ?saison=<Jahr>, siehe GET /api/termine.
app.get('/api/werke/vorschlaege', async (req, res) => {
  if (!pool) {
    return res.status(503).json({ status: 'error', message: 'DATABASE_URL nicht gesetzt' });
  }
  const q = (req.query.q || '').trim();
  if (!q) {
    return res.json({ vorschlaege: [] });
  }
  const saison = await resolveSaison(pool, req.query.saison);
  if (!saison) {
    return res.status(400).json({ status: 'error', message: 'Unbekannte Saison oder keine Saison aktiv' });
  }
  try {
    const result = await pool.query(SELECT_WERK_VORSCHLAEGE_SQL, [q, saison.id]);
    res.json({
      vorschlaege: result.rows.map((r) => ({
        nummer: r.nummer,
        name: r.name,
        typ: r.typ,
        dauerMinuten: r.dauer_minuten,
        teilnehmer: r.teilnehmer || [],
      })),
    });
  } catch (err) {
    res.status(500).json({ status: 'error', message: err.message });
  }
});

// POST /api/termine — legt einen neuen Termin an (siehe REFERENCE.md
// Abschnitt 1/3/4). Erwartet JSON-Body: { wochentag, datum, anfangszeit,
// endzeit, raumId, typ, werk, bemerkungen, teilnehmer }. Führt VOR dem
// Anlegen die Konfliktprüfung durch (Überschneidung/Pufferzeit im
// selben Raum, Abschnitt 4) — bei Konflikt wird 409 zurückgegeben und
// NICHTS geschrieben. Unbekannte Musiker-Kürzel werden automatisch
// angelegt (Annahme, siehe PROGRESS.md "Offene Fragen").
// Reiner Prüf-Endpunkt ohne Nebenwirkungen, damit admin.html das
// Organisator:innen-Passwort direkt BEIM LADEN prüfen kann statt erst
// beim ersten Speichern-Versuch (Rafi-Feedback, 07.09.2026). Nutzt
// dieselbe Middleware wie die Schreib-Routen -- 401 bei falschem/
// fehlendem Passwort, sonst 200 ohne Datenzugriff.
app.get('/api/auth/pruefen', pruefeOrganisatorAuth, (req, res) => {
  res.json({ status: 'ok' });
});

app.post('/api/termine', pruefeOrganisatorAuth, async (req, res) => {
  if (!pool) {
    return res.status(503).json({ status: 'error', message: 'DATABASE_URL nicht gesetzt' });
  }

  const { value, errors } = parseTerminInput(req.body);
  if (errors) {
    return res.status(400).json({ status: 'error', message: 'Ungültige Eingabe', errors });
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const saison = await resolveSaison(client, req.query.saison);
    if (!saison) {
      await client.query('ROLLBACK');
      return res.status(400).json({ status: 'error', message: 'Unbekannte Saison oder keine Saison aktiv' });
    }
    if (!saison.aktiv) {
      await client.query('ROLLBACK');
      return saisonArchiviertFehler(res, saison.jahr);
    }

    const pruefung = await pruefeKonflikte(client, value, null, saison.id);
    if (pruefung.raumUnbekannt) {
      await client.query('ROLLBACK');
      return res.status(400).json({ status: 'error', message: `Unbekannte raumId: ${value.raumId}` });
    }
    if (pruefung.konflikte.length) {
      await client.query('ROLLBACK');
      return res.status(409).json({ status: 'error', message: 'Terminkonflikt', konflikte: pruefung.konflikte });
    }

    const insertResult = await client.query(INSERT_TERMIN_SQL, [
      value.wochentag,
      value.datum,
      value.anfangszeit,
      value.endzeit,
      value.raumId,
      value.typ,
      value.werk,
      value.bemerkungen,
      saison.id,
    ]);
    const terminId = insertResult.rows[0].id;

    await setzeTeilnehmer(client, terminId, value.teilnehmer, saison.id);

    await client.query('COMMIT');

    const neuerTerminResult = await client.query(SELECT_TERMIN_BY_ID_SQL, [terminId]);
    res.status(201).json({ termin: groupTermineRows(neuerTerminResult.rows)[0] });
  } catch (err) {
    await client.query('ROLLBACK');
    if (err.code === '23503') {
      // foreign_key_violation — z.B. raumId existiert nicht.
      return res.status(400).json({ status: 'error', message: `Unbekannte raumId: ${err.detail || err.message}` });
    }
    res.status(500).json({ status: 'error', message: err.message });
  } finally {
    client.release();
  }
});

// PUT /api/termine/:id — ersetzt einen bestehenden Termin komplett
// (gleicher Body wie POST). Konfliktprüfung schliesst den eigenen
// Termin aus (sonst würde er sich ständig mit sich selbst
// überschneiden). 404 falls die ID nicht existiert.
app.put('/api/termine/:id', pruefeOrganisatorAuth, async (req, res) => {
  if (!pool) {
    return res.status(503).json({ status: 'error', message: 'DATABASE_URL nicht gesetzt' });
  }
  const id = Number(req.params.id);
  if (!Number.isInteger(id) || id <= 0) {
    return res.status(400).json({ status: 'error', message: 'Ungültige Termin-ID in der URL' });
  }

  const { value, errors } = parseTerminInput(req.body);
  if (errors) {
    return res.status(400).json({ status: 'error', message: 'Ungültige Eingabe', errors });
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Die Saison eines bestehenden Termins ist fix (ein Termin wechselt
    // nie die Saison) -- deshalb hier NICHT aus ?saison= auflösen,
    // sondern direkt vom Termin selbst ablesen. 404, falls die ID gar
    // nicht existiert; 403, falls seine Saison archiviert ist.
    const terminSaisonResult = await client.query(SELECT_TERMIN_SAISON_SQL, [id]);
    const terminSaison = terminSaisonResult.rows[0];
    if (!terminSaison) {
      await client.query('ROLLBACK');
      return res.status(404).json({ status: 'error', message: `Termin #${id} nicht gefunden` });
    }
    if (!terminSaison.aktiv) {
      await client.query('ROLLBACK');
      return saisonArchiviertFehler(res);
    }

    const pruefung = await pruefeKonflikte(client, value, id, terminSaison.saison_id);
    if (pruefung.raumUnbekannt) {
      await client.query('ROLLBACK');
      return res.status(400).json({ status: 'error', message: `Unbekannte raumId: ${value.raumId}` });
    }
    if (pruefung.konflikte.length) {
      await client.query('ROLLBACK');
      return res.status(409).json({ status: 'error', message: 'Terminkonflikt', konflikte: pruefung.konflikte });
    }

    const updateResult = await client.query(UPDATE_TERMIN_SQL, [
      value.wochentag,
      value.datum,
      value.anfangszeit,
      value.endzeit,
      value.raumId,
      value.typ,
      value.werk,
      value.bemerkungen,
      id,
    ]);
    if (updateResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ status: 'error', message: `Termin #${id} nicht gefunden` });
    }

    await setzeTeilnehmer(client, id, value.teilnehmer, terminSaison.saison_id);

    await client.query('COMMIT');

    const aktualisierterTerminResult = await client.query(SELECT_TERMIN_BY_ID_SQL, [id]);
    res.json({ termin: groupTermineRows(aktualisierterTerminResult.rows)[0] });
  } catch (err) {
    await client.query('ROLLBACK');
    if (err.code === '23503') {
      return res.status(400).json({ status: 'error', message: `Unbekannte raumId: ${err.detail || err.message}` });
    }
    res.status(500).json({ status: 'error', message: err.message });
  } finally {
    client.release();
  }
});

// DELETE /api/termine/:id — löscht einen Termin (termin_musiker-Zeilen
// verschwinden automatisch per ON DELETE CASCADE). 404 falls die ID
// nicht existiert.
app.delete('/api/termine/:id', pruefeOrganisatorAuth, async (req, res) => {
  if (!pool) {
    return res.status(503).json({ status: 'error', message: 'DATABASE_URL nicht gesetzt' });
  }
  const id = Number(req.params.id);
  if (!Number.isInteger(id) || id <= 0) {
    return res.status(400).json({ status: 'error', message: 'Ungültige Termin-ID in der URL' });
  }

  try {
    const terminSaisonResult = await pool.query(SELECT_TERMIN_SAISON_SQL, [id]);
    const terminSaison = terminSaisonResult.rows[0];
    if (!terminSaison) {
      return res.status(404).json({ status: 'error', message: `Termin #${id} nicht gefunden` });
    }
    if (!terminSaison.aktiv) {
      return saisonArchiviertFehler(res);
    }

    const result = await pool.query(DELETE_TERMIN_SQL, [id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ status: 'error', message: `Termin #${id} nicht gefunden` });
    }
    res.status(204).end();
  } catch (err) {
    res.status(500).json({ status: 'error', message: err.message });
  }
});

// GET /api/stand — aktueller Sperr-Zeitpunkt (REFERENCE.md Abschnitt 5).
// lockedAt=null bedeutet: noch nie gesperrt, dann gilt kein Termin als
// "neu/geändert" (siehe SELECT_TERMINE_SQL).
app.get('/api/stand', async (req, res) => {
  if (!pool) {
    return res.status(503).json({ status: 'error', message: 'DATABASE_URL nicht gesetzt' });
  }
  const saison = await resolveSaison(pool, req.query.saison);
  if (!saison) {
    return res.status(400).json({ status: 'error', message: 'Unbekannte Saison oder keine Saison aktiv' });
  }
  try {
    const result = await pool.query(SELECT_LOCKED_AT_SQL, [saison.id]);
    res.json({ lockedAt: result.rows[0]?.wert ?? null });
  } catch (err) {
    res.status(500).json({ status: 'error', message: err.message });
  }
});

// POST /api/stand/sperren — setzt den aktuellen Zeitpunkt als neuen
// Sperr-Stand DER GEWÄHLTEN SAISON (Standard: aktive Saison). Ab jetzt
// gilt jeder bereits bestehende Termin dieser Saison als "alt" (nicht
// mehr "neu"), bis er wieder geändert wird. Auf einer archivierten
// Saison bewusst nicht mehr möglich (dort ändert sich ohnehin nichts
// mehr).
app.post('/api/stand/sperren', pruefeOrganisatorAuth, async (req, res) => {
  if (!pool) {
    return res.status(503).json({ status: 'error', message: 'DATABASE_URL nicht gesetzt' });
  }
  const saison = await resolveSaison(pool, req.query.saison);
  if (!saison) {
    return res.status(400).json({ status: 'error', message: 'Unbekannte Saison oder keine Saison aktiv' });
  }
  if (!saison.aktiv) {
    return saisonArchiviertFehler(res, saison.jahr);
  }
  try {
    const result = await pool.query(SPERREN_SQL, [saison.id]);
    res.json({ lockedAt: result.rows[0].wert });
  } catch (err) {
    res.status(500).json({ status: 'error', message: err.message });
  }
});

// GET /api/pdf/gesamtplan?datum=YYYY-MM-DD — "Gesamtplan"-PDF für einen
// Tag (Phase 6, REFERENCE.md Abschnitt 7): alle Räume, farbige Kästchen
// wie in der Web-Ansicht, überlappende Termine nebeneinander ("Lanes").
// `datum` ist Pflicht (im Unterschied zu GET /api/termine) — ein PDF
// über alle Tage hinweg ergibt für diese Ansicht keinen Sinn.
app.get('/api/pdf/gesamtplan', async (req, res) => {
  if (!pool) {
    return res.status(503).json({ status: 'error', message: 'DATABASE_URL nicht gesetzt' });
  }
  const datum = req.query.datum;
  if (!datum) {
    return res.status(400).json({ status: 'error', message: 'Query-Parameter datum ist Pflicht (YYYY-MM-DD)' });
  }
  const saison = await resolveSaison(pool, req.query.saison);
  if (!saison) {
    return res.status(400).json({ status: 'error', message: 'Unbekannte Saison oder keine Saison aktiv' });
  }
  try {
    const result = await pool.query(SELECT_TERMINE_SQL, [datum, null, saison.id]);
    const termine = groupTermineRows(result.rows);
    const wochentag = termine[0]?.wochentag;
    const pdfBuffer = await erzeugeGesamtplanPdf({ datum, wochentag, termine });
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `inline; filename="gesamtplan-${formatiereDatum(datum)}.pdf"`);
    res.send(pdfBuffer);
  } catch (err) {
    res.status(500).json({ status: 'error', message: err.message });
  }
});

// GET /api/pdf/musikerplan?datum=YYYY-MM-DD&kuerzel=AB — individueller
// Musikerplan (Phase 6, REFERENCE.md Abschnitt 7): nur die eigenen
// Termine plus Kzt-Blöcke (REFERENCE.md Abschnitt 3). Beide
// Query-Parameter sind Pflicht.
app.get('/api/pdf/musikerplan', async (req, res) => {
  if (!pool) {
    return res.status(503).json({ status: 'error', message: 'DATABASE_URL nicht gesetzt' });
  }
  const datum = req.query.datum;
  const kuerzel = req.query.kuerzel;
  if (!datum || !kuerzel) {
    return res
      .status(400)
      .json({ status: 'error', message: 'Query-Parameter datum UND kuerzel sind Pflicht' });
  }
  const saison = await resolveSaison(pool, req.query.saison);
  if (!saison) {
    return res.status(400).json({ status: 'error', message: 'Unbekannte Saison oder keine Saison aktiv' });
  }
  try {
    const result = await pool.query(SELECT_TERMINE_SQL, [datum, null, saison.id]);
    const termine = groupTermineRows(result.rows);
    const wochentag = termine[0]?.wochentag;
    const pdfBuffer = await erzeugeMusikerplanPdf({ datum, wochentag, kuerzel, termine });
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader(
      'Content-Disposition',
      `inline; filename="musikerplan-${kuerzel}-${formatiereDatum(datum)}.pdf"`
    );
    res.send(pdfBuffer);
  } catch (err) {
    res.status(500).json({ status: 'error', message: err.message });
  }
});

// `app` exportieren, damit server/test/index.test.js echte HTTP-Requests
// gegen eine im Test gestartete Instanz schicken kann (statt nur Mocks),
// ohne dass beim einfachen `require('./index')` gleich ein echter Port
// belegt wird. Im Produktivbetrieb (`node index.js`) bleibt das
// Verhalten unverändert.
if (require.main === module) {
  app.listen(port, () => {
    console.log(`zwt-probeplan-server (Platzhalter) läuft auf Port ${port}`);
  });
}

module.exports = app;
