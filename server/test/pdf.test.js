'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const os = require('node:os');
const { execFileSync } = require('node:child_process');
const { erzeugeGesamtplanPdf, erzeugeMusikerplanPdf, zeitZuX, formatiereDatum } = require('../pdf');

// Für den echten Inhaltscheck wird `pdftotext` (poppler-utils) per
// Shell-Aufruf genutzt statt der npm-Bibliothek `pdf-parse` — die
// erwies sich als inkompatibel mit von pdfkit erzeugten PDFs (meldet
// "bad XRef entry" selbst bei einem minimalen "Hallo Welt"-PDF, obwohl
// `qpdf --check` und `pdftotext` dieselbe Datei klaglos akzeptieren und
// den Text korrekt extrahieren — siehe REFERENCE.md Abschnitt 13).
function extrahierePdfText(buffer) {
  const tmpFile = path.join(os.tmpdir(), `pdf-test-${process.pid}-${Date.now()}.pdf`);
  fs.writeFileSync(tmpFile, buffer);
  try {
    return execFileSync('pdftotext', [tmpFile, '-'], { encoding: 'utf8' });
  } finally {
    fs.unlinkSync(tmpFile);
  }
}

test('formatiereDatum: formatiert YYYY-MM-DD als DD.MM.YYYY', () => {
  assert.equal(formatiereDatum('2026-09-07'), '07.09.2026');
});

test('formatiereDatum: funktioniert auch mit vollem ISO-Timestamp (wie aus Postgres)', () => {
  assert.equal(formatiereDatum('2026-09-07T00:00:00.000Z'), '07.09.2026');
});

test('zeitZuX: 07:00 (Start der Achse) liegt am linken Rand des Plots', () => {
  const x = zeitZuX('07:00', 1000);
  assert.ok(x >= 100 && x < 105, `x=${x} sollte nahe am Plot-Start liegen`);
});

test('zeitZuX: spätere Zeit liegt weiter rechts', () => {
  const x1 = zeitZuX('09:00', 1000);
  const x2 = zeitZuX('15:00', 1000);
  assert.ok(x2 > x1);
});

// Echter End-to-End-Test: erzeugt ein tatsächliches PDF und liest den
// Text daraus wieder aus (mit pdf-parse), statt sich nur auf "die
// Funktion wirft keinen Fehler" zu verlassen — siehe REFERENCE.md
// Abschnitt 13 zur Lehre "Unit-Tests mit Mock-Daten reichen nicht".
test('erzeugeGesamtplanPdf: echtes PDF enthält Raum- und Terminnamen als Text', async () => {
  const termine = [
    {
      id: 1,
      werk: 'Beethoven Sinfonie Nr. 5',
      anfangszeit: '09:00',
      endzeit: '10:30',
      typ: null,
      teilnehmer: ['AB'],
      raum: { id: 1, name: 'Kursaal' },
    },
    {
      id: 2,
      werk: 'GP Brahms Violinkonzert',
      anfangszeit: '10:00',
      endzeit: '11:00',
      typ: 'GP',
      teilnehmer: [],
      raum: { id: 2, name: 'Kirchgemeindehaus' },
    },
  ];

  const buffer = await erzeugeGesamtplanPdf({ datum: '2026-09-07', wochentag: 'Mo', termine });

  assert.ok(buffer.length > 500, 'PDF sollte nicht trivial leer sein');
  assert.equal(buffer.subarray(0, 5).toString('latin1'), '%PDF-', 'Datei muss mit PDF-Magic-Bytes beginnen');

  // `pdftotext` (poppler-utils) ist nur in der Entwicklungsumgebung
  // vorhanden, nicht im Docker-Image — falls es fehlt, wird der
  // Inhaltscheck übersprungen, aber die Magic-Bytes-Prüfung oben bleibt
  // bestehen.
  let text;
  try {
    text = extrahierePdfText(buffer);
  } catch (err) {
    if (err.code === 'ENOENT') return;
    throw err;
  }

  assert.match(text, /Kursaal/);
  assert.match(text, /Kirchgemeindehaus/);
  assert.match(text, /Beethoven/);
  assert.match(text, /07\.09\.2026/);
});

test('erzeugeGesamtplanPdf: leerer Tag erzeugt trotzdem ein gültiges PDF mit Hinweistext', async () => {
  const buffer = await erzeugeGesamtplanPdf({ datum: '2026-09-08', wochentag: 'Di', termine: [] });
  assert.equal(buffer.subarray(0, 5).toString('latin1'), '%PDF-');

  let text;
  try {
    text = extrahierePdfText(buffer);
  } catch (err) {
    if (err.code === 'ENOENT') return;
    throw err;
  }
  assert.match(text, /Keine Termine/);
});

test('erzeugeMusikerplanPdf: enthält nur eigene Termine + Kzt, mit Raumname statt Teilnehmerliste', async () => {
  const termine = [
    {
      id: 1,
      werk: 'Beethoven Sinfonie Nr. 5',
      anfangszeit: '09:00',
      endzeit: '10:30',
      typ: null,
      teilnehmer: ['AB'],
      raum: { id: 1, name: 'Kursaal' },
    },
    {
      id: 2,
      werk: 'GP Brahms Violinkonzert',
      anfangszeit: '10:45',
      endzeit: '12:00',
      typ: 'GP',
      teilnehmer: ['CD'], // NICHT AB — darf im PDF für AB nicht auftauchen
      raum: { id: 2, name: 'Kirchgemeindehaus' },
    },
    {
      id: 3,
      werk: 'Konzertblock Abend',
      anfangszeit: '14:00',
      endzeit: '14:00',
      typ: 'Kzt',
      teilnehmer: [],
      raum: { id: 1, name: 'Kursaal' },
    },
  ];

  const buffer = await erzeugeMusikerplanPdf({ datum: '2026-09-07', wochentag: 'Mo', kuerzel: 'AB', termine });
  assert.equal(buffer.subarray(0, 5).toString('latin1'), '%PDF-');

  let text;
  try {
    text = extrahierePdfText(buffer);
  } catch (err) {
    if (err.code === 'ENOENT') return;
    throw err;
  }

  assert.match(text, /Musikerplan AB/);
  assert.match(text, /Beethoven/);
  assert.match(text, /Kursaal/); // Raumname statt Teilnehmerliste
  assert.match(text, /Konzertblock Abend/); // Kzt erscheint immer
  assert.doesNotMatch(text, /Brahms/); // gehört CD, nicht AB
});

test('erzeugeMusikerplanPdf: Musiker ohne Termine an diesem Tag bekommt gültiges PDF mit Hinweis', async () => {
  const buffer = await erzeugeMusikerplanPdf({ datum: '2026-09-08', wochentag: 'Di', kuerzel: 'ZZ', termine: [] });
  assert.equal(buffer.subarray(0, 5).toString('latin1'), '%PDF-');

  let text;
  try {
    text = extrahierePdfText(buffer);
  } catch (err) {
    if (err.code === 'ENOENT') return;
    throw err;
  }
  assert.match(text, /Keine Termine für ZZ/);
});
