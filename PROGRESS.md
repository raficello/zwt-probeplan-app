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
README.md). Remote gesetzt, Push mehrfach versucht (auch nachdem Rafi
GitHub in den Claude-Einstellungen verbunden hat, auch in einer neuen
nächtlichen Sitzung) — schlägt jedes Mal identisch fehl: "access denied
by the git proxy: raficello/zwt-probeplan-app is not in this session's
authorized repository set... Use add_repo to request access."

**Ursache gefunden (07.09.2026): bestätigter Anthropic-seitiger Bug,
nicht unser Konfigurationsfehler.** Öffentliches GitHub-Issue
[anthropics/claude-code#76248](https://github.com/anthropics/claude-code/issues/76248)
("Cloud/Cowork sessions: git proxy now blocks all pushes — 'not in this
session's authorized repository set'") beschreibt exakt denselben
Fehler, mit denselben Umgebungsvariablen, die auch in dieser Sitzung
gesetzt sind (`CCR_TEST_GITPROXY=1`, `CCR_AGENT_PROXY_ENABLED=1`,
`CCR_UPSTREAM_PROXY_ENABLED=1`). Laut Issue: server-seitiger Rollout
seit 10.07.2026, betrifft alle Cowork-Sitzungen, blockiert NUR Pushes
(Lesen/Klonen funktioniert weiterhin), kein `add_repo`-Tool oder UI in
Cowork tatsächlich erreichbar, kein bekannter Workaround, kein
Anthropic-Statement/Fix/ETA (Stand 07.09.2026). Ein eigener `add_repo`-
Aufruf und die Suche nach einer entsprechenden UI/Einstellung wurden in
dieser Sitzung ergebnislos versucht (kein passendes Tool, kein Skript
im Sandbox-Dateisystem, GitHub taucht auch nicht in der normalen
Connector-Liste auf).

**Konsequenz**: Push bleibt bis zu einem Anthropic-seitigen Fix
blockiert, unabhängig davon, was Rafi in seinen Einstellungen
konfiguriert. Workaround bleibt wie bisher: Rafi lädt bei Bedarf
manuell ein ZIP hoch bzw. pusht selbst von seinem Rechner aus (dort
funktioniert `git push` normal, da kein Cowork-Sitzungs-Proxy
zwischengeschaltet ist). Kein weiterer Push-Versuch pro Sitzung nötig,
bis das Issue als behoben gemeldet wird — stattdessen ggf. Rafi bitten,
lokal zu pushen, oder den Status des Issues periodisch zu prüfen.

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
- **Werk-Autocomplete auf VPS noch nicht sichtbar (07.09.2026)**: Rafi
  meldet, dass das Feature nach der Deploy-Anleitung nicht funktioniert.
  Diagnose (Details REFERENCE.md, neuer Abschnitt am Ende von 16):
  vermutlich hat ein scp-Befehl mit mehreren Quelldateien in einem
  Aufruf die Unterordnerstruktur nicht erhalten, wodurch `admin.html`
  nicht in `server/public/` gelandet ist und die alte Version aktiv
  blieb. Diese Sandbox hat KEINEN SSH-Zugriff auf den VPS (kein Key
  hinterlegt) — die Prüfung/der Fix muss von Rafis Rechner aus laufen.
  Korrigierte, selbst-verifizierende Befehlsfolge (jede Datei EINZELN
  kopieren, Zielpfad inkl. Dateiname):
  ```
  cd "/Users/rafi/Library/CloudStorage/Dropbox/Apps/ZWT Claude Schedule"

  scp server/index.js ubuntu@83.228.213.202:~/zwt-probeplan-app/server/index.js
  scp server/queries.js ubuntu@83.228.213.202:~/zwt-probeplan-app/server/queries.js
  scp server/public/admin.html ubuntu@83.228.213.202:~/zwt-probeplan-app/server/public/admin.html
  scp db/migration-werke.sql ubuntu@83.228.213.202:~/zwt-probeplan-app/db/migration-werke.sql
  scp db/seed-werke-2026.sql ubuntu@83.228.213.202:~/zwt-probeplan-app/db/seed-werke-2026.sql

  ssh ubuntu@83.228.213.202
  cd ~/zwt-probeplan-app

  # Verifikation 1: Zahl > 0 bedeutet, die neue admin.html ist wirklich angekommen
  grep -c "werkVorschlaege" server/public/admin.html

  cd deploy
  docker compose exec -T db sh -c 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"' < ../db/migration-werke.sql
  docker compose exec -T db sh -c 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"' < ../db/seed-werke-2026.sql
  docker compose up -d --build app

  # Verifikation 2: sollte "Mozart Duo B-Dur" und teilnehmer ["DU","YL"] zeigen
  sleep 5
  docker compose exec app node -e "require('http').get('http://localhost:3000/api/werke/vorschlaege?q=401', r => { let d=''; r.on('data', c => d+=c); r.on('end', () => console.log(d)); })"
  ```
  Danach im Browser Hard-Refresh (Cmd+Shift+R), damit kein alter
  admin.html-Cache-Stand angezeigt wird, und "401" im Werk-Feld
  ausprobieren. Noch nicht von Rafi bestätigt — nächster Schritt.
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
