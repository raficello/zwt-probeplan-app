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
