'use strict';

// PDF-Export (Phase 6, REFERENCE.md Abschnitt 7):
// - "Gesamtplan": ein PDF pro Tag, alle Räume, farbige Kästchen wie in
//   der Web-Ansicht, überlappende Termine im selben Raum nebeneinander.
// - "Musikerplan": ein PDF pro Musiker:in mit nur den eigenen Terminen
//   (plus Kzt-Blöcken). Teilt die Zeichenlogik mit dem Gesamtplan
//   (zeichneBaenderSeite) — der einzige Unterschied ist, WIE die
//   "Bänder" (Zeilengruppen) gebildet werden: pro Raum vs. ein
//   einzelnes Band pro Musiker:in.

const PDFDocument = require('pdfkit');
const { gruppiereNachRaumMitLanes, ordneLanesZu, filterTermineFuerMusiker } = require('./pdf-layout');
const { timeToMinutes } = require('./validation');
const { terminFarbe } = require('./public/color');

const START_STUNDE = 7; // Zeitachse beginnt 07:00
const END_STUNDE = 23; // ... und endet 23:00
const LABEL_BREITE = 100;
const LANE_HOEHE = 22;
const BAND_ABSTAND = 6;
const KOPF_HOEHE = 70;
const ZEITACHSE_HOEHE = 20;

function formatiereDatum(datum) {
  // datum kommt aus Postgres als "YYYY-MM-DD" oder ISO-Timestamp — beide
  // Fälle abdecken, indem nur der Datumsteil verwendet wird.
  const nurDatum = String(datum).slice(0, 10);
  const [jahr, monat, tag] = nurDatum.split('-');
  return `${tag}.${monat}.${jahr}`;
}

function zeitZuX(zeitStr, plotBreite) {
  const minuten = timeToMinutes(zeitStr);
  const startMin = START_STUNDE * 60;
  const endMin = END_STUNDE * 60;
  const anteil = (minuten - startMin) / (endMin - startMin);
  return LABEL_BREITE + Math.max(0, Math.min(1, anteil)) * plotBreite;
}

/**
 * Zeichnet eine Plan-Seite (Zeitachse + Bänder mit farbigen Terminblöcken)
 * auf ein bestehendes PDFKit-Dokument. `baender`: Array von { label,
 * termine (bereits mit `lane` versehen), lanesGesamt }. `beschriftung`:
 * Funktion, die aus einem Termin den anzuzeigenden Text baut (bei
 * Gesamtplan z.B. inkl. Teilnehmer, bei Musikerplan inkl. Raumname).
 */
function zeichneBaenderSeite(doc, { titel, baender, beschriftung, leerHinweis }) {
  const plotBreite = doc.page.width - doc.page.margins.left - doc.page.margins.right - LABEL_BREITE;
  const startX = doc.page.margins.left;

  doc.fontSize(16).text(titel, startX, doc.page.margins.top);

  // Gesamthöhe VOR dem Zeichnen berechnen, damit die Gitterlinien der
  // Zeitachse exakt bis zum Inhalt reichen, nicht bis zum Seitenende.
  const inhaltsHoehe = baender.reduce((summe, b) => summe + b.lanesGesamt * LANE_HOEHE + BAND_ABSTAND, 0);

  const zeitachseY = doc.page.margins.top + KOPF_HOEHE - ZEITACHSE_HOEHE;
  const gitterEndeY = baender.length
    ? doc.page.margins.top + KOPF_HOEHE + inhaltsHoehe
    : doc.page.height - doc.page.margins.bottom;
  doc.fontSize(8).fillColor('#000');
  for (let stunde = START_STUNDE; stunde <= END_STUNDE; stunde++) {
    const x = zeitZuX(`${String(stunde).padStart(2, '0')}:00`, plotBreite);
    doc.text(`${stunde}:00`, x - 10, zeitachseY, { width: 30, align: 'left' });
    doc
      .moveTo(x, zeitachseY + ZEITACHSE_HOEHE)
      .lineTo(x, gitterEndeY)
      .strokeColor('#ddd')
      .lineWidth(0.5)
      .stroke();
  }

  let y = doc.page.margins.top + KOPF_HOEHE;

  for (const band of baender) {
    const bandHoehe = band.lanesGesamt * LANE_HOEHE;

    doc
      .fontSize(10)
      .fillColor('#000')
      .text(band.label, startX, y + bandHoehe / 2 - 5, { width: LABEL_BREITE - 10 });

    doc
      .rect(startX, y, LABEL_BREITE + plotBreite, bandHoehe)
      .strokeColor('#ccc')
      .lineWidth(0.5)
      .stroke();

    for (const termin of band.termine) {
      const x1 = zeitZuX(termin.anfangszeit, plotBreite);
      const x2Roh = zeitZuX(termin.endzeit, plotBreite);
      const x2 = Math.max(x2Roh, x1 + 3); // Mindestbreite, damit Kzt-Punkte sichtbar bleiben
      const boxY = y + termin.lane * LANE_HOEHE;

      doc
        .rect(x1, boxY + 1, x2 - x1, LANE_HOEHE - 2)
        .fillAndStroke(terminFarbe(termin), '#888');

      doc
        .fontSize(7)
        .fillColor('#000')
        .text(beschriftung(termin), x1 + 2, boxY + 4, {
          width: Math.max(x2 - x1 - 4, 0),
          height: LANE_HOEHE - 6,
          ellipsis: true,
        });
    }

    y += bandHoehe + BAND_ABSTAND;
  }

  if (baender.length === 0) {
    doc.fontSize(11).fillColor('#900').text(leerHinweis, startX, y + 10);
  }
}

/**
 * Erzeugt das Gesamtplan-PDF für einen Tag (alle Räume) und liefert es
 * als Buffer zurück. `termine` sind bereits die Termine EINES Tages
 * (aus groupTermineRows).
 */
function erzeugeGesamtplanPdf({ datum, wochentag, termine }) {
  return new Promise((resolve, reject) => {
    const doc = new PDFDocument({ size: 'A4', layout: 'landscape', margin: 36 });
    const chunks = [];
    doc.on('data', (chunk) => chunks.push(chunk));
    doc.on('end', () => resolve(Buffer.concat(chunks)));
    doc.on('error', reject);

    const baender = gruppiereNachRaumMitLanes(termine).map((g) => ({
      label: g.raum.name,
      termine: g.termine,
      lanesGesamt: g.lanesGesamt,
    }));

    zeichneBaenderSeite(doc, {
      titel: `ZwT Probeplan — Gesamtplan ${wochentag ? wochentag + ', ' : ''}${formatiereDatum(datum)}`,
      baender,
      beschriftung: (t) => t.werk + (t.teilnehmer && t.teilnehmer.length ? ` (${t.teilnehmer.join(', ')})` : ''),
      leerHinweis: 'Keine Termine an diesem Tag.',
    });
    doc.end();
  });
}

/**
 * Erzeugt das individuelle Musikerplan-PDF für einen Tag: nur die
 * eigenen Termine des Musikers (`kuerzel`) plus alle `Kzt`-Blöcke
 * (REFERENCE.md Abschnitt 3/7), als einzelnes Band. Zeigt den Raumnamen
 * in der Beschriftung (statt Teilnehmer, die sind hier immer "man
 * selbst" bzw. bei Kzt irrelevant).
 */
function erzeugeMusikerplanPdf({ datum, wochentag, kuerzel, termine }) {
  return new Promise((resolve, reject) => {
    const doc = new PDFDocument({ size: 'A4', layout: 'landscape', margin: 36 });
    const chunks = [];
    doc.on('data', (chunk) => chunks.push(chunk));
    doc.on('end', () => resolve(Buffer.concat(chunks)));
    doc.on('error', reject);

    const eigeneTermine = filterTermineFuerMusiker(termine, kuerzel);
    const { termine: mitLanes, lanesGesamt } = ordneLanesZu(eigeneTermine);
    const baender = eigeneTermine.length ? [{ label: kuerzel, termine: mitLanes, lanesGesamt }] : [];

    zeichneBaenderSeite(doc, {
      titel: `ZwT Probeplan — Musikerplan ${kuerzel} — ${wochentag ? wochentag + ', ' : ''}${formatiereDatum(datum)}`,
      baender,
      beschriftung: (t) => t.werk + (t.raum && t.raum.name ? ` — ${t.raum.name}` : ''),
      leerHinweis: `Keine Termine für ${kuerzel} an diesem Tag.`,
    });
    doc.end();
  });
}

module.exports = { erzeugeGesamtplanPdf, erzeugeMusikerplanPdf, zeitZuX, formatiereDatum };
