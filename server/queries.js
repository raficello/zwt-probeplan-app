'use strict';

// Phase 3 — Kernfunktion: Terminverwaltung (siehe REFERENCE.md
// Abschnitt 1/3/4). Die SQL- und Gruppierungs-Logik ist hier von
// index.js getrennt, damit groupTermineRows ohne echte Datenbank
// getestet werden kann.
//
// Saison-Verwaltung (07.09.2026, siehe REFERENCE.md "Saison-Verwaltung"
// und db/migration-saisons.sql): raeume/musiker/termine/konfiguration/
// konzerte/werke/werk_vorlagen gehören jetzt zu genau einer Saison.
// Abfragen, die "alle X" oder "neues X anlegen" bedeuten, brauchen
// deshalb ab jetzt einen saisonId-Parameter; Abfragen, die über eine
// bereits vorhandene, global eindeutige ID gehen (z.B. Raum-, Konzert-,
// Werk-ID), brauchen KEINEN zusätzlichen Parameter — die ID legt die
// Saison implizit schon fest.

// Alle Saisons, neueste zuerst (Grundlage für das Jahres-Dropdown).
const SELECT_SAISONS_SQL = `
  SELECT id, jahr, bezeichnung, aktiv FROM saisons ORDER BY jahr DESC
`;

const SELECT_SAISON_BY_JAHR_SQL = `
  SELECT id, jahr, bezeichnung, aktiv FROM saisons WHERE jahr = $1
`;

const SELECT_AKTIVE_SAISON_SQL = `
  SELECT id, jahr, bezeichnung, aktiv FROM saisons WHERE aktiv = true
`;

// Legt eine neue Saison an -- bewusst NICHT automatisch aktiv (sonst
// würde das Vorbereiten einer künftigen Saison die gerade laufende
// versehentlich einfrieren, siehe db/migration-saisons.sql). Umschalten
// ist ein bewusster zweiter Schritt (AKTIVIERE_SAISON_SQL).
const INSERT_SAISON_SQL = `
  INSERT INTO saisons (jahr, bezeichnung) VALUES ($1, $2)
  RETURNING id, jahr, bezeichnung, aktiv
`;

// Aktiviert genau eine Saison (macht alle anderen automatisch inaktiv/
// Archiv). BEWUSST ZWEI Anweisungen statt einer einzigen
// "SET aktiv = (id = $1)" -- das sah erst einfacher aus, verletzte aber
// beim Testen (server/test/index.test.js) den partiellen Unique-Index
// "höchstens eine aktive Saison" (saisons_nur_eine_aktiv_idx): innerhalb
// EINER UPDATE-Anweisung prüft Postgres die Eindeutigkeit pro Zeile
// sofort beim Schreiben, nicht erst am Ende der Anweisung -- je nach
// physischer Scan-Reihenfolge kann die neu zu aktivierende Zeile VOR der
// noch alten aktiven Zeile verarbeitet werden, wodurch kurzzeitig zwei
// Zeilen aktiv=true wären und der Index-Check fehlschlägt (Fund per
// echtem Postgres-Test, siehe REFERENCE.md Abschnitt 13). Der Aufrufer
// führt beide Anweisungen NACHEINANDER in derselben Transaktion aus
// (erst alle deaktivieren, dann genau eine aktivieren) -- dabei gibt es
// nie mehr als eine aktive Zeile gleichzeitig.
const DEAKTIVIERE_ALLE_SAISONS_SQL = `
  UPDATE saisons SET aktiv = false WHERE aktiv = true
`;

const AKTIVIERE_SAISON_SQL = `
  UPDATE saisons SET aktiv = true WHERE id = $1
`;

// Ein Termin kann mehrere Musiker haben (Teilnehmer, Master Spalte H) —
// der JOIN liefert deshalb eine Zeile pro Termin-Musiker-Paar (bzw. eine
// einzelne Zeile mit musiker_kuerzel=NULL, falls keine Teilnehmer
// eingetragen sind, z.B. bei Typ='Kzt', siehe REFERENCE.md Abschnitt 3).
// $1 = Datum-Filter (oder NULL für "alle Tage"), $2 = Wochentag-Filter
// (oder NULL), $3 = saisonId (Pflicht seit 07.09.2026 -- sonst würden
// gleichnamige Tage aus verschiedenen Saisons vermischt).
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
  LEFT JOIN konfiguration k ON k.schluessel = 'locked_at' AND k.saison_id = t.saison_id
  WHERE ($1::date IS NULL OR t.datum = $1::date)
    AND ($2::text IS NULL OR t.wochentag = $2::text)
    AND t.saison_id = $3
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
  LEFT JOIN konfiguration k ON k.schluessel = 'locked_at' AND k.saison_id = t.saison_id
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
// einen Foreign-Key-Fehler beim INSERT). Liefert saison_id mit, damit
// der Aufrufer prüfen kann, dass der Raum zur selben Saison gehört wie
// der Termin (kein Raum-Wechsel über Saisongrenzen hinweg).
const SELECT_RAUM_SQL = `
  SELECT id, name, aud_code, erlaubte_tage, saison_id FROM raeume WHERE id = $1
`;

// ALLE Räume EINER Saison, auch ohne Termin an einem bestimmten Tag
// (Nachfolger von confRaeume, REFERENCE.md Abschnitt 2) — Grundlage für
// die Raum-Auswahl in der Terminverwaltung. $1 = saisonId (Pflicht seit
// 07.09.2026).
const SELECT_RAEUME_SQL = `
  SELECT id, name, aud_code, erlaubte_tage FROM raeume WHERE saison_id = $1 ORDER BY name
`;

const INSERT_TERMIN_SQL = `
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
  RETURNING id
`;

// Legt den Musiker an, falls das Kürzel noch nicht existiert (Annahme:
// gleiches Verhalten wie migrate/lib.js für unbekannte Räume — lieber
// automatisch anlegen als die ganze Anfrage ablehnen, siehe
// PROGRESS.md "Offene Fragen"). Pro Saison unabhängig (siehe
// db/migration-saisons.sql: kuerzel ist nur noch INNERHALB einer Saison
// eindeutig).
const UPSERT_MUSIKER_SQL = `
  INSERT INTO musiker (kuerzel, saison_id) VALUES ($1, $2)
  ON CONFLICT (kuerzel, saison_id) DO UPDATE SET kuerzel = EXCLUDED.kuerzel
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

// Saison (inkl. aktiv-Status) eines bestehenden Termins per ID -- Basis
// für die Archiv-Schreibsperre bei PUT/DELETE (eine Saison, die nicht
// mehr aktiv ist, gilt als Archiv und darf nicht mehr verändert werden,
// siehe REFERENCE.md "Saison-Verwaltung").
const SELECT_TERMIN_SAISON_SQL = `
  SELECT s.id AS saison_id, s.aktiv
  FROM termine t JOIN saisons s ON s.id = t.saison_id
  WHERE t.id = $1
`;

// "Stand sperren" (REFERENCE.md Abschnitt 5): speichert den aktuellen
// Zeitpunkt als locked_at, PRO SAISON ($1 = saisonId seit 07.09.2026).
// Ab da gilt jeder Termin mit updated_at > locked_at als "neu/geändert"
// (siehe SELECT_TERMINE_SQL oben).
const SPERREN_SQL = `
  INSERT INTO konfiguration (saison_id, schluessel, wert) VALUES ($1, 'locked_at', now()::text)
  ON CONFLICT (saison_id, schluessel) DO UPDATE SET wert = EXCLUDED.wert
  RETURNING wert
`;

const SELECT_LOCKED_AT_SQL = `
  SELECT wert FROM konfiguration WHERE saison_id = $1 AND schluessel = 'locked_at'
`;

// Werk-Autocomplete (Phase 8-Erweiterung, siehe REFERENCE.md Abschnitt 16
// und db/migration-werke.sql): sucht sowohl in den Konzertstücken
// (werke, z.B. "401" = Konzert 4, 1. Werk) als auch in den festen
// Ablaufpunkten (werk_vorlagen, z.B. "3" = Dîner). $1 = Suchtext, matcht
// entweder am Anfang der Nummer ODER am Anfang des Namens (Rafi-Feedback:
// beides soll funktionieren -- Nummer eingeben ODER Namensanfang). $2 =
// saisonId (Pflicht seit 07.09.2026, siehe REFERENCE.md
// "Saison-Verwaltung").
const SELECT_WERK_VORSCHLAEGE_SQL = `
  (
    SELECT w.nummer, w.name, NULL::text AS typ, w.dauer_minuten,
      COALESCE(array_agg(m.kuerzel ORDER BY m.kuerzel) FILTER (WHERE m.kuerzel IS NOT NULL), '{}') AS teilnehmer
    FROM werke w
    LEFT JOIN werk_musiker wm ON wm.werk_id = w.id
    LEFT JOIN musiker m ON m.id = wm.musiker_id
    WHERE (w.nummer::text LIKE $1 || '%' OR w.name ILIKE $1 || '%') AND w.saison_id = $2
    GROUP BY w.id
  )
  UNION ALL
  (
    SELECT wv.nummer, wv.name, wv.typ, wv.dauer_minuten,
      COALESCE(array_agg(m.kuerzel ORDER BY m.kuerzel) FILTER (WHERE m.kuerzel IS NOT NULL), '{}') AS teilnehmer
    FROM werk_vorlagen wv
    LEFT JOIN werk_vorlage_musiker wvm ON wvm.werk_vorlage_id = wv.id
    LEFT JOIN musiker m ON m.id = wvm.musiker_id
    WHERE (wv.nummer::text LIKE $1 || '%' OR wv.name ILIKE $1 || '%') AND wv.saison_id = $2
    GROUP BY wv.id
  )
  ORDER BY nummer
  LIMIT 15
`;

module.exports = {
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
};
