'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { ermittleMusikerAusTerminen, baueMusikerGroupsUndItems } = require('../public/musiker-logik');

function weisseFarbe() {
  return '#ffffff';
}

test('ermittleMusikerAusTerminen: sammelt eindeutige, sortierte Kürzel aus allen Terminen', () => {
  const termine = [
    { teilnehmer: ['CD', 'AB'] },
    { teilnehmer: ['AB', 'GH'] },
    { teilnehmer: [] },
  ];
  assert.deepEqual(ermittleMusikerAusTerminen(termine), ['AB', 'CD', 'GH']);
});

test('ermittleMusikerAusTerminen: leere Liste -> leeres Array', () => {
  assert.deepEqual(ermittleMusikerAusTerminen([]), []);
});

test('baueMusikerGroupsUndItems: normaler Termin erscheint NUR bei Musikern, deren Kürzel in teilnehmer steht', () => {
  const termine = [
    { id: 1, typ: null, werk: 'Beethoven', anfangszeit: '09:00', endzeit: '10:00', teilnehmer: ['AB'] },
  ];
  const { items } = baueMusikerGroupsUndItems(termine, ['AB', 'CD'], '2026-09-07', weisseFarbe);
  assert.equal(items.length, 1);
  assert.equal(items[0].group, 'AB');
});

test('baueMusikerGroupsUndItems: WICHTIGE REGEL — Kzt erscheint bei JEDEM ausgewählten Musiker, auch ohne Kürzel in teilnehmer', () => {
  // Diese Regel wurde laut REFERENCE.md in der alten Sheet-Historie
  // mehrfach falsch implementiert — deshalb hier explizit als eigener
  // Test, nicht nur implizit über andere Fälle.
  const termine = [
    { id: 1, typ: 'Kzt', werk: 'Konzertblock Abend', anfangszeit: '14:00', endzeit: '14:00', teilnehmer: [] },
  ];
  const { items } = baueMusikerGroupsUndItems(termine, ['AB', 'CD', 'GH'], '2026-09-07', weisseFarbe);
  assert.equal(items.length, 3);
  const gruppen = items.map((i) => i.group).sort();
  assert.deepEqual(gruppen, ['AB', 'CD', 'GH']);
});

test('baueMusikerGroupsUndItems: Typ=K wird NORMAL gefiltert, keine Sonderbehandlung wie Kzt', () => {
  // Wichtige Abgrenzung: nur Kzt hat die "für alle sichtbar"-Regel, K
  // (ein einzelnes Konzertstück innerhalb eines Kzt-Blocks) NICHT.
  const termine = [
    { id: 1, typ: 'K', werk: 'Brahms (Konzert)', anfangszeit: '14:00', endzeit: '14:20', teilnehmer: ['AB'] },
  ];
  const { items } = baueMusikerGroupsUndItems(termine, ['AB', 'CD'], '2026-09-07', weisseFarbe);
  assert.equal(items.length, 1);
  assert.equal(items[0].group, 'AB');
});

test('baueMusikerGroupsUndItems: derselbe Termin bei zwei Musikern bekommt zwei Items mit unterschiedlicher, eindeutiger ID', () => {
  const termine = [
    { id: 5, typ: null, werk: 'Duo', anfangszeit: '09:00', endzeit: '10:00', teilnehmer: ['AB', 'CD'] },
  ];
  const { items } = baueMusikerGroupsUndItems(termine, ['AB', 'CD'], '2026-09-07', weisseFarbe);
  assert.equal(items.length, 2);
  const ids = items.map((i) => i.id);
  assert.equal(new Set(ids).size, 2);
});

test('baueMusikerGroupsUndItems: Musiker ohne passende Termine bekommt trotzdem eine (leere) Spalte', () => {
  const termine = [{ id: 1, typ: null, werk: 'X', anfangszeit: '09:00', endzeit: '10:00', teilnehmer: ['AB'] }];
  const { groups, items } = baueMusikerGroupsUndItems(termine, ['AB', 'ZZ'], '2026-09-07', weisseFarbe);
  assert.deepEqual(groups.map((g) => g.id), ['AB', 'ZZ']);
  assert.equal(items.filter((i) => i.group === 'ZZ').length, 0);
});

test('baueMusikerGroupsUndItems: Kzt-Termin (Anfangszeit=Endzeit) wird als Punkt dargestellt', () => {
  const termine = [{ id: 1, typ: 'Kzt', werk: 'Block', anfangszeit: '14:00', endzeit: '14:00', teilnehmer: [] }];
  const { items } = baueMusikerGroupsUndItems(termine, ['AB'], '2026-09-07', weisseFarbe);
  assert.equal(items[0].type, 'point');
  assert.equal(items[0].end, undefined);
});
