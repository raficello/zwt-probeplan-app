'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  expandTageRange,
  istEchterTermin,
  parseTeilnehmer,
  buildModel,
} = require('../lib');

test('expandTageRange: leer/null/undefined -> []', () => {
  assert.deepEqual(expandTageRange(''), []);
  assert.deepEqual(expandTageRange(null), []);
  assert.deepEqual(expandTageRange(undefined), []);
});

test('expandTageRange: Komma-Liste', () => {
  assert.deepEqual(expandTageRange('Mo,Mi,Fr'), ['Mo', 'Mi', 'Fr']);
});

test('expandTageRange: einfacher Bereich', () => {
  assert.deepEqual(expandTageRange('Mo-Mi'), ['Mo', 'Di', 'Mi']);
});

test('expandTageRange: Bereich über das Wochenende', () => {
  assert.deepEqual(expandTageRange('So-Di'), ['So', 'Mo', 'Di']);
});

test('expandTageRange: gemischt', () => {
  assert.deepEqual(expandTageRange('Mo-Mi,Fr'), ['Mo', 'Di', 'Mi', 'Fr']);
});

test('expandTageRange: unbekannter Code wirft', () => {
  assert.throws(() => expandTageRange('Xy'));
});

test('istEchterTermin: vollständige Zeile ist echt', () => {
  assert.equal(
    istEchterTermin({ anfangszeit: '09:00', endzeit: '10:00', werk: 'Test' }),
    true
  );
});

test('istEchterTermin: fehlende Anfangszeit ist Leerzeile', () => {
  assert.equal(
    istEchterTermin({ anfangszeit: '', endzeit: '10:00', werk: 'Test' }),
    false
  );
});

test('istEchterTermin: fehlendes Werk ist Leerzeile', () => {
  assert.equal(
    istEchterTermin({ anfangszeit: '09:00', endzeit: '10:00', werk: '' }),
    false
  );
});

test('parseTeilnehmer: leerzeichen-getrennt', () => {
  assert.deepEqual(parseTeilnehmer('AB CD  EF'), ['AB', 'CD', 'EF']);
});

test('parseTeilnehmer: leer -> []', () => {
  assert.deepEqual(parseTeilnehmer(''), []);
  assert.deepEqual(parseTeilnehmer(null), []);
});

test('buildModel: sample-Daten ergeben erwartete Zählungen und Kzt hat leere Teilnehmer', () => {
  const master = require('../sample-master.json');
  const confRaeume = require('../sample-confraeume.json');
  const model = buildModel(master, confRaeume);

  // 7 Rohzeilen insgesamt (3 im Mo-Block inkl. 1 Leerzeile, 4 im Di-Block),
  // davon 6 echte Termine.
  assert.equal(model.termine.length, 6);

  // Kursaal + Kirchgemeindehaus aus confRaeume, plus "Mehrzweckhalle" aus
  // dem Master-Sheet automatisch angelegt (unbekannter Raum -> Warnung).
  assert.equal(model.raeume.length, 3);
  const mehrzweckhalle = model.raeume.find((r) => r.name === 'Mehrzweckhalle');
  assert.ok(mehrzweckhalle);
  assert.deepEqual(mehrzweckhalle.erlaubteTage, []);

  const kztTermin = model.termine.find((t) => t.typ === 'Kzt');
  assert.ok(kztTermin);
  assert.deepEqual(kztTermin.teilnehmer, []);

  assert.ok(model.warnings.some((w) => w.includes('Mehrzweckhalle')));

  // Musiker:innen: AB, CD, EF, GH, IJ (Kzt-Termin trägt keine bei)
  const kuerzel = model.musiker.map((m) => m.kuerzel).sort();
  assert.deepEqual(kuerzel, ['AB', 'CD', 'EF', 'GH', 'IJ']);
});

test('buildModel: Termin ohne Raumangabe wird übersprungen und gewarnt', () => {
  const master = [
    {
      wochentag: 'Mo',
      datum: '2026-09-07',
      termine: [
        {
          anfangszeit: '09:00',
          endzeit: '10:00',
          werk: 'Ohne Raum',
          teilnehmer: 'AB',
          ort: '',
        },
      ],
    },
  ];
  const model = buildModel(master, []);
  assert.equal(model.termine.length, 0);
  assert.ok(model.warnings.some((w) => w.includes('ohne Raumangabe')));
});
