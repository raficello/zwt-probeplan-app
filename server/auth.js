'use strict';

// Zugriffsschutz für Schreiboperationen (Phase 7, Zugriffsmodell "A",
// siehe PROGRESS.md): Lesen (Raumplan, Musikerplan, PDFs, GET /api/*)
// ist für alle offen, die den Link kennen — KEIN Login nötig. Nur
// Schreiben (Termine anlegen/ändern/löschen, Stand sperren, Stammdaten)
// ist per Basic-Auth-artigem Header geschützt (Authorization-Header),
// aber bewusst OHNE echtes HTTP-Basic-Auth-Handshake (kein
// `WWW-Authenticate`-Header bei 401!). Keine Session-Verwaltung, keine
// Cookies — für ein kleines Vereinsprojekt reicht das.
//
// WICHTIG (per echtem Browser-Test gefunden, siehe REFERENCE.md
// Abschnitt 13): ein `WWW-Authenticate: Basic`-Header auf der
// 401-Antwort lässt den BROWSER selbst einspringen — bei einem
// `fetch()`-Aufruf öffnet er (bzw. versucht zu öffnen) sein eigenes,
// natives Zugangsdaten-Dialogfeld, was den Request in Headless-
// Umgebungen unbemerkt für immer hängen lässt und auch in echten
// Browsern zu einem verwirrenden zweiten, hässlichen Login-Popup neben
// unserem eigenen `prompt()`-Dialog führt. Deshalb: NIE den
// `WWW-Authenticate`-Header setzen, wenn Basic-Auth-artige Daten über
// `fetch()` geprüft werden (im Unterschied zu "echtem" HTTP-Basic-Auth
// für z.B. direkten Browser-Seitenaufruf oder curl, wo der Header
// gewünscht wäre).
//
// NEU 07.09.2026 (Rafi-Feedback: "Es sollte auch eine
// Username/Passwort Funktion geben für verschiedene User"): zusätzlich
// zum bisherigen einzigen gemeinsamen Passwort (jetzt "Notfallzugang",
// siehe unten) gibt es echte Benutzerkonten in der `benutzer`-Tabelle
// (db/migration-benutzer.sql), jedes mit eigenem Benutzernamen +
// Passwort (gehasht mit `crypto.scrypt`, KEIN Klartext, KEINE externe
// Abhängigkeit nötig). Bewusst KEIN Rollen-/Rechte-System — jedes
// Konto hat dieselben Schreibrechte.
//
// `ORGANISATOR_BENUTZER`/`ORGANISATOR_PASSWORT` (.env) bleiben
// zusätzlich als Notfallzugang gültig — u.a. der Weg, wie das ERSTE
// eigene Benutzerkonto angelegt wird (damit einloggen, dann über die
// "Benutzer:innen"-Verwaltung in admin.html echte Konten anlegen).

const crypto = require('crypto');
const { pool } = require('./db');

const BENUTZER = process.env.ORGANISATOR_BENUTZER || 'organisator';

/**
 * Zerlegt einen "Authorization: Basic ..."-Header in { benutzer,
 * passwort }. Gibt null zurück, wenn der Header fehlt oder nicht dem
 * Basic-Auth-Format entspricht.
 */
function parseBasicAuthHeader(header) {
  if (!header || !header.startsWith('Basic ')) return null;
  let decoded;
  try {
    decoded = Buffer.from(header.slice('Basic '.length), 'base64').toString('utf8');
  } catch {
    return null;
  }
  const trennzeichenIndex = decoded.indexOf(':');
  if (trennzeichenIndex === -1) return null;
  return {
    benutzer: decoded.slice(0, trennzeichenIndex),
    passwort: decoded.slice(trennzeichenIndex + 1),
  };
}

/**
 * Vergleicht zwei Strings zeitkonstant (schützt gegen Timing-Angriffe
 * auf das Passwort). crypto.timingSafeEqual verlangt gleich lange
 * Buffer — bei unterschiedlicher Länge wird trotzdem ein (bedeutungs-
 * loser) Vergleich durchgeführt, damit die Antwortzeit nicht verrät,
 * dass die Länge falsch war.
 */
function sicherVergleich(a, b) {
  const bufA = Buffer.from(String(a ?? ''), 'utf8');
  const bufB = Buffer.from(String(b ?? ''), 'utf8');
  if (bufA.length !== bufB.length) {
    crypto.timingSafeEqual(bufA, bufA);
    return false;
  }
  return crypto.timingSafeEqual(bufA, bufB);
}

// -- Passwort-Hashing für die `benutzer`-Tabelle -------------------
//
// crypto.scrypt (Node-Bordmittel, keine neue npm-Abhängigkeit nötig)
// statt bcrypt/argon2. Format des gespeicherten Hash-Strings:
// "<salt-hex>:<derivedKey-hex>", damit pro Passwort ein zufälliger,
// eigener Salt verwendet wird (schützt gegen Rainbow-Table-Angriffe).

const SCRYPT_KEYLEN = 64;

/** Hasht ein Klartext-Passwort für die Speicherung in `benutzer.passwort_hash`. */
function hashePasswort(passwort) {
  return new Promise((resolve, reject) => {
    const salt = crypto.randomBytes(16).toString('hex');
    crypto.scrypt(String(passwort), salt, SCRYPT_KEYLEN, (err, derivedKey) => {
      if (err) return reject(err);
      resolve(`${salt}:${derivedKey.toString('hex')}`);
    });
  });
}

/**
 * Prüft ein Klartext-Passwort gegen einen gespeicherten Hash (Format
 * siehe `hashePasswort`). Gibt bei kaputtem/fremdem Hash-Format `false`
 * zurück statt zu werfen (z.B. falls die Spalte leer/NULL ist).
 */
function pruefePasswort(passwort, hash) {
  return new Promise((resolve, reject) => {
    if (typeof hash !== 'string' || !hash.includes(':')) return resolve(false);
    const [salt, keyHex] = hash.split(':');
    let erwarteterKey;
    try {
      erwarteterKey = Buffer.from(keyHex, 'hex');
    } catch {
      return resolve(false);
    }
    crypto.scrypt(String(passwort), salt, SCRYPT_KEYLEN, (err, derivedKey) => {
      if (err) return reject(err);
      if (erwarteterKey.length !== derivedKey.length) return resolve(false);
      resolve(crypto.timingSafeEqual(erwarteterKey, derivedKey));
    });
  });
}

/**
 * Prüft übergebene Basic-Auth-artige Zugangsdaten gegen die
 * `benutzer`-Tabelle. Gibt `false` zurück (statt zu werfen) bei
 * fehlender Datenbank, unbekanntem Benutzernamen oder DB-Fehlern —
 * ein Login-Fehlschlag ist hier immer nur "nicht erfolgreich", nie ein
 * Absturz.
 */
async function pruefeBenutzerInDatenbank(benutzername, passwort) {
  if (!pool || !benutzername) return false;
  try {
    const result = await pool.query('SELECT passwort_hash FROM benutzer WHERE benutzername = $1', [benutzername]);
    const zeile = result.rows[0];
    if (!zeile) return false;
    return await pruefePasswort(passwort, zeile.passwort_hash);
  } catch {
    // DB-Fehler beim Login-Check nicht crashen lassen -- als
    // Fehlschlag werten, nicht als Server-Fehler nach aussen zeigen.
    return false;
  }
}

/**
 * Express-Middleware: lässt die Anfrage nur durch, wenn gültige
 * Zugangsdaten mitgeschickt wurden — entweder der Notfallzugang
 * (`ORGANISATOR_BENUTZER`/`ORGANISATOR_PASSWORT` aus der Umgebung) oder
 * ein Konto aus der `benutzer`-Tabelle. Ist WEDER ein Notfallpasswort
 * gesetzt NOCH eine Datenbank verfügbar, wird Schreiben komplett
 * deaktiviert (503) statt versehentlich offen zu bleiben.
 */
async function pruefeOrganisatorAuth(req, res, next) {
  const notfallPasswort = process.env.ORGANISATOR_PASSWORT;

  if (!notfallPasswort && !pool) {
    return res
      .status(503)
      .json({ status: 'error', message: 'Kein Login-Mechanismus konfiguriert — Schreiben ist deaktiviert' });
  }

  const credentials = parseBasicAuthHeader(req.headers.authorization);
  if (!credentials) {
    // ABSICHTLICH kein WWW-Authenticate-Header — siehe Kommentar am
    // Dateianfang, das würde den Browser ein eigenes, hängendes
    // Login-Popup öffnen lassen statt die JSON-Antwort einfach an unser
    // fetch()-basiertes JS durchzureichen.
    return res.status(401).json({ status: 'error', message: 'Anmeldung erforderlich' });
  }

  // 1) Notfallzugang zuerst prüfen (rein synchron, kein DB-Zugriff
  //    nötig) -- funktioniert auch dann noch, wenn die Datenbank mal
  //    nicht erreichbar ist.
  if (
    notfallPasswort &&
    sicherVergleich(credentials.benutzer, BENUTZER) &&
    sicherVergleich(credentials.passwort, notfallPasswort)
  ) {
    return next();
  }

  // 2) Gegen die benutzer-Tabelle prüfen -- NUR wenn eine Datenbank
  //    verfügbar ist, und zwar mit einer synchronen Prüfung VOR dem
  //    `await`: jedes `await` verschiebt die Fortsetzung auf den
  //    nächsten Microtask, selbst wenn das awaitete Promise sofort
  //    aufgelöst wird (z.B. weil pool null ist) -- ohne dieses
  //    Kurzschluss-`if` würde pruefeOrganisatorAuth bei fehlender
  //    Datenbank nie mehr synchron antworten (Regressionstest siehe
  //    auth.test.js).
  if (pool) {
    const okInDatenbank = await pruefeBenutzerInDatenbank(credentials.benutzer, credentials.passwort);
    if (okInDatenbank) return next();
  }

  return res.status(401).json({ status: 'error', message: 'Anmeldung erforderlich' });
}

module.exports = {
  pruefeOrganisatorAuth,
  parseBasicAuthHeader,
  sicherVergleich,
  hashePasswort,
  pruefePasswort,
  BENUTZER,
};
