# Fortschritt

Migrationsplan (alle 10 Phasen):
https://claude.ai/code/artifact/f8082705-72cd-41e7-b8c7-63f1ff74fe81

Immer zuerst diese Datei lesen, dann REFERENCE.md (Abschnitt 13: Fallstricke).

## ✅ Kritischer Befund 07.09.2026 — Sandbox war leer, DRITTES Mal — BEHOBEN, Code wieder da

Nächtliche Sitzung (07.09.2026, Scheduled Task, niemand anwesend) fand
`/home/claude/zwt-probeplan-app` komplett leer vor (drittes Mal nach
04./05.09. und 05./06.09.). Wie vorgeschrieben wurde nichts blind
nachgebaut, nur der Befund dokumentiert und eine Push-Benachrichtigung
geschickt (Details dazu weiter unten archiviert).

**Behoben, selber Tag, interaktive Folge-Sitzung**: Rafi hat sein
eigenes ZIP-Backup `zwtprobeplanapp_20260906_1600UTC.zip` hochgeladen
(Stand 06.09.2026, 16:00 UTC — neuer als das zuvor als "letzte
bekannte Kopie" vermerkte 08:02-UTC-ZIP). Code (`db/`, `deploy/`,
`migrate/`, `server/` inkl. `server/public/admin.html`) wurde daraus in
diese Sandbox zurückgespielt und committet (README/REFERENCE/PROGRESS.md
NICHT aus dem ZIP übernommen, der hier fortgeschriebene, aktuellere
Doku-Stand bleibt massgeblich). Tests verifiziert:
`node --test migrate/test/*.test.js server/test/*.test.js` → 128 Tests,
**108 pass, 0 fail, 20 skipped** (die übersprungenen sind vermutlich
DB-/Netzwerk-abhängig und laufen ohne echtes Postgres nicht). Damit ist
der Code-Stand dieser Sandbox wieder vollständig (Phase 1–8).

**Bleibt trotzdem wichtig**: `git push` aus der Sandbox funktioniert
weiterhin nicht (siehe Abschnitt "Git-Push aus der Sandbox: ENDGÜLTIG
GEKLÄRT" unten) — ein erneuter Sandbox-Reset ist also weiterhin möglich
und würde den Code wieder verlieren, wenn bis dahin kein frisches ZIP
verschickt wurde. Deshalb JETZT sofort ein aktuelles ZIP an Rafi
schicken (siehe "Letzte Sicherung" unten), nicht abwarten.

## Phasenstatus

**Hinweis**: Code-Stand 07.09.2026 (nachmittags) wieder vollständig in
dieser Sandbox vorhanden (aus Rafis ZIP wiederhergestellt, s.o.), Tests
grün. Fachlicher Stand unverändert gegenüber 06.09.2026.

- **Phase 0** (Vorbereitung): [x] GitHub-Repo + URL bekannt, Remote
  gesetzt, Push aus Sandbox endgültig als nicht funktionsfähig geklärt
  (Workflow: ZIP → Rafi pusht lokal, siehe unten), [x] VPS
  bestellt/aktiv (`83.228.213.202`, ubuntu, Ubuntu 26.04), [ ] Swiss
  Backup (Rafi), **[x] Domain bekannt** (`schedule.zwischentoene.com`,
  zeigt bereits auf den VPS, seit 07.09.2026 in `deploy/Caddyfile`
  eingetragen — siehe REFERENCE.md Abschnitt 19), [x] Zugriffsmodell A
  entschieden (05.09.2026), **[x] Mehrere Benutzer:innen ergänzt**
  (07.09.2026, siehe REFERENCE.md Abschnitt 18).
- **Phase 1** (Datenmodell/Migration): [x] `db/schema.sql`, `migrate/*`,
  Code vorhanden und Tests grün.
- **Phase 2** (Server-Grundgerüst): [x] `deploy/*`, lief unverändert auf
  VPS. Backup-Cronjob wartet auf Swiss Backup.
- **Phase 3** (Terminverwaltung-API): [x] CRUD `/api/termine`,
  Konfliktprüfung, Kzt-Regel, Wochentags-Raumbeschränkung. Raumpuffer-
  Matrix weiterhin leer (Default 0 Min).
- **Phase 4** (Raumplan/Musiker-Ansicht): [x] vis-timeline,
  `raumplan.html`, `musikerplan.html`, `musiker-logik.js`, `color.js`,
  Nav-Links (jetzt auch zur neuen Startseite `/`) zu allen Seiten.
  `GET /api/musiker` fehlt weiterhin (kein Blocker).
- **Phase 5** (Stand sperren): [x] `GET/POST /api/stand*`, SQL-basierte
  Änderungsmarkierung.
- **Phase 6** (PDF-Export): [x] Gesamtplan+Musikerplan-PDFs (`pdfkit`).
- **Phase 7** (Zugriff/Login): [x] Schreiben geschützt — bisheriger
  gemeinsamer Organisator:innen-Zugang (`auth.js`, produktiv auf VPS,
  von Rafi bestätigt) PLUS seit 07.09.2026 echte Benutzerkonten pro
  Person (siehe REFERENCE.md Abschnitt 18).
- **Phase 8** (Parallelbetrieb/Testlauf): [x] Terminverwaltung
  (`admin.html`), vollständige Saison-Verwaltung + Konzert-/Werkliste
  mit Autocomplete (REFERENCE.md Abschnitte 16+17) — **läuft laut Rafi
  bereits auf dem VPS** (heute bestätigt, war zuvor unklar). NEU seit
  heute Nachmittag, **NOCH NICHT auf VPS ausgerollt**: Mehrere
  Benutzer:innen (Abschnitt 18) + Landingpage/Domain (Abschnitt 19) —
  siehe "Rollout-Anleitung für Rafi" unten. Der eigentliche
  Parallelbetrieb/Testlauf mit einer realen Probenwoche hat noch nicht
  begonnen.
- **Phase 9** (Umstieg): noch nicht begonnen.

**Nächster inhaltlicher Schritt**: Rafi rollt die heutigen Ergänzungen
(Mehrere Benutzer:innen, Landingpage, Domain in Caddyfile) auf den VPS
aus — siehe Abschnitt "Rollout-Anleitung für Rafi" unten für die
genauen Schritte (nur EINE neue Migration, alles andere ist Code-
Update + Caddy-Neustart). Danach: eigenes Konto anlegen (statt weiter
den gemeinsamen Zugang zu nutzen), dann Parallelbetrieb/Testlauf mit
realer Probenwoche beginnen (oder Phase 9, je nach Rafis Einschätzung).

## 🚀 Rollout-Anleitung für Rafi: heutige Ergänzungen (07.09.2026) auf den VPS bringen

Betrifft: Mehrere Benutzer:innen (REFERENCE.md Abschnitt 18),
Landingpage (Abschnitt 19), Domain in `deploy/Caddyfile` (Abschnitt 19).
Saison-Verwaltung/Werkliste sind laut dir bereits auf dem VPS — dafür
ist NICHTS mehr zu tun.

1. Neuestes ZIP entpacken und ins Projektverzeichnis auf dem VPS
   kopieren (Code-Dateien ersetzen: `server/`, `deploy/Caddyfile`,
   `db/migration-benutzer.sql` ist neu).
2. EINE neue, idempotente Migration anwenden (kann gefahrlos auch
   nochmal laufen, falls unsicher ob schon getan):
   ```
   cd deploy
   set -a; source .env; set +a
   docker compose exec -T db sh -c 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"' < ../db/migration-benutzer.sql
   ```
3. App-Container neu bauen (neue Datei `server/db.js`, geänderte
   `index.js`/`auth.js`/`queries.js`, neues `server/public/index.html`):
   ```
   docker compose up -d --build app
   ```
4. Caddy neu starten, damit die geänderte Domain in `Caddyfile` greift
   (kein Rebuild nötig, die Datei ist nur eingehängt):
   ```
   docker compose restart caddy
   ```
5. Prüfen: `https://schedule.zwischentoene.com/` sollte die neue
   Landingpage zeigen (Caddy braucht evtl. ein bis zwei Minuten fürs
   Let's-Encrypt-Zertifikat beim ersten Mal). Mit dem bisherigen
   gemeinsamen Passwort in `admin.html` einloggen, unter dem neuen Tab
   "Benutzer:innen" ein eigenes Konto anlegen, damit abmelden/neu laden
   und mit dem eigenen Konto einloggen testen.
6. Danach in `PROGRESS.md` (hier) vermerken, dass ausgerollt ist — oder
   Rafi sagt es einer Sitzung, die es einträgt.

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
- Saison-Verwaltung + Konzert-/Werkliste (REFERENCE.md Abschnitte
  16+17): **GEKLÄRT** — läuft laut Rafi bereits auf dem VPS.
- Mehrere Benutzer:innen (Abschnitt 18): KEIN Rollen-/Rechte-System
  (jedes Konto = volle Schreibrechte, wie bisher "der Organisator") —
  Annahme, da Rafis Feedback nur nach verschiedenen Logins fragte,
  nicht nach unterschiedlichen Berechtigungsstufen. Bei Bedarf später
  nachrüstbar (neue Spalte `benutzer.rolle` o.ä.).
- Benutzername ändern: nicht vorgesehen (nur Passwort ändern oder
  Konto löschen + neu anlegen) — Annahme, da nicht explizit gefordert.
- Kein Schutz gegen Löschen des letzten/eigenen Benutzerkontos beim
  Löschen — der Notfallzugang (ORGANISATOR_PASSWORT) bleibt so oder so
  als Absicherung bestehen, deshalb bewusst nicht extra abgefragt.
- `git push` aus der Sandbox: GEKLÄRT, siehe Abschnitt "Git-Push aus
  der Sandbox: ENDGÜLTIG GEKLÄRT" oben — funktioniert nicht und wird
  nicht mehr versucht, Workflow ist jetzt dauerhaft ZIP → Rafi pusht
  lokal.
- Prompt-Einbettung schützt die 3 Markdown-Dateien zuverlässig (dritter
  Erfolg in Folge), NICHT den Programmcode — siehe kritischer Befund
  oben. Das ist jetzt ein bestätigtes, wiederkehrendes strukturelles
  Problem, keine Ausnahme mehr.
- `update_trigger`s "exceeds maximum allowed tokens"-Fehler bedeutet
  NICHT, dass das Update fehlschlug (mehrfach per `list_triggers`
  verifiziert) — als Erfolg behandeln, nicht wiederholen/kürzen.

## Letzte Sicherung (ZIP an Nutzer per SendUserFile)
- 03.09.2026, 04.09.2026; danach unregelmässig während Tagsitzungen.
- 06.09.2026, 07:12 UTC: `zwt-probeplan-app-docs-only.zip` (nur Doku).
- 06.09.2026, 07:34 UTC: `zwt-probeplan-app_2026-09-06_0734UTC.zip`
  (Phase 1–7 wiederhergestellt).
- 06.09.2026, 08:02 UTC: `zwt-probeplan-app_2026-09-06_0802UTC.zip`
  — Phase 1–8 komplett, 54 Tests grün.
- **06.09.2026, 16:00 UTC** (`zwtprobeplanapp_20260906_1600UTC.zip`):
  Rafis EIGENES ZIP, von ihm am 07.09.2026 hochgeladen — neuerer Stand
  als das 08:02-UTC-ZIP, wurde zur Wiederherstellung des Codes in dieser
  Sandbox verwendet (siehe "Kritischer Befund" oben).
- 07.09.2026, 14:52 UTC: `zwt-probeplan-app_2026-09-07_1452UTC.zip`
  — Rückversand des wiederhergestellten Standes (Phase 1–8, Code +
  aktualisierte Doku) an Rafi, als Sicherung unmittelbar nach der
  Wiederherstellung (siehe README.md Punkt 4).
- 07.09.2026, 15:30 UTC: `zwt-probeplan-app_2026-09-07_1530UTC.zip`
  — Mehrere Benutzer:innen (REFERENCE.md Abschnitt 18) + Landingpage/
  Domain (Abschnitt 19) ergänzt, 136/136 Tests grün (gegen echtes
  lokales Postgres verifiziert, siehe Abschnitt 18). **Aktuellste
  bekannte vollständige Kopie — enthält Rollout-Schritte für Rafi
  (siehe Abschnitt "Rollout-Anleitung für Rafi" oben).**

## ✅ Git-Push aus der Sandbox: ENDGÜLTIG GEKLÄRT (07.09.2026, interaktiv) — geht nicht, wird nicht mehr versucht

Nachdem der 403-Fehler ("not in this session's authorized repository
set") über mehrere Nächte hinweg bestand, wurde heute (07.09.2026,
interaktive Folge-Sitzung, Rafi anwesend) der Ursache auf den Grund
gegangen:

1. Rafi hat die Claude-GitHub-App über den offiziellen Weg (Claude.ai
   Settings → Connectors → GitHub → Disconnect/Connect) installiert —
   der direkte Installations-Link (`github.com/apps/.../installations/new`)
   funktionierte NICHT (Fehler "state: Field required", weil der
   OAuth-state-Parameter fehlt, den nur Claudes eigener Connect-Flow
   mitliefert — bekannter Anthropic-Bug, siehe Issue #79353).
2. Trotz erfolgreicher App-Installation: `git push` aus dieser (bereits
   laufenden) Sitzung weiterhin 403 vom Git-Proxy — plausibel, weil die
   Autorisierung einer Sitzung offenbar beim Sitzungsstart fixiert wird
   und die App-Installation danach kam.
3. Test aus einer NEUEN, frisch gestarteten Cowork-Sitzung: anderer
   Fehler — `fatal: could not read Username for 'https://github.com'`.
   Das bedeutet: in dieser Sitzung gab es GAR KEINE Credential-Injektion
   (anders als der 403 vom Git-Proxy, der eine aktive, aber verweigerte
   Injektion zeigt). Zwei verschiedene Fehlerbilder je nach Sitzungstyp
   — in keinem Fall funktioniert es.
4. Nachgefragt, ob ein Zugangs-Token stattdessen manuell/dauerhaft in
   der Sandbox oder in Claudes persistentem Speicher hinterlegt werden
   könnte: NEIN, aus zwei Gründen. (a) Die Sandbox selbst ist nicht
   persistent (siehe "Kritischer Befund" oben) — ein dort abgelegtes
   Token wäre beim nächsten Reset genauso weg wie der Code. (b) Es gibt
   aktuell KEINE offizielle, sichere Secrets-Verwaltung für Scheduled
   Tasks — der einzige dazu gefundene Feature-Request (Issue #51854,
   "Encrypted secrets store for scheduled triggers") wurde von
   Anthropic als "not planned" geschlossen. Die einzige dokumentierte
   Alternative (Token im Klartext in den Prompt schreiben) ist ein
   Sicherheitsrisiko und wurde bewusst nicht umgesetzt.

**Endgültige Konsequenz**: `git push` aus dieser Sandbox heraus wird ab
sofort NICHT MEHR versucht — weder von der nächtlichen Routine noch in
interaktiven Sitzungen. Der Workflow ist stattdessen dauerhaft:
Code entsteht/ändert sich hier → sofort als ZIP per SendUserFile an
Rafi → Rafi pusht von seinem eigenen Rechner (mit seinen eigenen,
lokal gespeicherten GitHub-Zugangsdaten) nach GitHub. Das ist kein
Provisorium mehr, sondern der Standardweg, bis (falls je) Anthropic
eine offizielle Secrets-Lösung für Scheduled Tasks anbietet.

Frühere Einträge zu einzelnen 403-Versuchen (06./07.09.2026) sind mit
diesem Abschnitt erledigt und werden nicht weiter fortgeschrieben.
