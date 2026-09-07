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

  function pad2(n) {
    return (n < 10 ? '0' : '') + n;
  }

  // Formatiert ein Date wieder als lokale ISO-Zeit OHNE Zeitzone (Gegenstück
  // zu `new Date(lokalesIso)`), damit abrundenAufStunde/aufrundenAufStunde
  // dasselbe zeitzonen-unabhängige Format wie der Rest dieser Datei liefern.
  function zuLokalemIso(d) {
    return d.getFullYear() + '-' + pad2(d.getMonth() + 1) + '-' + pad2(d.getDate()) +
      'T' + pad2(d.getHours()) + ':' + pad2(d.getMinutes()) + ':' + pad2(d.getSeconds());
  }

  function abrundenAufStunde(iso) {
    var d = new Date(iso);
    d.setMinutes(0, 0, 0);
    return zuLokalemIso(d);
  }

  function aufrundenAufStunde(iso) {
    var d = new Date(iso);
    if (d.getMinutes() !== 0 || d.getSeconds() !== 0 || d.getMilliseconds() !== 0) {
      d.setHours(d.getHours() + 1);
    }
    d.setMinutes(0, 0, 0);
    return zuLokalemIso(d);
  }

  /**
   * Ermittelt das anzuzeigende Zeitfenster für einen Tag: NUR die
   * tatsächlich gebrauchten Stunden (Rafi-Feedback, 06.09.2026: "nicht
   * vor dem ersten und nach dem letzten Termin") -- also die Spanne vom
   * frühesten Termin-Anfang bis zum spätesten Termin-Ende, auf volle
   * Stunden auf-/abgerundet (damit die Stundenraster-Linien/-Labels
   * sinnvoll an den Rändern stehen, statt eine stundenlose Teilzeile am
   * Rand zu erzeugen). `minStart`/`minEnde` gelten NUR noch als
   * Ersatzwert für einen Tag OHNE jeden Termin (sonst wäre das Raster
   * leer) -- sie polstern ein Fenster mit vorhandenen Terminen nicht
   * mehr künstlich auf. `items` sind Objekte mit `start`/`end`
   * (ISO-Strings, `end` optional bei Punkt-Terminen).
   */
  function ermittleFenster(datum, items, minStart, minEnde) {
    var vorhandene = (items || []).filter(function (item) { return !!item.start; });
    if (vorhandene.length === 0) {
      return {
        start: datum + 'T' + (minStart || '07:00:00'),
        ende: datum + 'T' + (minEnde || '23:00:00'),
      };
    }
    var fruehesterStart = vorhandene[0].start;
    var spaetestesEnde = vorhandene[0].end || vorhandene[0].start;
    vorhandene.forEach(function (item) {
      if (item.start < fruehesterStart) fruehesterStart = item.start;
      var ende = item.end || item.start;
      if (ende > spaetestesEnde) spaetestesEnde = ende;
    });
    return {
      start: abrundenAufStunde(fruehesterStart),
      ende: aufrundenAufStunde(spaetestesEnde),
    };
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
    abrundenAufStunde: abrundenAufStunde,
    aufrundenAufStunde: aufrundenAufStunde,
  };
  if (typeof module !== 'undefined' && module.exports) {
    module.exports = exportsObj;
  } else {
    root.berechnePosition = berechnePosition;
    root.ermittleFenster = ermittleFenster;
    root.stundenraster = stundenraster;
    root.abrundenAufStunde = abrundenAufStunde;
    root.aufrundenAufStunde = aufrundenAufStunde;
  }
})(typeof window !== 'undefined' ? window : this);
