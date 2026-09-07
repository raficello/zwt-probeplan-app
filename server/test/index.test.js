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

  // Seit der Saison-Verwaltung (07.09.2026, siehe REFERENCE.md
  // "Saison-Verwaltung") braucht JEDE Route eine aktive Saison -- ohne
  // ?saison=<Jahr> im Request wird automatisch die aktive verwendet
  // (resolveSaison in index.js). Diese Test-DB muss db/schema.sql,
  // db/migration-werke.sql, db/migration-saisons.sql UND
  // db/migration-benutzer.sql (für die Benutzer-CRUD-Tests unten)
  // bereits angewendet haben (wie bisher schon für die Basistabellen
  // vorausgesetzt) -- hier wird nur EINE Test-Saison aktiviert, damit
  // alle bestehenden fetch()-Aufrufe ohne den neuen Parameter
  // weiterlaufen.
  await pool.query('UPDATE saisons SET aktiv = false');
  await pool.query(
    `INSERT INTO saisons (jahr, bezeichnung, aktiv) VALUES (2091, 'Test-Saison', true)
     ON CONFLICT (jahr) DO UPDATE SET aktiv = true`
  );

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
    `INSERT INTO raeume (name, aud_code, erlaubte_tage, saison_id)
     VALUES ('Kursaal', '802', NULL, (SELECT id FROM saisons WHERE jahr = 2091)) RETURNING id`
  );
  const kgh = await pool.query(
    `INSERT INTO raeume (name, aud_code, erlaubte_tage, saison_id)
     VALUES ('Kirchgemeindehaus', '604', ARRAY['Mo','Mi','Fr'], (SELECT id FROM saisons WHERE jahr = 2091)) RETURNING id`
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

// Saison-Verwaltung (Rafi-Feedback, 07.09.2026, siehe REFERENCE.md
// "Saison-Verwaltung"): eigene Test-Gruppe, damit die Archiv-Tests den
// globalen "aktive Saison"-Zustand am Ende IMMER wieder auf die
// Test-Saison 2091 zurücksetzen (frischerZustand() verlässt sich
// darauf, dass 2091 aktiv ist).

test('GET /api/saisons: listet Saisons, neueste zuerst', async (t) => {
  if (!dbErreichbar) return t.skip('Keine erreichbare Postgres-Instanz');
  const res = await fetch(`${baseUrl}/api/saisons`);
  assert.equal(res.status, 200);
  const body = await res.json();
  const testSaison = body.saisons.find((s) => s.jahr === 2091);
  assert.ok(testSaison);
  assert.equal(testSaison.aktiv, true);
});

test('POST /api/saisons: legt neue Saison an, NICHT automatisch aktiv', async (t) => {
  if (!dbErreichbar) return t.skip('Keine erreichbare Postgres-Instanz');
  await pool.query('DELETE FROM saisons WHERE jahr = 2092');

  const res = await fetch(`${baseUrl}/api/saisons`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: ORG_AUTH },
    body: JSON.stringify({ jahr: 2092, bezeichnung: 'ZwT 2092 (Test)' }),
  });
  assert.equal(res.status, 201);
  const body = await res.json();
  assert.equal(body.saison.jahr, 2092);
  assert.equal(body.saison.aktiv, false);

  // 2091 muss weiterhin die aktive Saison sein -- Anlegen einer neuen
  // Saison darf die laufende NICHT einfrieren (siehe queries.js
  // AKTIVIERE_SAISON_SQL-Kommentar).
  const aktiveNoch = await pool.query('SELECT jahr FROM saisons WHERE aktiv = true');
  assert.equal(aktiveNoch.rows[0].jahr, 2091);

  await pool.query('DELETE FROM saisons WHERE jahr = 2092');
});

test('POST /api/saisons: doppeltes Jahr -> 400 statt 500', async (t) => {
  if (!dbErreichbar) return t.skip('Keine erreichbare Postgres-Instanz');
  const res = await fetch(`${baseUrl}/api/saisons`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: ORG_AUTH },
    body: JSON.stringify({ jahr: 2091, bezeichnung: 'Doppelt' }),
  });
  assert.equal(res.status, 400);
});

test('POST /api/saisons: ohne Auth-Header -> 401', async (t) => {
  if (!dbErreichbar) return t.skip('Keine erreichbare Postgres-Instanz');
  const res = await fetch(`${baseUrl}/api/saisons`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ jahr: 2094, bezeichnung: 'Ohne Auth' }),
  });
  assert.equal(res.status, 401);
});

test('GET /api/termine: unbekanntes ?saison= -> 400', async (t) => {
  if (!dbErreichbar) return t.skip('Keine erreichbare Postgres-Instanz');
  await frischerZustand();
  const res = await fetch(`${baseUrl}/api/termine?saison=1234`);
  assert.equal(res.status, 400);
});

test('Saison-Aktivierung + Archiv-Schreibsperre: archivierte Saison kann nicht mehr bearbeitet werden, aber weiterhin gelesen', async (t) => {
  if (!dbErreichbar) return t.skip('Keine erreichbare Postgres-Instanz');
  const { kursaalId } = await frischerZustand();

  // Termin in der (noch aktiven) Test-Saison 2091 anlegen.
  const angelegt = await fetch(`${baseUrl}/api/termine`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: ORG_AUTH },
    body: JSON.stringify(terminBody({ raumId: kursaalId })),
  });
  assert.equal(angelegt.status, 201);
  const { termin } = await angelegt.json();

  // Zweite Saison anlegen und aktivieren -- 2091 wird dadurch automatisch
  // zum Archiv (siehe AKTIVIERE_SAISON_SQL).
  await pool.query('DELETE FROM saisons WHERE jahr = 2093');
  await fetch(`${baseUrl}/api/saisons`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: ORG_AUTH },
    body: JSON.stringify({ jahr: 2093, bezeichnung: 'ZwT 2093 (Test)' }),
  });
  const aktivierung = await fetch(`${baseUrl}/api/saisons/2093/aktivieren`, {
    method: 'POST',
    headers: { Authorization: ORG_AUTH },
  });
  assert.equal(aktivierung.status, 200);

  try {
    // Lesen des alten Termins (explizit ?saison=2091) funktioniert weiterhin.
    const gelesen = await fetch(`${baseUrl}/api/termine?saison=2091&datum=2026-09-07`);
    assert.equal(gelesen.status, 200);
    assert.equal((await gelesen.json()).termine.length, 1);

    // Ändern/Löschen ist jetzt gesperrt (403), nicht mehr 200/204.
    const geaendert = await fetch(`${baseUrl}/api/termine/${termin.id}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json', Authorization: ORG_AUTH },
      body: JSON.stringify(terminBody({ raumId: kursaalId, werk: 'Sollte scheitern' })),
    });
    assert.equal(geaendert.status, 403);

    const geloescht = await fetch(`${baseUrl}/api/termine/${termin.id}`, {
      method: 'DELETE',
      headers: { Authorization: ORG_AUTH },
    });
    assert.equal(geloescht.status, 403);

    // Neuanlegen IN der archivierten Saison (explizit ?saison=2091) ist
    // ebenfalls gesperrt.
    const neuerVersuch = await fetch(`${baseUrl}/api/termine?saison=2091`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: ORG_AUTH },
      body: JSON.stringify(terminBody({ raumId: kursaalId })),
    });
    assert.equal(neuerVersuch.status, 403);
  } finally {
    // WICHTIG: globalen Zustand für alle nachfolgenden Tests zurücksetzen
    // (frischerZustand() geht von 2091=aktiv aus).
    // Zwei getrennte Anweisungen (nicht eine einzelne "SET aktiv =
    // (jahr = 2091)") -- siehe Kommentar bei AKTIVIERE_SAISON_SQL in
    // queries.js, dieselbe Falle wurde hier beim ersten Testlauf real
    // ausgelöst (Unique-Index-Verletzung je nach Zeilen-Reihenfolge).
    await pool.query('UPDATE saisons SET aktiv = false WHERE aktiv = true');
    await pool.query('UPDATE saisons SET aktiv = true WHERE jahr = 2091');
    await pool.query('DELETE FROM saisons WHERE jahr = 2093');
  }
});

// Stammdaten-CRUD (Rafi-Feedback, 07.09.2026: "Raumliste, Musikerliste,
// Konzertliste, Werkeliste steuern"). Läuft in der Test-Saison 2091
// (siehe test.before oben).

test('Räume-CRUD: anlegen, ändern, löschen', async (t) => {
  if (!dbErreichbar) return t.skip('Keine erreichbare Postgres-Instanz');
  await frischerZustand();

  const angelegt = await fetch(`${baseUrl}/api/raeume`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: ORG_AUTH },
    body: JSON.stringify({ name: 'Testraum', erlaubteTage: ['Mo', 'Fr'] }),
  });
  assert.equal(angelegt.status, 201);
  const { raum } = await angelegt.json();
  assert.equal(raum.name, 'Testraum');
  assert.deepEqual(raum.erlaubteTage, ['Mo', 'Fr']);

  const geaendert = await fetch(`${baseUrl}/api/raeume/${raum.id}`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json', Authorization: ORG_AUTH },
    body: JSON.stringify({ name: 'Testraum umbenannt', erlaubteTage: [] }),
  });
  assert.equal(geaendert.status, 200);
  assert.equal((await geaendert.json()).raum.name, 'Testraum umbenannt');

  const geloescht = await fetch(`${baseUrl}/api/raeume/${raum.id}`, { method: 'DELETE', headers: { Authorization: ORG_AUTH } });
  assert.equal(geloescht.status, 204);
});

test('Räume-CRUD: Löschen mit bestehendem Termin -> 409, nicht gelöscht', async (t) => {
  if (!dbErreichbar) return t.skip('Keine erreichbare Postgres-Instanz');
  const { kursaalId } = await frischerZustand();

  const angelegt = await fetch(`${baseUrl}/api/termine`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: ORG_AUTH },
    body: JSON.stringify(terminBody({ raumId: kursaalId })),
  });
  assert.equal(angelegt.status, 201);

  const res = await fetch(`${baseUrl}/api/raeume/${kursaalId}`, { method: 'DELETE', headers: { Authorization: ORG_AUTH } });
  assert.equal(res.status, 409);

  const nochDa = await pool.query('SELECT id FROM raeume WHERE id = $1', [kursaalId]);
  assert.equal(nochDa.rows.length, 1);
});

test('Musiker-CRUD: anlegen, ändern, löschen', async (t) => {
  if (!dbErreichbar) return t.skip('Keine erreichbare Postgres-Instanz');
  await frischerZustand();

  const angelegt = await fetch(`${baseUrl}/api/musiker`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: ORG_AUTH },
    body: JSON.stringify({ kuerzel: 'ZZ', name: 'Zora Zeugin' }),
  });
  assert.equal(angelegt.status, 201);
  const { musiker } = await angelegt.json();
  assert.equal(musiker.kuerzel, 'ZZ');
  assert.equal(musiker.name, 'Zora Zeugin');

  const geaendert = await fetch(`${baseUrl}/api/musiker/${musiker.id}`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json', Authorization: ORG_AUTH },
    body: JSON.stringify({ kuerzel: 'ZZ', name: 'Zora Zeugin-Neu' }),
  });
  assert.equal(geaendert.status, 200);
  assert.equal((await geaendert.json()).musiker.name, 'Zora Zeugin-Neu');

  const geloescht = await fetch(`${baseUrl}/api/musiker/${musiker.id}`, { method: 'DELETE', headers: { Authorization: ORG_AUTH } });
  assert.equal(geloescht.status, 204);
});

test('Musiker-CRUD: Löschen mit bestehender Termin-Teilnahme -> 409, nicht gelöscht (KEIN stilles Kaskadieren)', async (t) => {
  if (!dbErreichbar) return t.skip('Keine erreichbare Postgres-Instanz');
  const { kursaalId } = await frischerZustand();

  await fetch(`${baseUrl}/api/termine`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: ORG_AUTH },
    body: JSON.stringify(terminBody({ raumId: kursaalId, teilnehmer: ['AB'] })),
  });
  const musikerRow = await pool.query("SELECT id FROM musiker WHERE kuerzel = 'AB'");
  const musikerId = musikerRow.rows[0].id;

  const res = await fetch(`${baseUrl}/api/musiker/${musikerId}`, { method: 'DELETE', headers: { Authorization: ORG_AUTH } });
  assert.equal(res.status, 409);

  const nochDa = await pool.query('SELECT id FROM musiker WHERE id = $1', [musikerId]);
  assert.equal(nochDa.rows.length, 1);
});

test('Konzerte+Werke-CRUD: anlegen (inkl. Teilnehmer), ändern, löschen', async (t) => {
  if (!dbErreichbar) return t.skip('Keine erreichbare Postgres-Instanz');
  await frischerZustand();

  const konzertRes = await fetch(`${baseUrl}/api/konzerte`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: ORG_AUTH },
    body: JSON.stringify({ nummer: 4200, name: 'Testkonzert', dauerMinuten: 60 }),
  });
  assert.equal(konzertRes.status, 201);
  const { konzert } = await konzertRes.json();

  const werkRes = await fetch(`${baseUrl}/api/werke`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: ORG_AUTH },
    body: JSON.stringify({ konzertId: konzert.id, nummer: 4201, name: 'Testwerk', dauerMinuten: 12, teilnehmer: ['AB', 'CD'] }),
  });
  assert.equal(werkRes.status, 201);
  const { id: werkId } = await werkRes.json();

  const listeRes = await fetch(`${baseUrl}/api/werke`);
  const werke = (await listeRes.json()).werke;
  const angelegtesWerk = werke.find((w) => w.id === werkId);
  assert.deepEqual(angelegtesWerk.teilnehmer, ['AB', 'CD']);
  assert.equal(angelegtesWerk.konzertNummer, 4200);

  // Konzert kann nicht gelöscht werden, solange das Werk noch existiert.
  const konzertLoeschVersuch = await fetch(`${baseUrl}/api/konzerte/${konzert.id}`, { method: 'DELETE', headers: { Authorization: ORG_AUTH } });
  assert.equal(konzertLoeschVersuch.status, 409);

  // Werk ändern (Teilnehmer ersetzen) funktioniert.
  const werkAendern = await fetch(`${baseUrl}/api/werke/${werkId}`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json', Authorization: ORG_AUTH },
    body: JSON.stringify({ konzertId: konzert.id, nummer: 4201, name: 'Testwerk geändert', dauerMinuten: 15, teilnehmer: ['EF'] }),
  });
  assert.equal(werkAendern.status, 200);
  const nachAendern = (await (await fetch(`${baseUrl}/api/werke`)).json()).werke.find((w) => w.id === werkId);
  assert.deepEqual(nachAendern.teilnehmer, ['EF']);

  // Werk löschen, dann Konzert löschen -- beides sollte jetzt gehen.
  const werkLoeschen = await fetch(`${baseUrl}/api/werke/${werkId}`, { method: 'DELETE', headers: { Authorization: ORG_AUTH } });
  assert.equal(werkLoeschen.status, 204);
  const konzertLoeschen = await fetch(`${baseUrl}/api/konzerte/${konzert.id}`, { method: 'DELETE', headers: { Authorization: ORG_AUTH } });
  assert.equal(konzertLoeschen.status, 204);
});

test('Stammdaten-CRUD: Anlegen auf archivierter Saison -> 403', async (t) => {
  if (!dbErreichbar) return t.skip('Keine erreichbare Postgres-Instanz');
  await frischerZustand();
  await pool.query('DELETE FROM saisons WHERE jahr = 2095');
  await fetch(`${baseUrl}/api/saisons`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: ORG_AUTH },
    body: JSON.stringify({ jahr: 2095, bezeichnung: 'ZwT 2095 (Test)' }),
  });
  try {
    const res = await fetch(`${baseUrl}/api/raeume?saison=2095`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: ORG_AUTH },
      body: JSON.stringify({ name: 'Sollte scheitern' }),
    });
    assert.equal(res.status, 403);
  } finally {
    await pool.query('DELETE FROM saisons WHERE jahr = 2095');
  }
});

// -- Benutzer:innen (07.09.2026, Rafi-Feedback: "Es sollte auch eine
// Username/Passwort Funktion geben für verschiedene User.", siehe
// REFERENCE.md "Mehrere Benutzer:innen" und server/auth.js). Bewusst
// KEIN frischerZustand()-Aufruf nötig -- die benutzer-Tabelle ist
// saisonunabhängig und wird hier selbst aufgeräumt (finally), statt
// bei jedem Test global geleert zu werden.
test('Benutzer-CRUD: anlegen, damit einloggen, Passwort ändern, löschen', async (t) => {
  if (!dbErreichbar) return t.skip('Keine erreichbare Postgres-Instanz');
  await pool.query("DELETE FROM benutzer WHERE benutzername = 'test-benutzerin'");

  try {
    const angelegt = await fetch(`${baseUrl}/api/benutzer`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: ORG_AUTH },
      body: JSON.stringify({ benutzername: 'test-benutzerin', passwort: 'geheim123' }),
    });
    assert.equal(angelegt.status, 201);
    const { benutzer } = await angelegt.json();
    assert.equal(benutzer.benutzername, 'test-benutzerin');
    assert.equal(benutzer.passwortHash, undefined); // Hash wird NIE nach aussen gegeben

    // Mit dem neuen Konto (nicht dem Notfallzugang) einloggen können.
    const eigeneAuth = authHeader('test-benutzerin', 'geheim123');
    const login = await fetch(`${baseUrl}/api/auth/pruefen`, { headers: { Authorization: eigeneAuth } });
    assert.equal(login.status, 200);

    // Falsches Passwort für dasselbe Konto weiterhin abgelehnt.
    const falscherLogin = await fetch(`${baseUrl}/api/auth/pruefen`, {
      headers: { Authorization: authHeader('test-benutzerin', 'falsch') },
    });
    assert.equal(falscherLogin.status, 401);

    // Doppelter Benutzername -> 400, nicht 500.
    const doppelt = await fetch(`${baseUrl}/api/benutzer`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: ORG_AUTH },
      body: JSON.stringify({ benutzername: 'test-benutzerin', passwort: 'geheim123' }),
    });
    assert.equal(doppelt.status, 400);

    // Passwort ändern -- alter Login funktioniert danach nicht mehr, neuer schon.
    const geaendert = await fetch(`${baseUrl}/api/benutzer/${benutzer.id}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json', Authorization: ORG_AUTH },
      body: JSON.stringify({ passwort: 'neuesgeheimnis' }),
    });
    assert.equal(geaendert.status, 200);
    const altesPasswort = await fetch(`${baseUrl}/api/auth/pruefen`, { headers: { Authorization: eigeneAuth } });
    assert.equal(altesPasswort.status, 401);
    const neuesPasswort = await fetch(`${baseUrl}/api/auth/pruefen`, {
      headers: { Authorization: authHeader('test-benutzerin', 'neuesgeheimnis') },
    });
    assert.equal(neuesPasswort.status, 200);

    // GET listet das Konto (ohne Passwort-Hash).
    const liste = await fetch(`${baseUrl}/api/benutzer`, { headers: { Authorization: ORG_AUTH } });
    assert.equal(liste.status, 200);
    const { benutzer: alle } = await liste.json();
    assert.ok(alle.some((b) => b.benutzername === 'test-benutzerin'));
    assert.ok(alle.every((b) => !('passwortHash' in b) && !('passwort_hash' in b)));

    // Löschen -- danach schlägt der Login mit diesem Konto fehl,
    // der Notfallzugang (ORGANISATOR_PASSWORT) funktioniert weiterhin.
    const geloescht = await fetch(`${baseUrl}/api/benutzer/${benutzer.id}`, { method: 'DELETE', headers: { Authorization: ORG_AUTH } });
    assert.equal(geloescht.status, 204);
    const loginNachLoeschen = await fetch(`${baseUrl}/api/auth/pruefen`, {
      headers: { Authorization: authHeader('test-benutzerin', 'neuesgeheimnis') },
    });
    assert.equal(loginNachLoeschen.status, 401);
    const notfallLoginGehtWeiterhin = await fetch(`${baseUrl}/api/auth/pruefen`, { headers: { Authorization: ORG_AUTH } });
    assert.equal(notfallLoginGehtWeiterhin.status, 200);
  } finally {
    await pool.query("DELETE FROM benutzer WHERE benutzername = 'test-benutzerin'");
  }
});

test('POST /api/benutzer: zu kurzes Passwort -> 400, kein Konto angelegt', async (t) => {
  if (!dbErreichbar) return t.skip('Keine erreichbare Postgres-Instanz');
  await pool.query("DELETE FROM benutzer WHERE benutzername = 'zu-kurz'");
  const res = await fetch(`${baseUrl}/api/benutzer`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: ORG_AUTH },
    body: JSON.stringify({ benutzername: 'zu-kurz', passwort: '123' }),
  });
  assert.equal(res.status, 400);
  const nachschlagen = await pool.query('SELECT id FROM benutzer WHERE benutzername = $1', ['zu-kurz']);
  assert.equal(nachschlagen.rows.length, 0);
});

test('POST /api/benutzer: ohne Auth-Header -> 401, nichts angelegt', async (t) => {
  if (!dbErreichbar) return t.skip('Keine erreichbare Postgres-Instanz');
  const res = await fetch(`${baseUrl}/api/benutzer`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ benutzername: 'ohne-auth', passwort: 'geheim123' }),
  });
  assert.equal(res.status, 401);
});
