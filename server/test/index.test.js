'use strict';

// Echte End-to-End-Tests für die Termin-API (server/index.js) gegen ein
// echtes lokales Postgres — bisher gab es dafür KEINE automatisierten
// Tests (nur manuelles Testen per curl auf dem VPS), obwohl genau hier
// (Konfliktprüfung, Wochentags-Raumbeschränkung, Transaktionen) die Art
// von Bugs auftrat, die reine Unit-Tests mit Mock-Daten in dieser
// Sitzung wiederholt übersehen haben (siehe REFERENCE.md Abschnitt 13).
//
// Voraussetzung: eine erreichbare Postgres-Instanz, Verbindung über
// process.env.DATABASE_URL (Default: lokale Test-DB "zwt_test").
// Existiert keine erreichbare DB, werden die Tests übersprungen statt
// rot zu schlagen (z.B. im Docker-Image, wo kein Postgres mitläuft).

const test = require('node:test');
const assert = require('node:assert/strict');
const { Pool } = require('pg');

const DATABASE_URL =
  process.env.TEST_DATABASE_URL || 'postgres://postgres:postgres@localhost:5432/zwt_test';

process.env.DATABASE_URL = DATABASE_URL;
process.env.ORGANISATOR_BENUTZER = 'organisator';
process.env.ORGANISATOR_PASSWORT = 'testpasswort';

function authHeader(benutzer, passwort) {
  return 'Basic ' + Buffer.from(`${benutzer}:${passwort}`, 'utf8').toString('base64');
}
const ORG_AUTH = authHeader('organisator', 'testpasswort');

let pool;
let server;
let baseUrl;
let dbErreichbar = true;

test.before(async () => {
  pool = new Pool({ connectionString: DATABASE_URL });
  try {
    await pool.query('SELECT 1');
  } catch (err) {
    dbErreichbar = false;
    return;
  }

  const app = require('../index');
  server = app.listen(0);
  await new Promise((resolve) => server.once('listening', resolve));
  baseUrl = `http://127.0.0.1:${server.address().port}`;
});

test.after(async () => {
  if (server) await new Promise((resolve) => server.close(resolve));
  if (pool) await pool.end();
});

// Vor jedem Test: sauberer Zustand + zwei Räume — einer ohne
// Wochentags-Beschränkung, einer NUR für Mo/Mi/Fr (Grundlage für die
// Beschränkungs-Tests unten).
async function frischerZustand() {
  await pool.query('TRUNCATE termine, termin_musiker, musiker, raeume, konfiguration RESTART IDENTITY CASCADE');
  const kursaal = await pool.query(
    `INSERT INTO raeume (name, aud_code, erlaubte_tage) VALUES ('Kursaal', '802', NULL) RETURNING id`
  );
  const kgh = await pool.query(
    `INSERT INTO raeume (name, aud_code, erlaubte_tage) VALUES ('Kirchgemeindehaus', '604', ARRAY['Mo','Mi','Fr']) RETURNING id`
  );
  return { kursaalId: kursaal.rows[0].id, kghId: kgh.rows[0].id };
}

function terminBody(overrides) {
  return {
    wochentag: 'Mo',
    datum: '2026-09-07', // ein Montag
    anfangszeit: '09:00',
    endzeit: '10:00',
    typ: '',
    werk: 'Testprobe',
    teilnehmer: ['AB'],
    ...overrides,
  };
}

test('GET /api/raeume: liefert ALLE Räume, auch ohne Termin, inkl. erlaubteTage', async (t) => {
  if (!dbErreichbar) return t.skip('Keine erreichbare Postgres-Instanz');
  const { kursaalId, kghId } = await frischerZustand();

  const res = await fetch(`${baseUrl}/api/raeume`);
  assert.equal(res.status, 200);
  const body = await res.json();
  assert.equal(body.raeume.length, 2);
  const kgh = body.raeume.find((r) => r.id === kghId);
  const kursaal = body.raeume.find((r) => r.id === kursaalId);
  assert.deepEqual(kgh.erlaubteTage, ['Mo', 'Mi', 'Fr']);
  assert.deepEqual(kursaal.erlaubteTage, []);
});

test('POST /api/termine: ohne Auth-Header -> 401, nichts wird angelegt', async (t) => {
  if (!dbErreichbar) return t.skip('Keine erreichbare Postgres-Instanz');
  const { kursaalId } = await frischerZustand();

  const res = await fetch(`${baseUrl}/api/termine`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(terminBody({ raumId: kursaalId })),
  });
  assert.equal(res.status, 401);

  const check = await pool.query('SELECT count(*) FROM termine');
  assert.equal(Number(check.rows[0].count), 0);
});

test('POST /api/termine: unbekannte raumId -> 400 VOR dem Schreiben (kein Foreign-Key-Absturz)', async (t) => {
  if (!dbErreichbar) return t.skip('Keine erreichbare Postgres-Instanz');
  await frischerZustand();

  const res = await fetch(`${baseUrl}/api/termine`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: ORG_AUTH },
    body: JSON.stringify(terminBody({ raumId: 999999 })),
  });
  assert.equal(res.status, 400);
  const body = await res.json();
  assert.match(body.message, /Unbekannte raumId/);
});

test('POST /api/termine: Raum mit Wochentags-Beschränkung an erlaubtem Tag -> 201', async (t) => {
  if (!dbErreichbar) return t.skip('Keine erreichbare Postgres-Instanz');
  const { kghId } = await frischerZustand();

  // 2026-09-07 ist ein Montag, KGH erlaubt Mo/Mi/Fr -> sollte klappen.
  const res = await fetch(`${baseUrl}/api/termine`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: ORG_AUTH },
    body: JSON.stringify(terminBody({ raumId: kghId, wochentag: 'Mo', datum: '2026-09-07' })),
  });
  assert.equal(res.status, 201);
  const body = await res.json();
  assert.equal(body.termin.raum.name, 'Kirchgemeindehaus');
});

test('POST /api/termine: Raum mit Wochentags-Beschränkung an NICHT erlaubtem Tag -> 409 mit erklärender Meldung (REGRESSIONSTEST — diese Prüfung fehlte komplett, siehe REFERENCE.md)', async (t) => {
  if (!dbErreichbar) return t.skip('Keine erreichbare Postgres-Instanz');
  const { kghId } = await frischerZustand();

  // 2026-09-10 ist ein Donnerstag, KGH erlaubt nur Mo/Mi/Fr -> muss scheitern.
  const res = await fetch(`${baseUrl}/api/termine`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: ORG_AUTH },
    body: JSON.stringify(terminBody({ raumId: kghId, wochentag: 'Do', datum: '2026-09-10' })),
  });
  assert.equal(res.status, 409);
  const body = await res.json();
  assert.ok(body.konflikte.some((k) => k.includes('nicht erlaubt')));

  const check = await pool.query('SELECT count(*) FROM termine');
  assert.equal(Number(check.rows[0].count), 0);
});

test('POST /api/termine: Raum ohne Beschränkung erlaubt jeden Wochentag', async (t) => {
  if (!dbErreichbar) return t.skip('Keine erreichbare Postgres-Instanz');
  const { kursaalId } = await frischerZustand();

  const res = await fetch(`${baseUrl}/api/termine`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: ORG_AUTH },
    body: JSON.stringify(terminBody({ raumId: kursaalId, wochentag: 'Do', datum: '2026-09-10' })),
  });
  assert.equal(res.status, 201);
});

test('PUT /api/termine/:id: Verschieben in einen an diesem Tag nicht erlaubten Raum -> 409, alter Termin bleibt unverändert', async (t) => {
  if (!dbErreichbar) return t.skip('Keine erreichbare Postgres-Instanz');
  const { kursaalId, kghId } = await frischerZustand();

  const angelegt = await fetch(`${baseUrl}/api/termine`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: ORG_AUTH },
    body: JSON.stringify(terminBody({ raumId: kursaalId, wochentag: 'Do', datum: '2026-09-10' })),
  });
  const { termin } = await angelegt.json();

  const res = await fetch(`${baseUrl}/api/termine/${termin.id}`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json', Authorization: ORG_AUTH },
    body: JSON.stringify(terminBody({ raumId: kghId, wochentag: 'Do', datum: '2026-09-10' })),
  });
  assert.equal(res.status, 409);

  const nochDa = await pool.query('SELECT raum_id FROM termine WHERE id = $1', [termin.id]);
  assert.equal(nochDa.rows[0].raum_id, kursaalId);
});

test('Vollständiger CRUD-Durchlauf: anlegen, lesen, ändern, löschen', async (t) => {
  if (!dbErreichbar) return t.skip('Keine erreichbare Postgres-Instanz');
  const { kursaalId } = await frischerZustand();

  const angelegt = await fetch(`${baseUrl}/api/termine`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: ORG_AUTH },
    body: JSON.stringify(terminBody({ raumId: kursaalId })),
  });
  assert.equal(angelegt.status, 201);
  const { termin } = await angelegt.json();

  const gelesen = await fetch(`${baseUrl}/api/termine?datum=2026-09-07`);
  const gelistet = (await gelesen.json()).termine;
  assert.equal(gelistet.length, 1);
  assert.deepEqual(gelistet[0].teilnehmer, ['AB']);

  const geaendert = await fetch(`${baseUrl}/api/termine/${termin.id}`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json', Authorization: ORG_AUTH },
    body: JSON.stringify(terminBody({ raumId: kursaalId, werk: 'Geänderte Probe', teilnehmer: ['AB', 'CD'] })),
  });
  assert.equal(geaendert.status, 200);
  assert.deepEqual((await geaendert.json()).termin.teilnehmer, ['AB', 'CD']);

  const geloescht = await fetch(`${baseUrl}/api/termine/${termin.id}`, {
    method: 'DELETE',
    headers: { Authorization: ORG_AUTH },
  });
  assert.equal(geloescht.status, 204);

  const nachLoeschen = await fetch(`${baseUrl}/api/termine?datum=2026-09-07`);
  assert.deepEqual((await nachLoeschen.json()).termine, []);
});
