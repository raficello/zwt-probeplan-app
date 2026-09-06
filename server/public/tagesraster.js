// Reine Positions-/Zeitraster-Logik für die vertikale Tagesansicht
// (Rafi-Feedback, 07.09.2026: Raumplan- und Musikerplan-Ansicht sollen
// vertikal sein wie im Original-Sheet -- siehe Tabs "Raumplan Grafik"/
// "Musiker Grafik": Zeit läuft von oben nach unten, Räume bzw.
// Musiker:innen sind Spalten -- statt der bisherigen horizontalen
// vis-timeline-Darstellung).
//
// UMD-artig wie color.js/musiker-logik.js: per require() in Node-Tests
// UND als <script> im Browser nutzbar. Enthält bewusst NUR reine
// Berechnungen ohne DOM-Zugriff -- das eigentliche Rendern des Rasters
// (DOM-Aufbau) steht direkt in raumplan.html/musikerplan.html, analog
// zum bisherigen Muster in diesem Projekt (siehe PROGRESS.md "Offene
// Fragen" zur bewussten Duplizierung kurzer Bau-Logik zwischen den
// beiden Ansichten).
(function (root) {
  'use strict';

  /**
   * Berechnet Position (top) und Höhe eines Termin-Blocks in Pixeln
   * innerhalb des sichtbaren Zeitfensters. `startIso`/`endIso`/
   * `fensterStartIso` sind lokale ISO-Datumszeiten OHNE Zeitzone (z.B.
   * "2026-10-12T14:30:00", wie überall sonst in diesem Projekt) --
   * `new Date(...)` interpretiert das konsistent als lokale Zeit, die
   * Differenzbildung ist deshalb zeitzonen-unabhängig korrekt.
   * `mindesthoehe` verhindert, dass sehr kurze Termine (oder Punkt-
   * Termine mit Anfang=Ende) unsichtbar schmal werden.
   */
  function berechnePosition(startIso, endIso, fensterStartIso, pxProMinute, mindesthoehe) {
    var start = new Date(startIso).getTime();
    var ende = new Date(endIso || startIso).getTime();
    var fensterStart = new Date(fensterStartIso).getTime();
    var top = ((start - fensterStart) / 60000) * pxProMinute;
    var hoehe = Math.max(mindesthoehe || 0, ((ende - start) / 60000) * pxProMinute);
    return { top: top, hoehe: hoehe };
  }

  /**
   * Ermittelt das anzuzeigende Zeitfenster für einen Tag: mindestens
   * `minStart`–`minEnde` (Standard-Sichtfenster, z.B. "07:00"–"23:00"),
   * aber erweitert um alle tatsächlichen Termine, damit nichts
   * ausserhalb des Fensters abgeschnitten wird (z.B. ein sehr früher
   * Soundcheck oder ein Termin bis nach Mitternacht-nah). `items` sind
   * Objekte mit `start`/`end` (ISO-Strings, `end` optional bei
   * Punkt-Terminen).
   */
  function ermittleFenster(datum, items, minStart, minEnde) {
    var fensterStart = datum + 'T' + (minStart || '07:00:00');
    var fensterEnde = datum + 'T' + (minEnde || '23:00:00');
    (items || []).forEach(function (item) {
      if (item.start && item.start < fensterStart) fensterStart = item.start;
      var ende = item.end || item.start;
      if (ende && ende > fensterEnde) fensterEnde = ende;
    });
    return { start: fensterStart, ende: fensterEnde };
  }

  /**
   * Liste der vollen Stunden innerhalb [fensterStartIso, fensterEndeIso]
   * für die Zeitmarken-Spalte links (z.B. "07:00", "08:00", ...).
   */
  function stundenraster(fensterStartIso, fensterEndeIso) {
    var stunden = [];
    var start = new Date(fensterStartIso);
    var ende = new Date(fensterEndeIso);
    var d = new Date(start.getTime());
    d.setMinutes(0, 0, 0);
    if (d.getTime() < start.getTime()) d.setHours(d.getHours() + 1);
    while (d.getTime() <= ende.getTime()) {
      stunden.push(new Date(d.getTime()).toISOString());
      d.setHours(d.getHours() + 1);
    }
    return stunden;
  }

  var exportsObj = {
    berechnePosition: berechnePosition,
    ermittleFenster: ermittleFenster,
    stundenraster: stundenraster,
  };
  if (typeof module !== 'undefined' && module.exports) {
    module.exports = exportsObj;
  } else {
    root.berechnePosition = berechnePosition;
    root.ermittleFenster = ermittleFenster;
    root.stundenraster = stundenraster;
  }
})(typeof window !== 'undefined' ? window : this);
