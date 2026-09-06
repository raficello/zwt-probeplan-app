'use strict';

// Phase 3 — Kernfunktion: Terminverwaltung (siehe REFERENCE.md
// Abschnitt 1/3/4). Die SQL- und Gruppierungs-Logik ist hier von
// index.js getrennt, damit groupTermineRows ohne echte Datenbank
// getestet werden kann.

// Ein Termin kann mehrere Musiker haben (Teilnehmer, Master Spalte H) —
// der JOIN liefert deshalb eine Zeile pro Termin-Musiker-Paar (bzw. eine
// einzelne Zeile mit musiker_kuerzel=NULL, falls keine Teilnehmer
// eingetragen sind, z.B. bei Typ='Kzt', siehe REFERENCE.md Abschnitt 3).
// $1 = Datum-Filter (oder NULL für "alle Tage"), $2 = Wochentag-Filter
// (oder NULL).
//
// "neu" (Änderungsmarkierung, REFERENCE.md Abschnitt 5): true, wenn der
// Termin nach dem letzten "Stand sperren" angelegt oder geändert wurde
// (t.updated_at > konfiguration.locked_at). Solange noch nie gesperrt
// wurde (kein Eintrag "locked_at" in konfiguration), ist ALLES "neu"=false
// — es gibt noch keinen Vergleichs-Zeitpunkt (Annahme, siehe PROGRESS.md
// "Offene Fragen"). Der Vergleich läuft komplett in SQL, damit
// Zeitzonen-Fragen nicht doppelt (SQL + JS) beantwortet werden müssen.
const SELECT_TERMINE_SQL = `
  SELECT
    t.id, t.wochentag, t.datum, t.anfangszeit, t.endzeit,
    t.typ, t.werk, t.bemerkungen, t.created_at, t.updated_at,
    r.id AS raum_id, r.name AS raum_name, r.aud_code,
    m.kuerzel AS musiker_kuerzel,
    (k.wert IS NOT NULL AND t.updated_at > k.wert::timestamptz) AS neu
  FROM termine t
  JOIN raeume r ON r.id = t.raum_id
  LEFT JOIN termin_musiker tm ON tm.termin_id = t.id
  LEFT JOIN musiker m ON m.id = tm.musiker_id
  LEFT JOIN konfiguration k ON k.schluessel = 'locked_at'
  WHERE ($1::date IS NULL OR t.datum = $1::date)
    AND ($2::text IS NULL OR t.wochentag = $2::text)
  ORDER BY t.datum, t.anfangszeit, t.id
`;

/**
 * Gruppiert die flachen SQL-Join-Zeilen von SELECT_TERMINE_SQL zu einem
 * Array von Terminen mit teilnehmer-Array (statt einer Zeile pro
 * Termin-Musiker-Paar).
 */
// `date`-Spalten liefert node-postgres als JS-Date-Objekt (Mitternacht
// UTC), NICHT als "YYYY-MM-DD"-String — JSON.stringify (res.json())
// macht daraus einen vollen ISO-Zeitstempel ("2026-09-07T00:00:00.000Z"),
// nicht "2026-09-07". Bisher fiel das nicht auf, weil raumplan.html/
// musikerplan.html das angeforderte Datum aus dem eigenen <input
// type="date">-Feld weiterverwenden statt termin.datum aus der
// API-Antwort zu lesen — server/pdf.js kennt genau dieses Muster bereits
// (siehe formatiereDatum dort). Per echtem Browser-Test gefunden, als
// die neue Terminverwaltung (Phase 8) t.datum erstmals in ein
// <input type="date"> schrieb: der volle ISO-String macht das Feld
// leer, weil <input type="date"> NUR "YYYY-MM-DD" akzeptiert. Deshalb
// hier zentral normalisieren, statt es jedem Aufrufer zu überlassen.
function formatiereDatumFeld(datum) {
  if (datum instanceof Date) return datum.toISOString().slice(0, 10);
  return typeof datum === 'string' ? datum.slice(0, 10) : datum;
}

function groupTermineRows(rows) {
  const byId = new Map();
  const order = [];

  for (const row of rows) {
    let termin = byId.get(row.id);
    if (!termin) {
      termin = {
        id: row.id,
        wochentag: row.wochentag,
        datum: formatiereDatumFeld(row.datum),
        anfangszeit: row.anfangszeit,
        endzeit: row.endzeit,
        raum: { id: row.raum_id, name: row.raum_name, audCode: row.aud_code },
        typ: row.typ,
        werk: row.werk,
        bemerkungen: row.bemerkungen,
        teilnehmer: [],
        createdAt: row.created_at,
        updatedAt: row.updated_at,
        neu: row.neu === true,
      };
      byId.set(row.id, termin);
      order.push(row.id);
    }
    if (row.musiker_kuerzel) {
      termin.teilnehmer.push(row.musiker_kuerzel);
    }
  }

  return order.map((id) => byId.get(id));
}

// Für das Anlegen/Ändern eines Termins (POST/PUT /api/termine): dieselbe
// Zeilenform wie SELECT_TERMINE_SQL (inkl. "neu"-Berechnung), aber für
// genau einen Termin per ID (zur Rückgabe im Response).
const SELECT_TERMIN_BY_ID_SQL = `
  SELECT
    t.id, t.wochentag, t.datum, t.anfangszeit, t.endzeit,
    t.typ, t.werk, t.bemerkungen, t.created_at, t.updated_at,
    r.id AS raum_id, r.name AS raum_name, r.aud_code,
    m.kuerzel AS musiker_kuerzel,
    (k.wert IS NOT NULL AND t.updated_at > k.wert::timestamptz) AS neu
  FROM termine t
  JOIN raeume r ON r.id = t.raum_id
  LEFT JOIN termin_musiker tm ON tm.termin_id = t.id
  LEFT JOIN musiker m ON m.id = tm.musiker_id
  LEFT JOIN konfiguration k ON k.schluessel = 'locked_at'
  WHERE t.id = $1
`;

// Bestehende Termine im selben Raum am selben Tag (für die
// Konfliktprüfung, REFERENCE.md Abschnitt 4) — bewusst ohne Musiker-JOIN,
// da hier nur Zeiten/ID/Werk gebraucht werden. $3 (optional, NULL bei
// POST): eigene ID beim Ändern (PUT) ausschliessen, sonst würde sich ein
// Termin ständig mit sich selbst "überschneiden".
const SELECT_TERMINE_FUER_KONFLIKTPRUEFUNG_SQL = `
  SELECT id, anfangszeit, endzeit, werk
  FROM termine
  WHERE raum_id = $1 AND datum = $2::date
    AND ($3::int IS NULL OR id != $3::int)
`;

// Pufferzeit zwischen zwei Terminen im selben Raum (REFERENCE.md
// Abschnitt 2). Kein Eintrag = Default-Puffer 0 Minuten (siehe
// PROGRESS.md "Offene Fragen").
const SELECT_RAUM_PUFFER_SQL = `
  SELECT puffer_minuten FROM raum_puffer WHERE von_raum_id = $1 AND bis_raum_id = $1
`;

// Ein einzelner Raum per ID (für die Wochentags-Beschränkungsprüfung
// beim Anlegen/Ändern eines Termins, REFERENCE.md Abschnitt 2, sowie um
// "Unbekannte raumId" VOR dem Schreiben zu erkennen statt erst über
// einen Foreign-Key-Fehler beim INSERT).
const SELECT_RAUM_SQL = `
  SELECT id, name, aud_code, erlaubte_tage FROM raeume WHERE id = $1
`;

// ALLE Räume, auch ohne Termin an einem bestimmten Tag (Nachfolger von
// confRaeume, REFERENCE.md Abschnitt 2) — Grundlage für die
// Raum-Auswahl in der Terminverwaltung (Phase 8-Vorbereitung: es gab
// bisher keinen Endpunkt, der Räume unabhängig von Terminen liefert).
const SELECT_RAEUME_SQL = `
  SELECT id, name, aud_code, erlaubte_tage FROM raeume ORDER BY name
`;

const INSERT_TERMIN_SQL = `
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen)
  VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
  RETURNING id
`;

// Legt den Musiker an, falls das Kürzel noch nicht existiert (Annahme:
// gleiches Verhalten wie migrate/lib.js für unbekannte Räume — lieber
// automatisch anlegen als die ganze Anfrage ablehnen, siehe
// PROGRESS.md "Offene Fragen").
const UPSERT_MUSIKER_SQL = `
  INSERT INTO musiker (kuerzel) VALUES ($1)
  ON CONFLICT (kuerzel) DO UPDATE SET kuerzel = EXCLUDED.kuerzel
  RETURNING id
`;

const INSERT_TERMIN_MUSIKER_SQL = `
  INSERT INTO termin_musiker (termin_id, musiker_id) VALUES ($1, $2)
  ON CONFLICT DO NOTHING
`;

// PUT /api/termine/:id — ersetzt alle Felder (kein PATCH mit Teil-Update,
// bewusst einfach gehalten für diesen ersten Schritt). `updated_at` wird
// explizit gesetzt, da es nur beim INSERT einen DEFAULT now() gibt
// (Basis für die Änderungsmarkierung, REFERENCE.md Abschnitt 5).
const UPDATE_TERMIN_SQL = `
  UPDATE termine
  SET wochentag = $1, datum = $2, anfangszeit = $3, endzeit = $4,
      raum_id = $5, typ = $6, werk = $7, bemerkungen = $8, updated_at = now()
  WHERE id = $9
  RETURNING id
`;

// Beim Ändern werden die Teilnehmer komplett ersetzt (löschen + neu
// einfügen) statt zu versuchen, die Differenz zu berechnen — einfacher
// und für die erwartete Terminzahl performant genug.
const DELETE_TERMIN_MUSIKER_SQL = `
  DELETE FROM termin_musiker WHERE termin_id = $1
`;

const DELETE_TERMIN_SQL = `
  DELETE FROM termine WHERE id = $1
  RETURNING id
`;

// "Stand sperren" (REFERENCE.md Abschnitt 5): speichert den aktuellen
// Zeitpunkt als locked_at. Ab da gilt jeder Termin mit updated_at >
// locked_at als "neu/geändert" (siehe SELECT_TERMINE_SQL oben).
const SPERREN_SQL = `
  INSERT INTO konfiguration (schluessel, wert) VALUES ('locked_at', now()::text)
  ON CONFLICT (schluessel) DO UPDATE SET wert = EXCLUDED.wert
  RETURNING wert
`;

const SELECT_LOCKED_AT_SQL = `
  SELECT wert FROM konfiguration WHERE schluessel = 'locked_at'
`;

module.exports = {
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
};
