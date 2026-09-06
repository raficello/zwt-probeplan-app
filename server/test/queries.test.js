'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { groupTermineRows } = require('../queries');

function makeRow(overrides) {
  return {
    id: 1,
    wochentag: 'Mo',
    datum: '2026-09-07',
    anfangszeit: '09:00:00',
    endzeit: '10:00:00',
    typ: null,
    werk: 'Beethoven Sinfonie Nr. 5',
    bemerkungen: null,
    created_at: '2026-09-01T00:00:00.000Z',
    updated_at: '2026-09-01T00:00:00.000Z',
    raum_id: 1,
    raum_name: 'Kursaal',
    aud_code: '802',
    musiker_kuerzel: null,
    ...overrides,
  };
}

test('groupTermineRows: mehrere Musiker-Zeilen desselben Termins werden zu einem Termin mit Teilnehmer-Array', () => {
  const rows = [
    makeRow({ musiker_kuerzel: 'AB' }),
    makeRow({ musiker_kuerzel: 'CD' }),
  ];
  const termine = groupTermineRows(rows);
  assert.equal(termine.length, 1);
  assert.deepEqual(termine[0].teilnehmer, ['AB', 'CD']);
  assert.deepEqual(termine[0].raum, { id: 1, name: 'Kursaal', audCode: '802' });
});

test('groupTermineRows: Termin ohne Teilnehmer (z.B. Typ=Kzt) bekommt leeres Teilnehmer-Array, nicht [null]', () => {
  const rows = [makeRow({ typ: 'Kzt', werk: 'Konzertblock Abend', musiker_kuerzel: null })];
  const termine = groupTermineRows(rows);
  assert.equal(termine.length, 1);
  assert.deepEqual(termine[0].teilnehmer, []);
  assert.equal(termine[0].typ, 'Kzt');
});

test('groupTermineRows: mehrere unterschiedliche Termine bleiben getrennt und in Reihenfolge', () => {
  const rows = [
    makeRow({ id: 1, musiker_kuerzel: 'AB' }),
    makeRow({ id: 2, anfangszeit: '10:45:00', werk: 'GP Brahms', musiker_kuerzel: 'AB' }),
    makeRow({ id: 2, anfangszeit: '10:45:00', werk: 'GP Brahms', musiker_kuerzel: 'GH' }),
  ];
  const termine = groupTermineRows(rows);
  assert.equal(termine.length, 2);
  assert.deepEqual(termine.map((t) => t.id), [1, 2]);
  assert.deepEqual(termine[1].teilnehmer, ['AB', 'GH']);
});

test('groupTermineRows: leere Eingabe ergibt leeres Array', () => {
  assert.deepEqual(groupTermineRows([]), []);
});

test('groupTermineRows: datum als JS-Date-Objekt (wie es node-postgres für "date"-Spalten liefert) wird zu "YYYY-MM-DD" normalisiert (Regressionstest)', () => {
  // Bug-Nachbau: node-postgres liefert `date`-Spalten als Date-Objekt
  // (Mitternacht UTC). JSON.stringify macht daraus einen vollen
  // ISO-Zeitstempel ("2026-09-07T00:00:00.000Z"), was ein <input
  // type="date"> in der Terminverwaltung (Phase 8) leer liess, weil das
  // Feld nur "YYYY-MM-DD" akzeptiert (per echtem Browser-Test gefunden).
  const rows = [makeRow({ datum: new Date('2026-09-07T00:00:00.000Z') })];
  const termine = groupTermineRows(rows);
  assert.equal(termine[0].datum, '2026-09-07');
});

test('groupTermineRows: datum als String bleibt unverändert (schon "YYYY-MM-DD")', () => {
  const termine = groupTermineRows([makeRow({ datum: '2026-09-07' })]);
  assert.equal(termine[0].datum, '2026-09-07');
});
