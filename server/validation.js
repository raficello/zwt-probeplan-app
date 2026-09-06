'use strict';

// Reine, DB-freie Validierungs- und Konfliktprüfungs-Logik für
// POST /api/termine (Phase 3, siehe REFERENCE.md Abschnitt 1/3/4).
// Getrennt von index.js, damit sie ohne echte Datenbank testbar ist.

const WOCHENTAGE = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
const ERLAUBTE_TYPEN = [null, '', 'GP', 'Kzt', 'K', 'Klf'];

const DATUM_REGEX = /^\d{4}-\d{2}-\d{2}$/;
// Akzeptiert sowohl "HH:MM" (Eingabe aus der API) als auch "HH:MM:SS"
// (so liefert node-postgres time-Spalten zurück — WICHTIG: ohne die
// optionale Sekunden-Gruppe hier würde jede aus der Datenbank gelesene
// Zeit als ungültig erkannt, siehe PROGRESS.md für den Vorfall, der das
// aufgedeckt hat). Sekunden werden für den Minutenwert ignoriert.
const ZEIT_REGEX = /^([01]\d|2[0-3]):([0-5]\d)(?::[0-5]\d)?$/;

function timeToMinutes(hhmm) {
  const match = ZEIT_REGEX.exec(hhmm);
  if (!match) return null;
  return Number(match[1]) * 60 + Number(match[2]);
}

/**
 * Validiert und normalisiert den Request-Body für POST /api/termine.
 * Gibt entweder { value: {...} } oder { errors: [...] } zurück.
 *
 * Business-Regel aus REFERENCE.md Abschnitt 3: bei Typ='Kzt' ist das
 * Teilnehmer-Feld IMMER leer, unabhängig davon, was übergeben wurde
 * (analog zu migrate/lib.js: buildModel).
 */
function parseTerminInput(body) {
  const errors = [];
  body = body && typeof body === 'object' ? body : {};

  const wochentag = body.wochentag;
  if (!WOCHENTAGE.includes(wochentag)) {
    errors.push(`wochentag muss einer von ${WOCHENTAGE.join(', ')} sein`);
  }

  const datum = body.datum;
  if (typeof datum !== 'string' || !DATUM_REGEX.test(datum) || Number.isNaN(Date.parse(datum))) {
    errors.push('datum muss im Format YYYY-MM-DD vorliegen');
  }

  const anfangszeit = body.anfangszeit;
  const endzeit = body.endzeit;
  const anfangMin = typeof anfangszeit === 'string' ? timeToMinutes(anfangszeit) : null;
  const endMin = typeof endzeit === 'string' ? timeToMinutes(endzeit) : null;
  if (anfangMin === null) errors.push('anfangszeit muss im Format HH:MM vorliegen');
  if (endMin === null) errors.push('endzeit muss im Format HH:MM vorliegen');
  if (anfangMin !== null && endMin !== null && endMin < anfangMin) {
    // Gleichstand (endzeit === anfangszeit) ist erlaubt — siehe Kzt-Blockkopf
    // in REFERENCE.md Abschnitt 3 (z.B. "14:00 - 14:00").
    errors.push('endzeit darf nicht vor anfangszeit liegen');
  }

  const raumId = Number(body.raumId);
  if (!Number.isInteger(raumId) || raumId <= 0) {
    errors.push('raumId muss eine positive Ganzzahl sein');
  }

  const typ = body.typ === undefined || body.typ === '' ? null : body.typ;
  if (!ERLAUBTE_TYPEN.includes(typ)) {
    errors.push(`typ muss einer von GP, Kzt, K, Klf oder leer sein`);
  }

  const werk = typeof body.werk === 'string' ? body.werk.trim() : '';
  if (!werk) errors.push('werk darf nicht leer sein');

  const bemerkungen =
    typeof body.bemerkungen === 'string' && body.bemerkungen.trim() ? body.bemerkungen.trim() : null;

  let teilnehmer = [];
  if (typ !== 'Kzt') {
    if (body.teilnehmer !== undefined) {
      if (!Array.isArray(body.teilnehmer) || body.teilnehmer.some((k) => typeof k !== 'string' || !k.trim())) {
        errors.push('teilnehmer muss ein Array nicht-leerer Kürzel-Strings sein');
      } else {
        teilnehmer = body.teilnehmer.map((k) => k.trim());
      }
    }
  }
  // Bei typ='Kzt' bleibt teilnehmer bewusst [] — Business-Regel, kein Fehler,
  // selbst wenn der Aufrufer versehentlich welche mitschickt.

  if (errors.length) return { errors };

  return {
    value: { wochentag, datum, anfangszeit, endzeit, raumId, typ, werk, bemerkungen, teilnehmer },
  };
}

/**
 * Prüft einen Kandidaten-Termin gegen bereits existierende Termine im
 * selben Raum am selben Tag (siehe REFERENCE.md Abschnitt 4). Zwei
 * Termine dürfen sich nicht überschneiden, und zwischen Ende des einen
 * und Start des nächsten muss der raumspezifische Mindestabstand
 * (pufferMinuten) eingehalten werden. Gibt ein Array von
 * Konflikt-Beschreibungen zurück (leer = kein Konflikt).
 *
 * existierendeTermine: Array von { id, anfangszeit, endzeit, werk }
 * (bereits auf denselben Raum + Tag gefiltert).
 */
function findKonflikte(existierendeTermine, kandidat, pufferMinuten) {
  const puffer = Number.isFinite(pufferMinuten) ? pufferMinuten : 0;
  const kStart = timeToMinutes(kandidat.anfangszeit);
  const kEnd = timeToMinutes(kandidat.endzeit);
  if (kStart === null || kEnd === null) {
    throw new Error(`findKonflikte: ungültige Kandidat-Zeit (${kandidat.anfangszeit}–${kandidat.endzeit})`);
  }
  const konflikte = [];

  for (const t of existierendeTermine) {
    const tStart = timeToMinutes(t.anfangszeit);
    const tEnd = timeToMinutes(t.endzeit);
    if (tStart === null || tEnd === null) {
      // Absichtlich ein harter Fehler statt stiller Falschberechnung: null
      // würde in der Arithmetik unten als 0 behandelt und Konflikte
      // unbemerkt verschwinden lassen (genau das ist bereits einmal
      // passiert, als Postgres "HH:MM:SS" statt "HH:MM" lieferte).
      throw new Error(`findKonflikte: ungültige Zeit bei Termin #${t.id} (${t.anfangszeit}–${t.endzeit})`);
    }
    // Kein Konflikt, wenn der Kandidat komplett vor oder komplett nach dem
    // bestehenden Termin liegt (mit Puffer dazwischen).
    const abstandOk = kStart >= tEnd + puffer || kEnd + puffer <= tStart;
    if (!abstandOk) {
      konflikte.push(
        `Überschneidung/zu geringer Abstand (${puffer} Min. nötig) mit Termin #${t.id} "${t.werk}" (${t.anfangszeit}–${t.endzeit})`
      );
    }
  }

  return konflikte;
}

module.exports = { WOCHENTAGE, ERLAUBTE_TYPEN, timeToMinutes, parseTerminInput, findKonflikte };
