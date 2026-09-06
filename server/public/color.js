// Farblogik für die Raumplan-/Musiker-Ansicht (Phase 4, siehe
// REFERENCE.md Abschnitt 6). UMD-artig: funktioniert sowohl per
// `require('./color.js')` in Node (server/test/color.test.js) als auch
// als einfaches <script src="/color.js"> im Browser (dann global als
// window.terminFarbe verfügbar) — bewusst ohne Build-Tooling/Bundler.
(function (root) {
  'use strict';

  var SONDER_WOERTER = ['aufbau', 'apero', 'logistik', 'musikeressen'];

  function terminFarbe(termin) {
    var werk = (termin.werk || '').toLowerCase();
    var bemerkungen = (termin.bemerkungen || '').toLowerCase();

    // Höchste Priorität (REFERENCE.md Abschnitt 5+6): "neu/geändert seit
    // letztem Sperren" überstimmt alle anderen Farbregeln. `termin.neu`
    // wird server-seitig berechnet (SELECT_TERMINE_SQL in queries.js),
    // damit der Zeitzonen-Vergleich nur an einer Stelle passiert.
    if (termin.neu) return '#ffd9a0';

    if (termin.typ === 'Kzt') return '#b6f2b6';
    if (termin.typ === 'K') return '#d7f2d7';
    if (werk.indexOf('gp') === 0) return '#fff3b0';
    for (var i = 0; i < SONDER_WOERTER.length; i++) {
      var w = SONDER_WOERTER[i];
      if (werk.indexOf(w) !== -1 || bemerkungen.indexOf(w) !== -1) return '#fbd7ea';
    }
    if (werk.indexOf('stimmung') !== -1 || bemerkungen.indexOf('stimmung') !== -1) return '#fff3b0';
    return '#ffffff';
  }

  if (typeof module !== 'undefined' && module.exports) {
    module.exports = { terminFarbe: terminFarbe };
  } else {
    root.terminFarbe = terminFarbe;
  }
})(typeof window !== 'undefined' ? window : this);
