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
  (`admin.html`) fertig gebaut+getestet, inkl. Wochentags-
  Raumbeschränkung und `GET /api/raeume`. **Noch NICHT auf dem VPS
  ausgerollt** — ZIP an Rafi schicken sobald er bereit ist (siehe
  README.md Punkt 4: diesmal SOFORT, nicht verzögert). [ ] Der
  eigentliche Parallelbetrieb/Testlauf mit einer realen Probenwoche hat
  noch nicht begonnen — das ist der nächste inhaltliche Schritt.
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
- Pufferzeiten-Matrix-Quelle nicht lokalisiert — Default 0 Min.
- Kein echter Sheet-Export vorhanden — Migration nutzt Beispieldaten.
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

## Letzte Sicherung (ZIP an Nutzer per SendUserFile)
- 03.09.2026, 04.09.2026; danach unregelmässig während Tagsitzungen.
- 06.09.2026, 07:12 UTC: `zwt-probeplan-app-docs-only.zip` (nur Doku).
- 06.09.2026, 07:34 UTC: `zwt-probeplan-app_2026-09-06_0734UTC.zip`
  (Phase 1–7 wiederhergestellt).
- 06.09.2026, ~08:15 UTC: nächstes ZIP folgt mit Phase 1–8 komplett
  (Dateiname wird in der Begleitnachricht genannt, siehe README Punkt 8).
