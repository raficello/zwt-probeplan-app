'use strict';

// Server: Health-Checks (Phase 2), Terminverwaltungs-API (Phase 3,
// siehe REFERENCE.md Abschnitt 1/3/4) + Raumplan-Ansicht (Phase 4,
// siehe REFERENCE.md Abschnitt 6).

const path = require('path');
const express = require('express');
const { Pool } = require('pg');
const {
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
  SPERREN_SQL,
  SELECT_LOCKED_AT_SQL,
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

// Statische Dateien: eigene Seiten (public/) + vis-timeline-Bibliothek
// direkt aus node_modules ausgeliefert (kein CDN nötig, funktioniert
// auch ohne Internetzugang am Aufführungsort — nur der Browser der
// Besucher:innen muss den Server erreichen).
app.use(express.static(path.join(__dirname, 'public')));
app.use('/vendor/vis-timeline', express.static(path.join(__dirname, 'node_modules/vis-timeline')));
app.get('/favicon.ico', (req, res) => res.status(204).end());

// Gemeinsame Konfliktprüfung für POST (excludeId=null) und PUT
// (excludeId=eigene ID, siehe REFERENCE.md Abschnitt 4). Muss innerhalb
// der aufrufenden Transaktion (client) laufen, damit Prüfung und
// Schreiben konsistent sind. Prüft ZWEI Dinge: dass die raumId
// existiert (sonst { raumUnbekannt: true }, damit der Aufrufer VOR dem
// Schreiben sauber 400 antworten kann statt sich auf den
// Foreign-Key-Fehler beim INSERT zu verlassen), und — als Teil der
// zurückgegebenen konflikte-Liste — sowohl die Wochentags-Raumbeschränkung
// (REFERENCE.md Abschnitt 2, bisher NICHT umgesetzt gewesen, siehe
// PROGRESS.md) als auch Überschneidungen/Pufferzeiten.
async function pruefeKonflikte(client, value, excludeId) {
  const raumResult = await client.query(SELECT_RAUM_SQL, [value.raumId]);
  const raum = raumResult.rows[0];
  if (!raum) {
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
// und legt dabei unbekannte Musiker-Kürzel automatisch an.
async function setzeTeilnehmer(client, terminId, kuerzelListe) {
  await client.query(DELETE_TERMIN_MUSIKER_SQL, [terminId]);
  for (const kuerzel of kuerzelListe) {
    const musikerResult = await client.query(UPSERT_MUSIKER_SQL, [kuerzel]);
    await client.query(INSERT_TERMIN_MUSIKER_SQL, [terminId, musikerResult.rows[0].id]);
  }
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

// GET /api/termine?datum=YYYY-MM-DD  ODER  ?wochentag=Mo  (beides optional,
// ohne Filter werden alle Termine aller Tage geliefert). Bewusst nur
// Lesen — der kleinstmögliche erste Schritt für Phase 3 (siehe
// PROGRESS.md). Schreiboperationen (POST/PUT/DELETE) folgen später.
app.get('/api/termine', async (req, res) => {
  if (!pool) {
    return res.status(503).json({ status: 'error', message: 'DATABASE_URL nicht gesetzt' });
  }
  const datum = req.query.datum || null;
  const wochentag = req.query.wochentag || null;
  try {
    const result = await pool.query(SELECT_TERMINE_SQL, [datum, wochentag]);
    res.json({ termine: groupTermineRows(result.rows) });
  } catch (err) {
    res.status(500).json({ status: 'error', message: err.message });
  }
});

// GET /api/raeume — ALLE Räume, auch ohne Termin an einem bestimmten
// Tag (im Unterschied zu GET /api/termine, das Räume nur implizit über
// vorhandene Termine liefert). Offen, kein Auth nötig (Lesen). Grundlage
// für die Raum-Auswahl in der Terminverwaltung (Phase 8) — vorher gab
// es dafür keinen Endpunkt (siehe PROGRESS.md "Bekannte Einschränkung").
app.get('/api/raeume', async (req, res) => {
  if (!pool) {
    return res.status(503).json({ status: 'error', message: 'DATABASE_URL nicht gesetzt' });
  }
  try {
    const result = await pool.query(SELECT_RAEUME_SQL);
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

// POST /api/termine — legt einen neuen Termin an (siehe REFERENCE.md
// Abschnitt 1/3/4). Erwartet JSON-Body: { wochentag, datum, anfangszeit,
// endzeit, raumId, typ, werk, bemerkungen, teilnehmer }. Führt VOR dem
// Anlegen die Konfliktprüfung durch (Überschneidung/Pufferzeit im
// selben Raum, Abschnitt 4) — bei Konflikt wird 409 zurückgegeben und
// NICHTS geschrieben. Unbekannte Musiker-Kürzel werden automatisch
// angelegt (Annahme, siehe PROGRESS.md "Offene Fragen").
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

    const pruefung = await pruefeKonflikte(client, value, null);
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
    ]);
    const terminId = insertResult.rows[0].id;

    await setzeTeilnehmer(client, terminId, value.teilnehmer);

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

    const pruefung = await pruefeKonflikte(client, value, id);
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

    await setzeTeilnehmer(client, id, value.teilnehmer);

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
  try {
    const result = await pool.query(SELECT_LOCKED_AT_SQL);
    res.json({ lockedAt: result.rows[0]?.wert ?? null });
  } catch (err) {
    res.status(500).json({ status: 'error', message: err.message });
  }
});

// POST /api/stand/sperren — setzt den aktuellen Zeitpunkt als neuen
// Sperr-Stand. Ab jetzt gilt jeder bereits bestehende Termin als
// "alt" (nicht mehr "neu"), bis er wieder geändert wird.
app.post('/api/stand/sperren', pruefeOrganisatorAuth, async (req, res) => {
  if (!pool) {
    return res.status(503).json({ status: 'error', message: 'DATABASE_URL nicht gesetzt' });
  }
  try {
    const result = await pool.query(SPERREN_SQL);
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
  try {
    const result = await pool.query(SELECT_TERMINE_SQL, [datum, null]);
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
  try {
    const result = await pool.query(SELECT_TERMINE_SQL, [datum, null]);
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
