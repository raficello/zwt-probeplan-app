'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { parseBasicAuthHeader, sicherVergleich, pruefeOrganisatorAuth } = require('../auth');

function basicHeader(benutzer, passwort) {
  return 'Basic ' + Buffer.from(`${benutzer}:${passwort}`, 'utf8').toString('base64');
}

test('parseBasicAuthHeader: parst einen gültigen Basic-Auth-Header', () => {
  const result = parseBasicAuthHeader(basicHeader('organisator', 'geheim123'));
  assert.deepEqual(result, { benutzer: 'organisator', passwort: 'geheim123' });
});

test('parseBasicAuthHeader: Passwort mit Doppelpunkt bleibt erhalten (nur beim ERSTEN ":" getrennt)', () => {
  const result = parseBasicAuthHeader(basicHeader('organisator', 'ge:heim:123'));
  assert.deepEqual(result, { benutzer: 'organisator', passwort: 'ge:heim:123' });
});

test('parseBasicAuthHeader: fehlender Header ergibt null', () => {
  assert.equal(parseBasicAuthHeader(undefined), null);
  assert.equal(parseBasicAuthHeader(''), null);
});

test('parseBasicAuthHeader: falsches Schema (nicht "Basic") ergibt null', () => {
  assert.equal(parseBasicAuthHeader('Bearer abc123'), null);
});

test('parseBasicAuthHeader: kaputtes Base64 ergibt null statt Absturz', () => {
  assert.equal(parseBasicAuthHeader('Basic !!!nicht-base64!!!'), null);
});

test('sicherVergleich: gleiche Strings sind gleich', () => {
  assert.equal(sicherVergleich('geheim123', 'geheim123'), true);
});

test('sicherVergleich: unterschiedliche Strings (gleiche Länge) sind ungleich', () => {
  assert.equal(sicherVergleich('geheim123', 'geheim124'), false);
});

test('sicherVergleich: unterschiedliche Länge ist ungleich (kein Absturz)', () => {
  assert.equal(sicherVergleich('kurz', 'vielviellaenger'), false);
});

// Für pruefeOrganisatorAuth: einfache Fake-Objekte statt eines echten
// Express-Requests, da die Middleware nur req.headers.authorization
// liest und res.status/json/setHeader aufruft.
function fakeRes() {
  const res = {
    statusCode: null,
    body: null,
    headers: {},
    status(code) {
      this.statusCode = code;
      return this;
    },
    json(body) {
      this.body = body;
      return this;
    },
    setHeader(name, value) {
      this.headers[name] = value;
    },
  };
  return res;
}

test('pruefeOrganisatorAuth: ohne ORGANISATOR_PASSWORT in der Umgebung -> 503, next() NICHT aufgerufen', () => {
  const alt = process.env.ORGANISATOR_PASSWORT;
  delete process.env.ORGANISATOR_PASSWORT;
  try {
    const req = { headers: {} };
    const res = fakeRes();
    let nextAufgerufen = false;
    pruefeOrganisatorAuth(req, res, () => {
      nextAufgerufen = true;
    });
    assert.equal(res.statusCode, 503);
    assert.equal(nextAufgerufen, false);
  } finally {
    if (alt !== undefined) process.env.ORGANISATOR_PASSWORT = alt;
  }
});

test('pruefeOrganisatorAuth: fehlender Authorization-Header -> 401, ABSICHTLICH ohne WWW-Authenticate', () => {
  // Kein WWW-Authenticate-Header — sonst öffnet der Browser bei einem
  // fetch()-Aufruf sein eigenes, hängendes Login-Popup statt die
  // JSON-Antwort durchzureichen (per echtem Browser-Test gefunden,
  // siehe REFERENCE.md Abschnitt 13 — Regressionstest).
  process.env.ORGANISATOR_PASSWORT = 'testpasswort';
  const req = { headers: {} };
  const res = fakeRes();
  let nextAufgerufen = false;
  pruefeOrganisatorAuth(req, res, () => {
    nextAufgerufen = true;
  });
  assert.equal(res.statusCode, 401);
  assert.equal(res.headers['WWW-Authenticate'], undefined);
  assert.equal(nextAufgerufen, false);
});

test('pruefeOrganisatorAuth: falsches Passwort -> 401', () => {
  process.env.ORGANISATOR_PASSWORT = 'testpasswort';
  const req = { headers: { authorization: basicHeader('organisator', 'falsch') } };
  const res = fakeRes();
  let nextAufgerufen = false;
  pruefeOrganisatorAuth(req, res, () => {
    nextAufgerufen = true;
  });
  assert.equal(res.statusCode, 401);
  assert.equal(nextAufgerufen, false);
});

test('pruefeOrganisatorAuth: richtiges Passwort -> next() wird aufgerufen, keine Response gesetzt', () => {
  process.env.ORGANISATOR_PASSWORT = 'testpasswort';
  const req = { headers: { authorization: basicHeader('organisator', 'testpasswort') } };
  const res = fakeRes();
  let nextAufgerufen = false;
  pruefeOrganisatorAuth(req, res, () => {
    nextAufgerufen = true;
  });
  assert.equal(nextAufgerufen, true);
  assert.equal(res.statusCode, null);
});

test('pruefeOrganisatorAuth: falscher Benutzername (auch bei richtigem Passwort) -> 401', () => {
  process.env.ORGANISATOR_PASSWORT = 'testpasswort';
  const req = { headers: { authorization: basicHeader('jemand-anderes', 'testpasswort') } };
  const res = fakeRes();
  let nextAufgerufen = false;
  pruefeOrganisatorAuth(req, res, () => {
    nextAufgerufen = true;
  });
  assert.equal(res.statusCode, 401);
  assert.equal(nextAufgerufen, false);
});
