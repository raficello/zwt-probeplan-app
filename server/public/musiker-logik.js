// Reine Bau-Logik für die Musiker-Ansicht (Phase 4, siehe REFERENCE.md
// Abschnitt 3 + 6). UMD-artig wie color.js: per require() in
// Node-Tests UND als <script> im Browser nutzbar.
//
// WICHTIGE GESCHÄFTSREGEL (laut REFERENCE.md "mehrfach in der
// bisherigen Arbeit korrigiert"): Typ='Kzt' wird JEDEM Musiker
// angezeigt, unabhängig vom (bei Kzt ohnehin leeren) Teilnehmer-Feld.
// ALLE anderen Termine — inklusive Typ='K' — werden normal nach
// Teilnehmer-Kürzel gefiltert. Keine weitere Ausnahme.
(function (root) {
  'use strict';

  /**
   * Ermittelt die Menge aller Musiker-Kürzel, die an den übergebenen
   * Terminen als Teilnehmer beteiligt sind (sortiert, eindeutig). Dient
   * als Standardauswahl für die Musiker-Ansicht, wenn niemand explizit
   * ausgewählt wurde. Kzt-Termine tragen naturgemäss nichts bei (ihr
   * Teilnehmer-Feld ist immer leer).
   */
  function ermittleMusikerAusTerminen(termine) {
    var kuerzelSet = {};
    (termine || []).forEach(function (t) {
      (t.teilnehmer || []).forEach(function (k) {
        kuerzelSet[k] = true;
      });
    });
    return Object.keys(kuerzelSet).sort();
  }

  /**
   * Baut vis-timeline-"groups" (eine Spalte pro ausgewähltem Musiker)
   * und "items" (ein Eintrag pro Musiker-Termin-Kombination) aus einer
   * flachen Terminliste. `datum` ist das angezeigte Tagesdatum
   * (YYYY-MM-DD), wird für start/end der Items gebraucht.
   *
   * `terminFarbe` wird als Parameter übergeben statt fest verdrahtet,
   * damit diese Funktion ohne Abhängigkeit auf color.js testbar bleibt.
   */
  function baueMusikerGroupsUndItems(termine, musikerListe, datum, terminFarbeFn) {
    var groups = musikerListe.map(function (kuerzel) {
      return { id: kuerzel, content: kuerzel };
    });

    var items = [];
    musikerListe.forEach(function (kuerzel) {
      (termine || []).forEach(function (t) {
        var betrifftMusiker = t.typ === 'Kzt' || (t.teilnehmer || []).indexOf(kuerzel) !== -1;
        if (!betrifftMusiker) return;

        var istPunkt = t.anfangszeit === t.endzeit;
        var item = {
          id: t.id + '-' + kuerzel,
          group: kuerzel,
          content: t.werk,
          start: datum + 'T' + t.anfangszeit,
          type: istPunkt ? 'point' : 'range',
          style: 'background-color:' + terminFarbeFn(t) + ';border-color:#888',
        };
        if (!istPunkt) item.end = datum + 'T' + t.endzeit;
        items.push(item);
      });
    });

    return { groups: groups, items: items };
  }

  var exportsObj = { ermittleMusikerAusTerminen: ermittleMusikerAusTerminen, baueMusikerGroupsUndItems: baueMusikerGroupsUndItems };
  if (typeof module !== 'undefined' && module.exports) {
    module.exports = exportsObj;
  } else {
    root.ermittleMusikerAusTerminen = ermittleMusikerAusTerminen;
    root.baueMusikerGroupsUndItems = baueMusikerGroupsUndItems;
  }
})(typeof window !== 'undefined' ? window : this);
