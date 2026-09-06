# Fortschritt

Migrationsplan (alle 10 Phasen):
https://claude.ai/code/artifact/f8082705-72cd-41e7-b8c7-63f1ff74fe81

Immer zuerst diese Datei lesen, dann REFERENCE.md (Abschnitt 13: Fallstricke).

## ✅ Code-Verlust vom 06.09.2026 — VOLLSTÄNDIG BEHOBEN

Nächtliche Sitzung fand `/home/claude/zwt-probeplan-app` komplett leer
vor (Sandbox-Neubereitstellung). NOCH IN DERSELBEN NACHT hat Rafi zwei
eigene ZIP-Backups vom 05.09.2026 beigesteuert:
1. `zwtprobeplanappfull_22.51.19.zip` — Phase 1–7 (Schema, Migration,
   CRUD-API, Konfliktprüfung, Raumplan-/Musiker-Ansicht, Stand sperren,
   PDF-Export, Organisator:innen-Login).
2. `zwtprobeplanapp.zip` (später am selben Abend) — zusätzlich der
   komplette Phase-8-Code: `server/public/admin.html`,
   `raumTagErlaubt()` in `validation.js`, `GET /api/raeume` in
   `index.js`, `server/test/index.test.js`, Nav-Links, Date-Objekt-
   Regressionstest.

Beide zurückgespielt und verifiziert: **54 Tests grün** (13
`migrate/test` + 41 DB-freie `server/test`, inkl. 5 neuer
`raumTagErlaubt`-Tests). Der gesamte Code bis einschliesslich Phase 8
ist damit wiederhergestellt — nichts mehr fehlt.

**Lehre für künftige Sitzungen**: bei Datenverlust IMMER zuerst fragen,
ob Rafi ein aktuelles ZIP hat (er sichert offenbar öfter, als früher
angenommen), bevor Code blind aus REFERENCE.md nachgebaut wird.

**GitHub**: Rafi hat die Repo-URL mitgeteilt
(`https://github.com/raficello/zwt-probeplan-app.git`, dauerhaft in
README.md). Remote gesetzt, Push zweimal versucht (auch nachdem Rafi
GitHub in den Claude-Einstellungen verbunden hat) — schlägt beide Male
identisch fehl: "access denied by the git proxy:
raficello/zwt-probeplan-app is not in this session's authorized
repository set... add the repository to the session's sources."
Vermutung: diese Autorisierung wird pro Sitzung/Scheduled-Task beim
Start festgelegt, nicht nachträglich während eine Sitzung läuft — die
nächste nächtliche Sitzung (neue Session) sollte es also automatisch
erneut probieren (Schritt 5) und könnte dann funktionieren. Falls
nicht: prüfen, ob beim Anlegen eines Scheduled Tasks eine Repo-Auswahl
möglich ist.

**Korrektur zum update_trigger-"Grössenlimit"** (fälschlich in einer
früheren Fassung dieser Nacht angenommen): der Fehler "result exceeds
maximum allowed tokens" bei `update_trigger`-Aufrufen bedeutet NICHT,
dass das Update fehlgeschlagen ist — nur die Bestätigungsantwort ist zu
gross zum Anzeigen, das Update selbst geht durch (mehrfach per
`list_triggers` verifiziert). Bei diesem Fehler künftig: als Erfolg
behandeln, nicht panisch kürzen oder wiederholen.

**ZIP-Dateinamen**: Rafi hat gebeten, künftig immer den exakten
Dateinamen (mit Zeitstempel) in der Begleitnachricht zu nennen, da
Downloads bei ihm nicht zuverlässig im normalen Downloads-Ordner landen
— siehe README.md Arbeitsweise Punkt 8.

## Phasenstatus

- **Phase 0** (Vorbereitung): [x] GitHub-Repo + URL bekannt, Remote
  gesetzt, Push noch blockiert (Repo-Autorisierung, siehe oben), [x] VPS
  bestellt/aktiv (`83.228.213.202`, ubuntu, Ubuntu 26.04), [ ] Swiss
  Backup (Rafi), [ ] Domain (Rafi, Caddyfile hat IP-Übergangslösung),
  [x] Zugriffsmodell A entschieden (05.09.2026).
- **Phase 1** (Datenmodell/Migration): [x] `db/schema.sql`, `migrate/*`,
  13 Tests grün. Offen: `raum_puffer`-Befüllung sobald echter Export
  vorliegt.
- **Phase 2** (Server-Grundgerüst): [x] `deploy/*`, läuft unverändert
  auf VPS. Backup-Cronjob wartet auf Swiss Backup.
- **Phase 3** (Terminverwaltung-API): [x] CRUD `/api/termine`,
  Konfliktprüfung, Kzt-Regel, Wochentags-Raumbeschränkung
  (`raumTagErlaubt()`, ursprünglich in Phase 3 vergessen, in Phase 8
  nachgerüstet — REFERENCE.md Abschnitt 13). Raumpuffer-Matrix weiterhin
  leer (Default 0 Min).
- **Phase 4** (Raumplan/Musiker-Ansicht): [x] vis-timeline,
  `raumplan.html`, `musikerplan.html`, `musiker-logik.js`, `color.js`,
  Nav-Links zu allen drei Seiten. Bekannte Einschränkung: Ansicht zeigt
  nur Räume/Musiker mit Termin an dem Tag; `GET /api/musiker` fehlt
  weiterhin (kein Blocker).
- **Phase 5** (Stand sperren): [x] `GET/POST /api/stand*`, SQL-basierte
  Änderungsmarkierung.
- **Phase 6** (PDF-Export): [x] Gesamtplan+Musikerplan-PDFs (`pdfkit`).
  QR/Dropbox vermutlich unnötig.
- **Phase 7** (Zugriff/Login): [x] Passwortschutz für Schreiben
  (`auth.js`), von Rafi bestätigt.
- **Phase 8** (Parallelbetrieb/Testlauf): [x] Terminverwaltung
  (`admin.html`) fertig gebaut, **auf dem VPS ausgerollt und von Rafi
  bestätigt** (06.09.2026: Speichern/Löschen funktioniert produktiv).
  [x] Wochentags-Raumbeschränkung, `GET /api/raeume`, Raum-Produktivdaten
  (`db/seed-raeume.sql`, noch auf dem VPS auszuführen). [x] Datum als
  Festival-Tage-Auswahl überall (nicht nur Formular, auch Toolbar-
  Navigation aller 3 Seiten). [x] Werk-Autocomplete + Teilnehmer-
  Vorschlag (Abschnitt 16, `db/migration-werke.sql` +
  `db/seed-werke-2026.sql`, noch auf dem VPS auszuführen). [ ] Der
  eigentliche Parallelbetrieb/Testlauf mit einer realen Probenwoche hat
  noch nicht begonnen — das ist der nächste inhaltliche Schritt, sobald
  alle Seed-Skripte auf dem VPS gelaufen sind.
- **Phase 9** (Umstieg): noch nicht begonnen.

## Offene Fragen / Annahmen

- Kzt-Filterlogik dupliziert (`musiker-logik.js` Browser +
  `pdf-layout.js` Node) statt geteilt — Annahme: lohnt sich für 2 kurze
  Funktionen nicht. Bei Änderungen IMMER beide Stellen beachten.
- Vor erstem "Stand sperren" gilt jeder Termin als `neu=false`.
- `musikerplan.html` ohne eigenen Sperren-Button (wirkt global).
- vis-timeline statt FullCalendar (MIT-Lizenz vs. Premium-Plugin).
- Aud (Spalte D) vs. Ort (Spalte I) im Master-Sheet ungeklärt — vorläufig
  zwei unabhängige Felder auf `raeume`.
- **Pufferzeiten-Matrix-Quelle gefunden** (06.09.2026, Tab "Config" des
  Google Sheets), in `db/seed-raeume.sql` eingetragen — noch NICHT auf
  dem VPS angewendet (Rafi muss das Skript ausführen). Dabei entdeckt:
  die Konfliktprüfung wertet die Matrix nicht raumübergreifend aus
  (fragt nur denselben Raum ab) — mit den echten, fast durchweg
  nichtleeren Werten wirkt sich das so aus, dass praktisch nie ein
  Pufferzeit-Konflikt gemeldet wird. Muss nachgezogen werden
  (REFERENCE.md Abschnitt 2), kein Blocker für den Testlauf.
- Festival-Tage 2026 bekannt (06.09.2026, aus Google Sheet): Mo.
  12.10.2026 bis So. 18.10.2026. In `admin.html` als Datums-Auswahlliste
  hinterlegt (fest im Code, keine Server-Quelle dafür — bei Bedarf
  später aus der DB oder Config ableiten).
- Kein echter Sheet-Export für die Migration (`migrate/`) vorhanden —
  nutzt weiterhin Beispieldaten. Google-Sheet-Zugriff via Google-Drive-
  Connector ist inzwischen möglich (06.09.2026, siehe oben) — bei Bedarf
  künftig direkt daraus exportieren statt manuell.
- Unbekannte Raumnamen im Export: Warnung + Auto-Raum statt Abbruch.
- Backup-Ziel noch nicht bestellt.
- `git push` schlägt mit 403 fehl — Repo-Autorisierung fehlt für diese
  Session (siehe oben). Nächste (neue) Sitzung sollte es erneut
  versuchen, nicht mehrfach pro Sitzung.
- Prompt-Einbettung schützt nur die 3 Markdown-Dateien vor leerer
  Sandbox, NICHT den Programmcode — Rafis eigene ZIP-Backups sind aber
  ein funktionierender Rettungsweg (siehe oben).
- `update_trigger`s "exceeds maximum allowed tokens"-Fehler bedeutet
  NICHT, dass das Update fehlschlug — siehe oben.
- **Werk-Autocomplete + Teilnehmer-Vorschlag: erledigt** (06.09.2026).
  Rafi hat den kompletten Excel-Export hochgeladen, per `openpyxl`
  gelesen (zuverlässiger als der Google-Drive-Connector, der den Tab
  "config" nicht vollständig lieferte). Details: REFERENCE.md
  Abschnitt 16. 1 Werk ("502a", nicht-numerischer Code) bewusst nicht
  importiert — falls das gebraucht wird, müsste `werke.nummer` von
  `int` auf `text` geändert werden (kleiner Nacharbeitsposten, kein
  Blocker).
- **Saison-Verwaltung angefragt, bewusst VERTAGT (06.09.2026)**: Rafi
  will künftig mehrere Saisons verwalten können (Daten, Musiker,
  Konzerte, Werke pro Saison; vergangene Saisons als Archiv, Jahr per
  Dropdown wählbar). Das ist eine grosse, invasive Änderung (praktisch
  jede Tabelle bräuchte eine `saison_id`, plus Migration der bereits
  produktiv befüllten Daten, plus UI-Jahresauswahl auf allen 3 Seiten).
  Rafis eigene Formulierung ("Es muss DANN eine Verwaltung geben")
  deutet darauf hin, dass das für eine KÜNFTIGE Saison gilt, nicht für
  das bevorstehende Festival Okt. 2026 — deshalb bewusst NICHT jetzt
  kurz vor dem Festival umgesetzt (Risiko, die gerade lauffähige App zu
  destabilisieren), sondern als eigenes Vorhaben nach dem Festival
  vorgeschlagen, wenn mehr Zeit für einen sauberen Entwurf ist. Rafi
  müsste das bestätigen — falls er es doch VOR dem Festival braucht,
  sofort Bescheid geben. Die neuen Werk/Konzert-Tabellen (Abschnitt 16)
  wurden bewusst ohne `saison_id` gebaut, um diese Entscheidung nicht
  vorwegzunehmen.

## Letzte Sicherung (ZIP an Nutzer per SendUserFile)
- 03.09.2026, 04.09.2026; danach unregelmässig während Tagsitzungen.
- 06.09.2026, 07:12 UTC: `zwt-probeplan-app-docs-only.zip` (nur Doku).
- 06.09.2026, 07:34 UTC: `zwt-probeplan-app_2026-09-06_0734UTC.zip`
  (Phase 1–7 wiederhergestellt).
- 06.09.2026, 08:02 UTC: **`zwt-probeplan-app_2026-09-06_0802UTC.zip`**
  — Phase 1–8 komplett, 54 Tests grün. Aktuellster Stand.
