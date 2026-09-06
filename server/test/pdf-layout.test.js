'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { ordneLanesZu, gruppiereNachRaumMitLanes, filterTermineFuerMusiker } = require('../pdf-layout');

function termin(overrides) {
  return { id: 1, werk: 'X', anfangszeit: '09:00', endzeit: '10:00', ...overrides };
}

test('ordneLanesZu: nicht überlappende Termine bekommen alle Lane 0', () => {
  const termine = [
    termin({ id: 1, anfangszeit: '09:00', endzeit: '10:00' }),
    termin({ id: 2, anfangszeit: '10:00', endzeit: '11:00' }),
    termin({ id: 3, anfangszeit: '11:30', endzeit: '12:00' }),
  ];
  const { termine: mitLanes, lanesGesamt } = ordneLanesZu(termine);
  assert.deepEqual(mitLanes.map((t) => t.lane), [0, 0, 0]);
  assert.equal(lanesGesamt, 1);
});

test('ordneLanesZu: zwei überlappende Termine bekommen unterschiedliche Lanes', () => {
  const termine = [
    termin({ id: 1, anfangszeit: '09:00', endzeit: '10:00' }),
    termin({ id: 2, anfangszeit: '09:30', endzeit: '10:30' }),
  ];
  const { termine: mitLanes, lanesGesamt } = ordneLanesZu(termine);
  const lanes = mitLanes.map((t) => t.lane).sort();
  assert.deepEqual(lanes, [0, 1]);
  assert.equal(lanesGesamt, 2);
});

test('ordneLanesZu: drei sich gegenseitig überlappende Termine brauchen drei Lanes', () => {
  const termine = [
    termin({ id: 1, anfangszeit: '09:00', endzeit: '11:00' }),
    termin({ id: 2, anfangszeit: '09:30', endzeit: '10:30' }),
    termin({ id: 3, anfangszeit: '09:45', endzeit: '10:15' }),
  ];
  const { lanesGesamt } = ordneLanesZu(termine);
  assert.equal(lanesGesamt, 3);
});

test('ordneLanesZu: Termin, der genau endet wenn der nächste beginnt, teilt sich die Lane', () => {
  const termine = [
    termin({ id: 1, anfangszeit: '09:00', endzeit: '10:00' }),
    termin({ id: 2, anfangszeit: '10:00', endzeit: '11:00' }),
  ];
  const { termine: mitLanes, lanesGesamt } = ordneLanesZu(termine);
  assert.deepEqual(mitLanes.map((t) => t.lane), [0, 0]);
  assert.equal(lanesGesamt, 1);
});

test('ordneLanesZu: eine frei gewordene Lane wird wiederverwendet, nicht immer neue angehängt', () => {
  const termine = [
    termin({ id: 1, anfangszeit: '09:00', endzeit: '09:30' }), // Lane 0
    termin({ id: 2, anfangszeit: '09:00', endzeit: '09:30' }), // Lane 1 (überlappt mit 1)
    termin({ id: 3, anfangszeit: '10:00', endzeit: '10:30' }), // Lane 0 (1 ist vorbei, wird wiederverwendet)
  ];
  const { termine: mitLanes, lanesGesamt } = ordneLanesZu(termine);
  const laneVonId = Object.fromEntries(mitLanes.map((t) => [t.id, t.lane]));
  assert.equal(laneVonId[3], 0);
  assert.equal(lanesGesamt, 2);
});

test('ordneLanesZu: leere Liste', () => {
  const { termine, lanesGesamt } = ordneLanesZu([]);
  assert.deepEqual(termine, []);
  assert.equal(lanesGesamt, 1);
});

test('gruppiereNachRaumMitLanes: gruppiert korrekt nach Raum und sortiert nach Raumname', () => {
  const termine = [
    termin({ id: 1, raum: { id: 2, name: 'Kursaal' } }),
    termin({ id: 2, raum: { id: 1, name: 'Kirchgemeindehaus' } }),
    termin({ id: 3, raum: { id: 2, name: 'Kursaal' }, anfangszeit: '11:00', endzeit: '12:00' }),
  ];
  const gruppen = gruppiereNachRaumMitLanes(termine);
  assert.equal(gruppen.length, 2);
  assert.deepEqual(gruppen.map((g) => g.raum.name), ['Kirchgemeindehaus', 'Kursaal']);
  assert.equal(gruppen[1].termine.length, 2);
});

test('filterTermineFuerMusiker: normaler Termin nur bei passendem Kürzel', () => {
  const termine = [termin({ id: 1, teilnehmer: ['AB'] })];
  assert.equal(filterTermineFuerMusiker(termine, 'AB').length, 1);
  assert.equal(filterTermineFuerMusiker(termine, 'CD').length, 0);
});

test('filterTermineFuerMusiker: WICHTIGE REGEL — Kzt erscheint für JEDEN Musiker, auch ohne Kürzel in teilnehmer', () => {
  const termine = [termin({ id: 1, typ: 'Kzt', teilnehmer: [] })];
  assert.equal(filterTermineFuerMusiker(termine, 'AB').length, 1);
  assert.equal(filterTermineFuerMusiker(termine, 'ZZ').length, 1);
});

test('filterTermineFuerMusiker: Typ=K wird normal gefiltert, keine Kzt-Sonderbehandlung', () => {
  const termine = [termin({ id: 1, typ: 'K', teilnehmer: ['AB'] })];
  assert.equal(filterTermineFuerMusiker(termine, 'AB').length, 1);
  assert.equal(filterTermineFuerMusiker(termine, 'ZZ').length, 0);
});
