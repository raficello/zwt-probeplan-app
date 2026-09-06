'use strict';

// Zugriffsschutz für Schreiboperationen (Phase 7, Zugriffsmodell "A",
// siehe PROGRESS.md): Lesen (Raumplan, Musikerplan, PDFs, GET /api/*)
// ist für alle offen, die den Link kennen — KEIN Login nötig. Nur
// Schreiben (Termine anlegen/ändern/löschen, Stand sperren) ist mit
// einem einzigen, gemeinsamen Organisator:innen-Passwort geschützt, im
// "Basic"-Format übertragen (Authorization-Header), aber bewusst OHNE
// echtes HTTP-Basic-Auth-Handshake (kein `WWW-Authenticate`-Header bei
// 401!). Bewusst kein Konto pro Person, keine eigene Datenbank-Tabelle,
// keine Session-Verwaltung — für ein kleines Vereinsprojekt reicht das.
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

const crypto = require('crypto');

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

/**
 * Express-Middleware: lässt die Anfrage nur durch, wenn gültige
 * Organisator:innen-Basic-Auth-Daten mitgeschickt wurden. Erwartet
 * `ORGANISATOR_PASSWORT` in der Umgebung — ist die Variable nicht
 * gesetzt, wird Schreiben komplett deaktiviert (503) statt versehentlich
 * offen zu bleiben.
 */
function pruefeOrganisatorAuth(req, res, next) {
  const erwartetesPasswort = process.env.ORGANISATOR_PASSWORT;
  if (!erwartetesPasswort) {
    return res
      .status(503)
      .json({ status: 'error', message: 'ORGANISATOR_PASSWORT nicht gesetzt — Schreiben ist deaktiviert' });
  }

  const credentials = parseBasicAuthHeader(req.headers.authorization);
  const ok =
    credentials !== null &&
    sicherVergleich(credentials.benutzer, BENUTZER) &&
    sicherVergleich(credentials.passwort, erwartetesPasswort);

  if (!ok) {
    // ABSICHTLICH kein WWW-Authenticate-Header — siehe Kommentar am
    // Dateianfang, das würde den Browser ein eigenes, hängendes
    // Login-Popup öffnen lassen statt die JSON-Antwort einfach an unser
    // fetch()-basiertes JS durchzureichen.
    return res.status(401).json({ status: 'error', message: 'Anmeldung als Organisator:in erforderlich' });
  }

  next();
}

module.exports = { pruefeOrganisatorAuth, parseBasicAuthHeader, sicherVergleich, BENUTZER };
