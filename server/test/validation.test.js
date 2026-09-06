'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { timeToMinutes, parseTerminInput, findKonflikte, raumTagErlaubt } = require('../validation');

function validBody(overrides) {
  return {
    wochentag: 'Mo',
    datum: '2026-09-07',
    anfangszeit: '09:00',
    endzeit: '10:30',
    raumId: 1,
    typ: '',
    werk: 'Beethoven Sinfonie Nr. 5',
    teilnehmer: ['AB', 'CD'],
    ...overrides,
  };
}

test('timeToMinutes: parst HH:MM korrekt', () => {
  assert.equal(timeToMinutes('00:00'), 0);
  assert.equal(timeToMinutes('09:30'), 570);
  assert.equal(timeToMinutes('23:59'), 1439);
});

test('timeToMinutes: ungültiges Format ergibt null', () => {
  assert.equal(timeToMinutes('9:30'), null);
  assert.equal(timeToMinutes('24:00'), null);
  assert.equal(timeToMinutes('abc'), null);
});

test('timeToMinutes: akzeptiert "HH:MM:SS", wie es node-postgres für time-Spalten liefert (Regressionstest)', () => {
  // Siehe PROGRESS.md: dieser Fall führte zu einem echten Bug, bei dem
  // Konflikte aus der Datenbank gelesener Termine unbemerkt ignoriert
  // wurden, weil timeToMinutes für "09:00:00" fälschlich null lieferte.
  assert.equal(timeToMinutes('09:00:00'), 540);
  assert.equal(timeToMinutes('23:59:59'), 1439);
});

test('parseTerminInput: gültiger Body liefert normalisierten value ohne errors', () => {
  const result = parseTerminInput(validBody());
  assert.ok(result.value);
  assert.equal(result.errors, undefined);
  assert.deepEqual(result.value.teilnehmer, ['AB', 'CD']);
});

test('parseTerminInput: fehlende Pflichtfelder werden gesammelt gemeldet', () => {
  const result = parseTerminInput({});
  assert.ok(result.errors.length >= 5);
});

test('parseTerminInput: endzeit == anfangszeit ist erlaubt (Kzt-Blockkopf-Konvention)', () => {
  const result = parseTerminInput(
    validBody({ typ: 'Kzt', anfangszeit: '14:00', endzeit: '14:00', teilnehmer: undefined })
  );
  assert.ok(result.value);
  assert.deepEqual(result.value.teilnehmer, []);
});

test('parseTerminInput: endzeit vor anfangszeit ist ein Fehler', () => {
  const result = parseTerminInput(validBody({ anfangszeit: '10:00', endzeit: '09:00' }));
  assert.ok(result.errors.some((e) => e.includes('endzeit')));
});

test('parseTerminInput: Typ=Kzt ignoriert mitgeschickte Teilnehmer (Business-Regel, kein Fehler)', () => {
  const result = parseTerminInput(validBody({ typ: 'Kzt', teilnehmer: ['AB'] }));
  assert.ok(result.value);
  assert.deepEqual(result.value.teilnehmer, []);
});

test('parseTerminInput: unbekannter Typ ist ein Fehler', () => {
  const result = parseTerminInput(validBody({ typ: 'Foo' }));
  assert.ok(result.errors.some((e) => e.includes('typ')));
});

test('parseTerminInput: leeres werk ist ein Fehler', () => {
  const result = parseTerminInput(validBody({ werk: '   ' }));
  assert.ok(result.errors.some((e) => e.includes('werk')));
});

test('findKonflikte: keine bestehenden Termine -> keine Konflikte', () => {
  assert.deepEqual(findKonflikte([], { anfangszeit: '09:00', endzeit: '10:00' }, 0), []);
});

test('findKonflikte: direkte Überschneidung wird erkannt', () => {
  const bestehend = [{ id: 1, anfangszeit: '09:00', endzeit: '10:00', werk: 'A' }];
  const konflikte = findKonflikte(bestehend, { anfangszeit: '09:30', endzeit: '11:00' }, 0);
  assert.equal(konflikte.length, 1);
  assert.match(konflikte[0], /#1/);
});

test('findKonflikte: exakt anschliessend ohne Puffer ist OK', () => {
  const bestehend = [{ id: 1, anfangszeit: '09:00', endzeit: '10:00', werk: 'A' }];
  const konflikte = findKonflikte(bestehend, { anfangszeit: '10:00', endzeit: '11:00' }, 0);
  assert.deepEqual(konflikte, []);
});

test('findKonflikte: zu geringer Abstand bei gesetztem Puffer wird erkannt', () => {
  const bestehend = [{ id: 1, anfangszeit: '09:00', endzeit: '10:00', werk: 'A' }];
  const konflikte = findKonflikte(bestehend, { anfangszeit: '10:05', endzeit: '11:00' }, 15);
  assert.equal(konflikte.length, 1);
});

test('findKonflikte: ausreichender Abstand bei gesetztem Puffer ist OK', () => {
  const bestehend = [{ id: 1, anfangszeit: '09:00', endzeit: '10:00', werk: 'A' }];
  const konflikte = findKonflikte(bestehend, { anfangszeit: '10:15', endzeit: '11:00' }, 15);
  assert.deepEqual(konflikte, []);
});

test('findKonflikte: Termin komplett davor mit ausreichend Abstand ist OK', () => {
  const bestehend = [{ id: 1, anfangszeit: '09:00', endzeit: '10:00', werk: 'A' }];
  const konflikte = findKonflikte(bestehend, { anfangszeit: '07:00', endzeit: '08:45' }, 15);
  assert.deepEqual(konflikte, []);
});

test('findKonflikte: erkennt Konflikte auch mit "HH:MM:SS"-Zeiten aus der Datenbank (Regressionstest)', () => {
  // Bug-Nachbau: bestehende Termine kamen aus Postgres mit Sekunden
  // ("09:00:00"), das brachte die Konfliktprüfung zum Schweigen (siehe
  // PROGRESS.md). Muss jetzt wieder einen Konflikt erkennen.
  const bestehend = [{ id: 1, anfangszeit: '09:00:00', endzeit: '10:00:00', werk: 'A' }];
  const konflikte = findKonflikte(bestehend, { anfangszeit: '09:30', endzeit: '11:00' }, 15);
  assert.equal(konflikte.length, 1);
});

test('findKonflikte: wirft bei ungültiger Zeit statt still falsch zu rechnen', () => {
  const bestehend = [{ id: 1, anfangszeit: 'kaputt', endzeit: '10:00', werk: 'A' }];
  assert.throws(() => findKonflikte(bestehend, { anfangszeit: '09:30', endzeit: '11:00' }, 15));
});

test('raumTagErlaubt: null (keine Beschränkung) erlaubt jeden Wochentag', () => {
  assert.equal(raumTagErlaubt(null, 'So'), true);
});

test('raumTagErlaubt: leeres Array (keine Beschränkung) erlaubt jeden Wochentag', () => {
  assert.equal(raumTagErlaubt([], 'So'), true);
});

test('raumTagErlaubt: Wochentag in der Liste ist erlaubt', () => {
  assert.equal(raumTagErlaubt(['Mo', 'Mi', 'Fr'], 'Mi'), true);
});

test('raumTagErlaubt: Wochentag NICHT in der Liste ist nicht erlaubt', () => {
  assert.equal(raumTagErlaubt(['Mo', 'Mi', 'Fr'], 'Do'), false);
});
