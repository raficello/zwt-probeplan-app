'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { terminFarbe } = require('../public/color');

test('terminFarbe: Typ=Kzt ist grün, unabhängig vom Werk', () => {
  assert.equal(terminFarbe({ typ: 'Kzt', werk: 'GP irgendwas' }), '#b6f2b6');
});

test('terminFarbe: Typ=K ist helles Grün', () => {
  assert.equal(terminFarbe({ typ: 'K', werk: 'Beethoven (Konzert)' }), '#d7f2d7');
});

test('terminFarbe: Werk beginnt mit "GP" ist gelb', () => {
  assert.equal(terminFarbe({ typ: null, werk: 'GP Brahms Violinkonzert' }), '#fff3b0');
});

test('terminFarbe: "GP" mitten im Wort zählt NICHT (nur am Anfang)', () => {
  assert.equal(terminFarbe({ typ: null, werk: 'Vorbereitung GP' }), '#ffffff');
});

test('terminFarbe: Sonderwörter in Werk oder Bemerkungen sind rosa', () => {
  assert.equal(terminFarbe({ typ: null, werk: 'Aufbau Bühne' }), '#fbd7ea');
  assert.equal(terminFarbe({ typ: null, werk: 'X', bemerkungen: 'Apero danach' }), '#fbd7ea');
  assert.equal(terminFarbe({ typ: null, werk: 'Logistik-Team' }), '#fbd7ea');
  assert.equal(terminFarbe({ typ: null, werk: 'Musikeressen' }), '#fbd7ea');
});

test('terminFarbe: "stimmung" in Werk oder Bemerkungen ist gelb', () => {
  assert.equal(terminFarbe({ typ: null, werk: 'Flügelstimmung' }), '#fff3b0');
  assert.equal(terminFarbe({ typ: null, werk: 'X', bemerkungen: 'danach Stimmung' }), '#fff3b0');
});

test('terminFarbe: normaler Termin ohne Sonderregel ist weiss', () => {
  assert.equal(terminFarbe({ typ: null, werk: 'Beethoven Sinfonie Nr. 5' }), '#ffffff');
  assert.equal(terminFarbe({ typ: '', werk: 'Normale Probe' }), '#ffffff');
});

test('terminFarbe: Reihenfolge — Kzt hat Vorrang vor "GP"-Regel', () => {
  assert.equal(terminFarbe({ typ: 'Kzt', werk: 'GP-Block' }), '#b6f2b6');
});

test('terminFarbe: fehlende bemerkungen/werk führen nicht zum Absturz', () => {
  assert.equal(terminFarbe({ typ: null }), '#ffffff');
});

test('terminFarbe: neu=true ist orange und hat Vorrang vor JEDER anderen Regel (REFERENCE.md Abschnitt 5+6)', () => {
  assert.equal(terminFarbe({ typ: 'Kzt', werk: 'X', neu: true }), '#ffd9a0');
  assert.equal(terminFarbe({ typ: null, werk: 'GP Brahms', neu: true }), '#ffd9a0');
  assert.equal(terminFarbe({ typ: null, werk: 'Aufbau', neu: true }), '#ffd9a0');
  assert.equal(terminFarbe({ typ: null, werk: 'Normale Probe', neu: true }), '#ffd9a0');
});

test('terminFarbe: neu=false (oder fehlend) ändert nichts am gewohnten Verhalten', () => {
  assert.equal(terminFarbe({ typ: 'Kzt', werk: 'X', neu: false }), '#b6f2b6');
  assert.equal(terminFarbe({ typ: null, werk: 'Normale Probe' }), '#ffffff');
});
