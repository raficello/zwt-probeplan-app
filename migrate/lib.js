'use strict';

// Reine, DB-freie Kernlogik für die Migration des Google-Sheets
// "ZwT 2026 - Probeplan" in das relationale Schema (db/schema.sql).
// Siehe REFERENCE.md Abschnitt 11 für den Kontext.

const TAGE = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

/**
 * Expandiert einen confRaeume-Spalte-N-String ("erlaubte Tage") in ein
 * Array von Tages-Codes. Unterstützt:
 *   - leer/null/undefined  -> [] (bedeutet: alle Tage erlaubt)
 *   - Einzeltage, Komma-getrennt: "Mo,Mi,Fr" -> ["Mo","Mi","Fr"]
 *   - Bereiche: "Mo-Mi" -> ["Mo","Di","Mi"]
 *   - Bereiche über das Wochenende hinweg: "So-Di" -> ["So","Mo","Di"]
 *   - Mischungen: "Mo-Mi,Fr" -> ["Mo","Di","Mi","Fr"]
 */
function expandTageRange(raw) {
  if (raw === null || raw === undefined) return [];
  const trimmed = String(raw).trim();
  if (trimmed === '') return [];

  const result = [];
  const teile = trimmed.split(',').map((t) => t.trim()).filter(Boolean);

  for (const teil of teile) {
    if (teil.includes('-')) {
      const [von, bis] = teil.split('-').map((t) => t.trim());
      const vonIdx = TAGE.indexOf(von);
      const bisIdx = TAGE.indexOf(bis);
      if (vonIdx === -1 || bisIdx === -1) {
        throw new Error(`Unbekannter Tages-Code in Bereich "${teil}"`);
      }
      let i = vonIdx;
      while (true) {
        if (!result.includes(TAGE[i])) result.push(TAGE[i]);
        if (i === bisIdx) break;
        i = (i + 1) % TAGE.length;
      }
    } else {
      if (!TAGE.includes(teil)) {
        throw new Error(`Unbekannter Tages-Code "${teil}"`);
      }
      if (!result.includes(teil)) result.push(teil);
    }
  }

  return result;
}

/**
 * Leerzeilen-Filter (REFERENCE.md Abschnitt 1, letzter Satz): ein Termin
 * zählt nur als echt, wenn Anfangszeit, Endzeit und Werk gesetzt sind.
 */
function istEchterTermin(row) {
  if (!row) return false;
  const hatWert = (v) => v !== null && v !== undefined && String(v).trim() !== '';
  return hatWert(row.anfangszeit) && hatWert(row.endzeit) && hatWert(row.werk);
}

/**
 * Zerlegt die Teilnehmer-Spalte (leerzeichen-getrennte Kürzel) in ein
 * Array eindeutiger, getrimmter Kürzel. Typ='Kzt' hat laut Spezifikation
 * immer ein leeres Teilnehmer-Feld -> liefert dann [].
 */
function parseTeilnehmer(raw) {
  if (raw === null || raw === undefined) return [];
  return String(raw)
    .split(/\s+/)
    .map((k) => k.trim())
    .filter(Boolean);
}

/**
 * Normalisiert Rohdaten (Array von Tagesblöcken aus dem Master-Sheet +
 * confRaeume-Array) in ein modell-fertiges {raeume, musiker, termine,
 * warnings}.
 *
 * masterBloecke: Array von { wochentag, datum, termine: [ { anfangszeit,
 *   endzeit, aud, typ, werk, teilnehmer, ort, bemerkungen } ] }
 * confRaeume: Array von { name, erlaubteTage } (bereits als roher Text
 *   aus Spalte N, wird hier mit expandTageRange verarbeitet)
 */
function buildModel(masterBloecke, confRaeume) {
  const warnings = [];

  // Räume aus confRaeume aufbauen
  const raeumeByName = new Map();
  for (const r of confRaeume || []) {
    const name = String(r.name || '').trim();
    if (!name) continue;
    let erlaubteTage;
    try {
      erlaubteTage = expandTageRange(r.erlaubteTage);
    } catch (err) {
      warnings.push(
        `Raum "${name}": ungültige "erlaubte Tage"-Angabe (${err.message}) — als "alle Tage erlaubt" behandelt.`
      );
      erlaubteTage = [];
    }
    raeumeByName.set(name, { name, audCode: null, erlaubteTage });
  }

  const musikerByKuerzel = new Map();
  const termine = [];

  for (const block of masterBloecke || []) {
    const { wochentag, datum } = block;
    for (const row of block.termine || []) {
      if (!istEchterTermin(row)) continue;

      const ortName = String(row.ort || '').trim();
      let raum = ortName ? raeumeByName.get(ortName) : undefined;
      if (ortName && !raum) {
        warnings.push(
          `Unbekannter Raum "${ortName}" (Tag ${wochentag}, Werk "${row.werk}") — automatisch angelegt, ohne Tages-Einschränkung.`
        );
        raum = { name: ortName, audCode: null, erlaubteTage: [] };
        raeumeByName.set(ortName, raum);
      } else if (!ortName) {
        warnings.push(
          `Termin ohne Raumangabe (Tag ${wochentag}, Werk "${row.werk}") — übersprungen.`
        );
        continue;
      }

      if (row.aud !== undefined && row.aud !== null && String(row.aud).trim() !== '') {
        const audCode = String(row.aud).trim();
        if (raum.audCode && raum.audCode !== audCode) {
          warnings.push(
            `Raum "${raum.name}" hat widersprüchliche Aud-Codes ("${raum.audCode}" vs "${audCode}") — erster Wert behalten.`
          );
        } else {
          raum.audCode = raum.audCode || audCode;
        }
      }

      const typ = row.typ ? String(row.typ).trim() : null;
      const teilnehmer = typ === 'Kzt' ? [] : parseTeilnehmer(row.teilnehmer);

      for (const kuerzel of teilnehmer) {
        if (!musikerByKuerzel.has(kuerzel)) {
          musikerByKuerzel.set(kuerzel, { kuerzel, name: null });
        }
      }

      termine.push({
        wochentag,
        datum,
        anfangszeit: row.anfangszeit,
        endzeit: row.endzeit,
        raumName: raum.name,
        typ: typ || null,
        werk: String(row.werk).trim(),
        bemerkungen: row.bemerkungen ? String(row.bemerkungen).trim() : null,
        teilnehmer,
      });
    }
  }

  return {
    raeume: Array.from(raeumeByName.values()),
    musiker: Array.from(musikerByKuerzel.values()),
    termine,
    warnings,
  };
}

module.exports = {
  TAGE,
  expandTageRange,
  istEchterTermin,
  parseTeilnehmer,
  buildModel,
};
