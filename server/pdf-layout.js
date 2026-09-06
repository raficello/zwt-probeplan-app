'use strict';

// Reine Layout-Logik für den PDF-Export (Phase 6, REFERENCE.md
// Abschnitt 7): "überlappende Termine im selben Raum nebeneinander
// ('Lanes')". Getrennt von der eigentlichen PDF-Zeichnung (pdf.js),
// damit sie ohne pdfkit getestet werden kann.

const { timeToMinutes } = require('./validation');

/**
 * Ordnet Terminen eines EINZELNEN Raums "Lanes" (Spuren) zu, sodass sich
 * zeitlich überlappende Termine nie dieselbe Lane teilen. Greedy-
 * Algorithmus: sortiert nach Anfangszeit, weist jedem Termin die erste
 * Lane zu, deren letzter Termin bereits vorbei ist (oder eine neue Lane).
 * Zwei Termine, bei denen der eine exakt endet, wenn der andere beginnt,
 * dürfen sich eine Lane teilen (keine Pufferzeit-Anforderung hier — das
 * ist reine Layout-Überschneidung, nicht die Konfliktprüfung aus
 * REFERENCE.md Abschnitt 4).
 *
 * Gibt ein Array zurück (gleiche Termine, ergänzt um `lane`, Index ab 0)
 * plus `lanesGesamt` (höchste Lane + 1 — wird für die Zeilenhöhe im PDF
 * gebraucht).
 */
function ordneLanesZu(termine) {
  const sortiert = [...termine].sort(
    (a, b) => timeToMinutes(a.anfangszeit) - timeToMinutes(b.anfangszeit)
  );

  const laneEndzeiten = []; // laneEndzeiten[i] = Ende (Minuten) des letzten Termins in Lane i
  const ergebnis = [];

  for (const termin of sortiert) {
    const start = timeToMinutes(termin.anfangszeit);
    const end = timeToMinutes(termin.endzeit);

    let lane = laneEndzeiten.findIndex((laneEnde) => start >= laneEnde);
    if (lane === -1) {
      lane = laneEndzeiten.length;
      laneEndzeiten.push(end);
    } else {
      laneEndzeiten[lane] = end;
    }

    ergebnis.push({ ...termin, lane });
  }

  return { termine: ergebnis, lanesGesamt: laneEndzeiten.length || 1 };
}

/**
 * Gruppiert eine flache Terminliste nach Raum und wendet `ordneLanesZu`
 * pro Raum an. Gibt ein Array von { raum, termine, lanesGesamt } zurück,
 * sortiert nach Raumname (für eine stabile Reihenfolge im PDF).
 */
function gruppiereNachRaumMitLanes(termine) {
  const nachRaum = new Map();
  for (const t of termine) {
    const key = t.raum.id;
    if (!nachRaum.has(key)) {
      nachRaum.set(key, { raum: t.raum, termine: [] });
    }
    nachRaum.get(key).termine.push(t);
  }

  return Array.from(nachRaum.values())
    .map(({ raum, termine: raumTermine }) => {
      const { termine: mitLanes, lanesGesamt } = ordneLanesZu(raumTermine);
      return { raum, termine: mitLanes, lanesGesamt };
    })
    .sort((a, b) => a.raum.name.localeCompare(b.raum.name));
}

/**
 * Filtert Termine für den individuellen Musikerplan (REFERENCE.md
 * Abschnitt 7, verwendet dieselbe Kernregel wie
 * server/public/musiker-logik.js: baueMusikerGroupsUndItems — bei
 * Änderung an einer Stelle IMMER auch die andere prüfen, siehe
 * PROGRESS.md "Offene Fragen" zu dieser Duplikation). Typ='Kzt'
 * erscheint immer, alle anderen Termine nur wenn `kuerzel` in
 * `teilnehmer` steht.
 */
function filterTermineFuerMusiker(termine, kuerzel) {
  return termine.filter((t) => t.typ === 'Kzt' || (t.teilnehmer || []).includes(kuerzel));
}

module.exports = { ordneLanesZu, gruppiereNachRaumMitLanes, filterTermineFuerMusiker };
