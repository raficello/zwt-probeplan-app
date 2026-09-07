'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  berechnePosition,
  ermittleFenster,
  stundenraster,
  abrundenAufStunde,
  aufrundenAufStunde,
} = require('../public/tagesraster');

test('berechnePosition: Start direkt am Fensteranfang ergibt top=0', () => {
  const pos = berechnePosition('2026-10-12T07:00:00', '2026-10-12T08:00:00', '2026-10-12T07:00:00', 1, 0);
  assert.equal(pos.top, 0);
  assert.equal(pos.hoehe, 60);
});

test('berechnePosition: 90 Minuten nach Fensteranfang, pxProMinute=2', () => {
  const pos = berechnePosition('2026-10-12T08:30:00', '2026-10-12T09:00:00', '2026-10-12T07:00:00', 2, 0);
  assert.equal(pos.top, 180); // 90 Min * 2px
  assert.equal(pos.hoehe, 60); // 30 Min * 2px
});

test('berechnePosition: Punkt-Termin (kein end) nutzt start als Ende -> Höhe 0, aber Mindesthöhe greift', () => {
  const pos = berechnePosition('2026-10-12T09:00:00', null, '2026-10-12T07:00:00', 1, 15);
  assert.equal(pos.hoehe, 15);
});

test('berechnePosition: sehr kurzer Termin wird auf Mindesthöhe angehoben', () => {
  const pos = berechnePosition('2026-10-12T09:00:00', '2026-10-12T09:02:00', '2026-10-12T07:00:00', 1, 15);
  assert.equal(pos.hoehe, 15); // 2px wäre kleiner als Mindesthöhe 15
});

test('berechnePosition: Termin vor Fensteranfang ergibt negatives top (Aufrufer entscheidet über Clipping)', () => {
  const pos = berechnePosition('2026-10-12T06:00:00', '2026-10-12T06:30:00', '2026-10-12T07:00:00', 1, 0);
  assert.equal(pos.top, -60);
});

test('ermittleFenster: ohne Termine bleibt es beim Standard-Sichtfenster', () => {
  const fenster = ermittleFenster('2026-10-12', [], '07:00:00', '23:00:00');
  assert.equal(fenster.start, '2026-10-12T07:00:00');
  assert.equal(fenster.ende, '2026-10-12T23:00:00');
});

// Rafi-Feedback, 06.09.2026: "nur diese Stunden angezeigt werden, die auch
// gebraucht werden. Also nicht vor dem ersten und nach dem letzten Termin"
// -- ab jetzt polstern minStart/minEnde ein Fenster mit vorhandenen
// Terminen NICHT mehr auf, sie gelten nur noch als Ersatzwert für einen
// Tag ganz ohne Termine (Test oben).

test('ermittleFenster: ein einzelner Termin ergibt ein Fenster genau um diesen Termin (auf volle Stunden gerundet), NICHT das Standard-Sichtfenster', () => {
  const items = [{ start: '2026-10-12T14:45:00', end: '2026-10-12T15:30:00' }];
  const fenster = ermittleFenster('2026-10-12', items, '07:00:00', '23:00:00');
  assert.equal(fenster.start, '2026-10-12T14:00:00'); // abgerundet
  assert.equal(fenster.ende, '2026-10-12T16:00:00'); // aufgerundet
});

test('ermittleFenster: ein früher Termin bestimmt den Fensteranfang (abgerundet), ignoriert minStart', () => {
  const items = [{ start: '2026-10-12T06:15:00', end: '2026-10-12T06:45:00' }];
  const fenster = ermittleFenster('2026-10-12', items, '07:00:00', '23:00:00');
  assert.equal(fenster.start, '2026-10-12T06:00:00');
  assert.equal(fenster.ende, '2026-10-12T07:00:00');
});

test('ermittleFenster: ein spaeter Termin bestimmt das Fensterende (aufgerundet), ignoriert minEnde', () => {
  const items = [{ start: '2026-10-12T23:30:00', end: '2026-10-12T23:59:00' }];
  const fenster = ermittleFenster('2026-10-12', items, '07:00:00', '23:00:00');
  assert.equal(fenster.start, '2026-10-12T23:00:00');
  assert.equal(fenster.ende, '2026-10-13T00:00:00'); // Rundung über Mitternacht hinweg korrekt
});

test('ermittleFenster: mehrere Termine -> Fenster vom fruehesten Anfang bis zum spaetesten Ende', () => {
  const items = [
    { start: '2026-10-12T14:45:00', end: '2026-10-12T15:30:00' },
    { start: '2026-10-12T09:30:00', end: '2026-10-12T10:15:00' },
    { start: '2026-10-12T18:00:00', end: '2026-10-12T20:00:00' },
  ];
  const fenster = ermittleFenster('2026-10-12', items, '07:00:00', '23:00:00');
  assert.equal(fenster.start, '2026-10-12T09:00:00');
  assert.equal(fenster.ende, '2026-10-12T20:00:00');
});

test('ermittleFenster: Termin exakt auf vollen Stunden bleibt unveraendert (keine unnoetige Rundung)', () => {
  const items = [{ start: '2026-10-12T10:00:00', end: '2026-10-12T11:00:00' }];
  const fenster = ermittleFenster('2026-10-12', items, '07:00:00', '23:00:00');
  assert.equal(fenster.start, '2026-10-12T10:00:00');
  assert.equal(fenster.ende, '2026-10-12T11:00:00');
});

test('ermittleFenster: Punkt-Termine ohne end nutzen start auch fuer die Ende-Berechnung', () => {
  const items = [{ start: '2026-10-12T23:45:00' }];
  const fenster = ermittleFenster('2026-10-12', items, '07:00:00', '23:00:00');
  assert.equal(fenster.ende, '2026-10-13T00:00:00');
});

test('abrundenAufStunde: rundet auf den Beginn der Stunde ab', () => {
  assert.equal(abrundenAufStunde('2026-10-12T14:45:30'), '2026-10-12T14:00:00');
  assert.equal(abrundenAufStunde('2026-10-12T14:00:00'), '2026-10-12T14:00:00'); // schon glatt -> unveraendert
});

test('aufrundenAufStunde: rundet auf den Beginn der naechsten Stunde auf, ausser schon glatt', () => {
  assert.equal(aufrundenAufStunde('2026-10-12T14:00:01'), '2026-10-12T15:00:00');
  assert.equal(aufrundenAufStunde('2026-10-12T23:30:00'), '2026-10-13T00:00:00'); // Tagesgrenze korrekt
  assert.equal(aufrundenAufStunde('2026-10-12T14:00:00'), '2026-10-12T14:00:00'); // schon glatt -> unveraendert
});

test('stundenraster: volle Stunden zwischen Fensteranfang und -ende, inklusive Randstunden', () => {
  const stunden = stundenraster('2026-10-12T07:00:00', '2026-10-12T10:00:00');
  assert.equal(stunden.length, 4); // 07,08,09,10 Uhr
});

test('stundenraster: Fenster beginnt mitten in einer Stunde -> erste volle Stunde danach', () => {
  const stunden = stundenraster('2026-10-12T07:15:00', '2026-10-12T09:00:00');
  assert.equal(stunden.length, 2); // 08:00 und 09:00, NICHT 07:00 (liegt vor Fensteranfang)
});

test('stundenraster: Positionen der zurückgegebenen Stunden passen zu berechnePosition (Rundtrip epoch-konsistent)', () => {
  const fensterStart = '2026-10-12T07:00:00';
  const stunden = stundenraster(fensterStart, '2026-10-12T10:00:00');
  const pos = berechnePosition(stunden[1], stunden[1], fensterStart, 1, 0);
  assert.equal(pos.top, 60); // zweiter Eintrag (08:00) = 60 Minuten nach Fensteranfang 07:00, mit pxProMinute=1
});
