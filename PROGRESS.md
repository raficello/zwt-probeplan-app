# Fortschritt

Migrationsplan (alle 10 Phasen):
https://claude.ai/code/artifact/f8082705-72cd-41e7-b8c7-63f1ff74fe81

Immer zuerst diese Datei lesen, dann REFERENCE.md (Abschnitt 13: Fallstricke).

## ⚠️ Code-Verlust vom 06.09.2026 — GROSSTEILS BEHOBEN

Nächtliche Sitzung fand `/home/claude/zwt-probeplan-app` komplett leer
vor (Sandbox-Neubereitstellung). NOCH IN DERSELBEN NACHT hat Rafi ein
eigenes ZIP-Backup vom Abend des 05.09.2026 beigesteuert
(`zwtprobeplanappfull_22.51.19.zip`), das den **kompletten Code für
Phase 1–7** enthält (`db/`, `migrate/`, `server/`, `deploy/` — Schema,
Migrationsskript, CRUD-API, Konfliktprüfung, Raumplan-/Musiker-Ansicht,
Stand sperren, PDF-Export, Organisator:innen-Login). Zurückgespielt und
verifiziert: 50 Tests grün (13 `migrate/test`, 37 DB-freie
`server/test`). Damit ist der Datenverlust für Phase 1–7 behoben.

**Weiterhin fehlend**: Phase-8-Code (`server/public/admin.html`,
`raumTagErlaubt()`-Durchsetzung in `server/validation.js`, `GET
/api/raeume` in `server/index.js`, `server/test/index.test.js`) war in
diesem ZIP NICHT enthalten (Datei-Zeitstempel darin gehen nur bis
~14:00 Uhr) — vermutlich erst später am 05.09.-Abend gebaut. **Rafi
gebeten, ein späteres ZIP von diesem Abend zu suchen** (nach ca. 23
Uhr) — falls vorhanden, enthält es vermutlich auch admin.html.

**GitHub**: Rafi hat die Repo-URL mitgeteilt
(`https://github.com/raficello/zwt-probeplan-app.git`, jetzt dauerhaft
in README.md). Remote gesetzt, Push versucht — schlägt NICHT (nur) am
bekannten generischen Cowork-Proxy-Bug fehl, sondern konkret mit:
"access denied by the git proxy: raficello/zwt-probeplan-app is not in
this session's authorized repository set... add the repository to the
session's sources." Das ist vermutlich eine Berechtigungs-/
Verbindungseinstellung auf Rafis Seite (GitHub-Verbindung in den
Cowork-Einstellungen muss dieses Repo als Quelle erlauben), keine
Cowork-Infrastruktur-Störung. **Für Rafi**: bitte prüfen/einrichten,
danach sollte der nächtliche Push funktionieren.

**Korrektur zum update_trigger-"Grössenlimit"** (fälschlich in einer
früheren Fassung dieser Nacht angenommen): der Fehler "result exceeds
maximum allowed tokens" bei `update_trigger`-Aufrufen bedeutet NICHT,
dass das Update fehlgeschlagen ist — es bedeutet nur, dass die
Bestätigungsantwort zu gross zum Anzeigen ist. Verifiziert per
`list_triggers`: ein Aufruf mit ~26 KB Prompt UND ein nachfolgender
namensonly-Aufruf (kein neuer Prompt) zeigten BEIDE denselben
"exceeds maximum tokens"-Fehler, aber der Prompt-Inhalt war trotzdem
korrekt gespeichert. Das Grössenlimit-Problem besteht also vermutlich
NICHT wie angenommen — die Dateien mussten diese Nacht wahrscheinlich
nicht so stark gekürzt werden. Trotzdem NICHT davon ausgehen, dass ein
extrem grosser Prompt (>100 KB) sicher funktioniert, das wurde nicht
getestet. Bei diesem Fehler künftig: Update trotzdem als erfolgreich
behandeln, ggf. mit `list_triggers` verifizieren statt zu wiederholen
oder panisch zu kürzen.

## Phasenstatus

- **Phase 0** (Vorbereitung): [x] GitHub-Repo + URL bekannt
  (`github.com/raficello/zwt-probeplan-app`), Remote gesetzt, Push noch
  blockiert (Repo-Autorisierung, siehe oben — Aktion bei Rafi), [x] VPS
  bestellt/aktiv (`83.228.213.202`, ubuntu, Ubuntu 26.04), [ ] Swiss
  Backup (Rafi), [ ] Domain (Rafi, Caddyfile hat IP-Übergangslösung),
  [x] Zugriffsmodell A entschieden (05.09.2026).
- **Phase 1** (Datenmodell/Migration): [x] Code wiederhergestellt
  (`db/schema.sql`, `migrate/*`), 13 Tests grün. Offen:
  `raum_puffer`-Befüllung sobald echter Export vorliegt.
- **Phase 2** (Server-Grundgerüst): [x] `deploy/*` wiederhergestellt,
  läuft unverändert auf VPS. Backup-Cronjob wartet auf Swiss Backup.
- **Phase 3** (Terminverwaltung-API): [x] Code wiederhergestellt
  (`server/index.js`, `queries.js`, `validation.js`), läuft produktiv.
  Enthält NICHT die Wochentags-Raumbeschränkung (`raumTagErlaubt()`) —
  die kam erst in Phase 8, ist weiterhin verloren (siehe unten).
  Raumpuffer-Matrix weiterhin leer (Default 0 Min).
- **Phase 4** (Raumplan/Musiker-Ansicht): [x] Code wiederhergestellt
  (`raumplan.html`, `musikerplan.html`, `musiker-logik.js`, `color.js`),
  läuft produktiv. Bekannte Einschränkung: zeigt nur Räume/Musiker mit
  Termin an dem Tag; `GET /api/musiker` fehlt weiterhin.
- **Phase 5** (Stand sperren): [x] Code wiederhergestellt (in
  `server/index.js`/`queries.js`), läuft produktiv.
- **Phase 6** (PDF-Export): [x] Code wiederhergestellt (`pdf.js`,
  `pdf-layout.js`), läuft produktiv. QR/Dropbox vermutlich unnötig.
- **Phase 7** (Zugriff/Login): [x] Code wiederhergestellt (`auth.js`),
  läuft produktiv, von Rafi bestätigt.
- **Phase 8** (Parallelbetrieb/Testlauf): [ ] **admin.html + die zwei
  Backend-Ergänzungen (raumTagErlaubt, GET /api/raeume) +
  server/test/index.test.js sind weiterhin verloren** — nicht im
  wiederhergestellten ZIP enthalten. Rafi gebeten, nach einem späteren
  ZIP vom 05.09.-Abend zu suchen. Falls keins auftaucht: Neuaufbau in
  Tagsitzung, Spezifikation REFERENCE.md Abschnitt 15 (überschaubarer
  Umfang: 1 HTML-Formular-Seite + 2 kleine Backend-Ergänzungen + Tests).
  [ ] Echter Testlauf mit realer Probenwoche noch nicht begonnen.
- **Phase 9** (Umstieg): noch nicht begonnen.

## Offene Fragen / Annahmen

- Kzt-Filterlogik war dupliziert (`musiker-logik.js` Browser +
  `pdf-layout.js` Node) statt geteilt — Annahme: lohnt sich für 2 kurze
  Funktionen nicht. Bei Neuaufbau beide Stellen beachten.
- Vor erstem "Stand sperren" gilt jeder Termin als `neu=false`.
- `musikerplan.html` ohne eigenen Sperren-Button (wirkt global).
- vis-timeline statt FullCalendar (MIT-Lizenz vs. Premium-Plugin).
- Aud (Spalte D) vs. Ort (Spalte I) im Master-Sheet ungeklärt — vorläufig
  zwei unabhängige Felder auf `raeume`.
- Pufferzeiten-Matrix-Quelle nicht lokalisiert — Default 0 Min.
- Kein echter Sheet-Export vorhanden — Migration nutzt Beispieldaten.
- Unbekannte Raumnamen im Export: Warnung + Auto-Raum statt Abbruch.
- Backup-Ziel noch nicht bestellt.
- `git push` schlägt mit 403 fehl — Stand 06.09.2026 konkret durch
  fehlende Repo-Autorisierung für diese Session/dieses Konto (siehe
  oben), nicht mehr durch einen generischen Proxy-Bug erklärt. Nach
  Rafis Fix erneut versuchen, nicht mehrfach pro Sitzung.
- Wichtig: Prompt-Einbettung schützt NUR die 3 Markdown-Dateien vor
  leerer Sandbox, NICHT den Programmcode. ABER: Rafis eigene ZIP-Backups
  (er hat mehrere vom 05.09.) sind ein funktionierender Rettungsweg,
  siehe oben — bei Datenverlust IMMER zuerst fragen, ob ein aktuelles
  ZIP vorliegt, bevor Neuaufbau aus Spezifikation versucht wird.
- **Korrigiert 06.09.2026**: `update_trigger`s "exceeds maximum allowed
  tokens"-Fehler bedeutet NICHT, dass das Update fehlschlug (siehe oben,
  verifiziert per `list_triggers`) — nur die Bestätigungsantwort ist zu
  gross zum Anzeigen. Diese Dateien mussten also wahrscheinlich nicht so
  stark gekürzt werden wie in dieser Nacht geschehen; bei Bedarf künftig
  wieder ausführlicher schreiben.

## Letzte Sicherung (ZIP an Nutzer per SendUserFile)
- 03.09.2026, 04.09.2026; danach unregelmässig während Tagsitzungen.
- 06.09.2026, 07:12 UTC (nächtlich): `zwt-probeplan-app-docs-only.zip`
  — enthielt NUR die 3 Markdown-Dateien (kein Programmcode vorhanden).
- 06.09.2026, 07:34 UTC (nächtlich): **`zwt-probeplan-app_2026-09-06_0734UTC.zip`**
  — vollständiger Stand inkl. wiederhergestelltem Phase-1–7-Code. Ab
  jetzt bei jedem Versand den exakten Dateinamen (mit Zeitstempel) in
  der Begleitnachricht nennen, damit Rafi die Version zuordnen kann
  (siehe Nachricht von Rafi, 06.09.2026: Downloads landen bei ihm nicht
  zuverlässig im normalen Downloads-Ordner, macht Versions-Verwechslung
  leicht möglich — Dateiname ist der einzige verlässliche Anker).
