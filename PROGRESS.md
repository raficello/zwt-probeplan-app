# Fortschritt

Reihenfolge und Nummerierung entsprechen dem Migrationsplan:
https://claude.ai/code/artifact/f8082705-72cd-41e7-b8c7-63f1ff74fe81

Immer zuerst diese Datei lesen, dann `REFERENCE.md` für die fachlichen
Details (insbesondere Abschnitt 13: gesammelte technische Fallstricke,
die künftige Arbeit vermeiden sollte).

## ⚠️ KRITISCHER BEFUND (06.09.2026, nächtliche Sitzung): Code-Verlust bestätigt

Diese nächtliche Sitzung fand `/home/claude/zwt-probeplan-app` **komplett
leer** vor (kein `.git`, keine einzige Datei) — nicht nur, wie in
früheren PROGRESS-Fassungen vermerkt, "manchmal passiert es", sondern
diesmal mit einer gezielten Suche über das gesamte Dateisystem bestätigt
(`find / -iname "*zwt*"`, `-iname admin.html`, `-iname schema.sql` —
alles ergebnislos). Betroffen ist NICHT nur diese drei Markdown-Dateien
(die aus dem Prompt wiederhergestellt sind, siehe unten), sondern der
**gesamte Programmcode**: `db/schema.sql`, `migrate/*`, `server/*`
(inklusive des kompletten, erst am Vortag 05.09.2026 gebauten
Phase-8-Codes: `admin.html`, `raumTagErlaubt()`, `GET /api/raeume`,
`server/test/index.test.js`, zwei Browser-Bugfixes), `deploy/*`.

**Warum das vermutlich ein echter, nicht wiederherstellbarer Verlust
ist**: laut der PROGRESS-Fassung, die diese Sitzung vorgefunden hat,
endete die Tagsitzung vom 05.09.2026 mit dem Hinweis "Noch nicht auf dem
VPS ausgerollt — ZIP an Rafi schicken, sobald er bereit ist zu
deployen." Das deutet darauf hin, dass der Phase-8-ZIP zu diesem
Zeitpunkt noch NICHT verschickt war. Wenige Stunden später ist die
Sandbox leer. Damit ist unklar, ob dieser Code irgendwo ausserhalb
dieser Sandbox existiert.

**Was NICHT betroffen ist**: Phase 0–7 laufen produktiv auf dem
Infomaniak-VPS (`83.228.213.202`) und sind damit unabhängig von dieser
Sandbox gesichert — der VPS ist von diesem Vorfall nicht betroffen
(siehe REFERENCE.md Abschnitt 9).

**Bewusste Entscheidung dieser Sitzung**: NICHT versucht, den
Phase-8-Code blind aus der Spezifikation in REFERENCE.md Abschnitt 15
nachzubauen. Das wäre kein "kleines, klar abgegrenztes Teilstück" mehr,
sondern ein kompletter, unbeaufsichtigter Wiederaufbau mehrerer hundert
Zeilen Geschäftslogik + Tests ohne Möglichkeit zur Verifikation durch
einen Menschen — mit genau dem Risiko stiller Abweichungen, vor dem
REFERENCE.md Abschnitt 13 mehrfach warnt (z.B. der Wochentags-
Raumbeschränkungs-Bug, der nur durch gezieltes Nachsehen auffiel). Das
gehört in eine interaktive Tagsitzung mit Rafi, nicht in eine
unbeaufsichtigte Nacht mit begrenztem Kontingent.

**Stattdessen heute Nacht erledigt**:
1. README.md/REFERENCE.md/PROGRESS.md aus diesem Prompt wiederhergestellt,
   `git init` + Commit.
2. Die vermutliche Ursache im Prozess behoben: README.md "Arbeitsweise"
   verlangt jetzt, ein ZIP SOFORT nach jeder Code-Änderung zu verschicken,
   nicht erst "wenn Rafi bereit ist zu deployen" (siehe README.md Punkt 4).
3. REFERENCE.md Abschnitt 13 um diesen Vorfall als Lehre ergänzt.
4. Diesen Befund an Rafi per Push-Benachrichtigung gemeldet (siehe unten).

**Für Rafi — Aktion nötig, sobald Zeit ist**:
- Bitte prüfen, ob am Abend/in der Nacht des 05.09.2026 doch noch ein
  ZIP mit `admin.html` etc. per Chat/E-Mail ankam (Downloads-Ordner,
  Chat-Anhänge durchsuchen). Falls ja: einfach in einer neuen Sitzung
  wieder hochladen/anhängen, dann kann alles daraus wiederhergestellt
  werden — kein Neuaufbau nötig.
- Falls nein: Phase 8 (admin.html, Wochentags-Raumbeschränkung,
  `GET /api/raeume`, Tests, zwei Bugfixes) muss in einer interaktiven
  Tagsitzung neu gebaut werden — die vollständige Spezifikation dafür
  steht in REFERENCE.md Abschnitt 15, das war schon einmal fertig und
  bestätigt, sollte also zügig nachbaubar sein.
- Falls möglich: einmalig die GitHub-Repo-URL mitteilen (kein Geheimnis,
  nur die URL) — dann kann sie dauerhaft in README.md eingebettet
  werden, und künftige Sitzungen könnten bei leerem Verzeichnis
  wenigstens automatisch `git remote add origin <url>` setzen und einen
  Push versuchen, statt bei jedem Neustart wirkungslos zu warten. Aktuell
  ist unbekannt, ob überhaupt ein GitHub-Repo mit Inhalt existiert (der
  Push schlägt seit Längerem an einem Proxy-Bug fehl, siehe "Offene
  Fragen" unten — ob vor diesem Bug jemals erfolgreich gepusht wurde,
  ist aus dem vorgefundenen Text nicht ersichtlich).

**Nächster Schritt für die nächste Sitzung** (nächtlich oder Tag): zuerst
prüfen, ob Rafi auf diesen Befund reagiert hat (ZIP gefunden? Neuaufbau
gewünscht?). Falls keine Reaktion: mit dem Neuaufbau von Phase 8 gemäss
REFERENCE.md Abschnitt 15 beginnen (klar spezifiziert, überschaubarer
Umfang) — davor kurz `db/schema.sql` (Abschnitt 10), `migrate/*`
(Abschnitt 11) und die produktiv laufenden Phase-2–7-Grundlagen
(Abschnitte 9, 12, 14) mit aufbauen, da diese ja ebenfalls aus dem
Sandbox-Repo verschwunden sind, auch wenn sie unverändert auf dem VPS
laufen — sonst fehlt dem Repo die Basis, auf der Phase 8 aufsetzt.

## Phase 0 — Vorbereitung & Entscheidungen
- [x] GitHub-Repo eingerichtet (Push aktuell blockiert, siehe Offene Fragen)
- [x] Infomaniak VPS Lite bestellt und aktiv — IPv4 `83.228.213.202`, SSH-User `ubuntu`, Ubuntu 26.04 LTS 64-bit (Details: REFERENCE.md Abschnitt 9). Nächtliche Sitzungen können sich NICHT selbst per SSH auf diesen Server verbinden (kein allgemeiner Internetzugang aus der Sandbox, verifiziert).
- [ ] Swiss Backup bestellt (Aufgabe des Menschen)
- [ ] Domain-Frage geklärt (Aufgabe des Menschen) — `deploy/Caddyfile` hatte bis dahin eine funktionierende Übergangsvariante (nackte IP, kein HTTPS) aktiv (Datei aktuell im Sandbox-Repo verschwunden, siehe Kritischer Befund; auf dem VPS unverändert vorhanden)
- [x] Zugriffsmodell entschieden (05.09.2026, mit Rafi): Variante A — Lesen offen für alle, Schreiben mit gemeinsamem Organisator:innen-Passwort. Details/Umsetzung: siehe Phase 7 unten und REFERENCE.md Abschnitt 14.

## Phase 1 — Datenmodell & Migrationsskript
- [ ] **War ✅ abgeschlossen, Code Stand 06.09.2026 im Sandbox-Repo NICHT mehr vorhanden** (siehe Kritischer Befund oben). Design/Spezifikation weiterhin gültig: `db/schema.sql` (REFERENCE.md Abschnitt 10), `migrate/lib.js` + `migrate/migrate.js` (Abschnitt 11). Neuaufbau nötig, sobald Kapazität da ist — niedriges Risiko, da vollständig spezifiziert und zuvor schon einmal fertig getestet.
- [ ] Weiterhin offen, sobald ein echter Sheet-Export vorliegt: Format ggf.
  anpassen, `raum_puffer`-Matrix befüllen (siehe Offene Fragen). Kein
  Blocker.

## Phase 2 — Server-Grundgerüst
- [ ] **War ✅ abgeschlossen (bis auf Backup), Konfigurationsdateien Stand
  06.09.2026 im Sandbox-Repo NICHT mehr vorhanden** — läuft aber
  unverändert produktiv auf dem VPS (Docker-Compose-Setup App + Postgres
  + Caddy), das ist NICHT betroffen (siehe Kritischer Befund, REFERENCE.md
  Abschnitt 9/12). Für das Sandbox-Repo müssten `deploy/*` bei Bedarf neu
  committet werden (z.B. durch Abschreiben vom VPS in einer Sitzung mit
  verlinktem Computer) — kein inhaltlicher Neubau nötig, nur erneutes
  Ablegen im Repo.
- [ ] Backup-Cronjob nach Swiss Backup: noch nicht umgesetzt, wartet auf
  Bestellung (Phase 0). Kein Blocker für andere Phasen.

## Phase 3 — Kernfunktion: Terminverwaltung
- [ ] **War ✅ abgeschlossen, Code Stand 06.09.2026 im Sandbox-Repo NICHT
  mehr vorhanden** (läuft aber produktiv auf dem VPS). Vollständige
  CRUD-API für Termine: `GET/POST/PUT/DELETE /api/termine(/:id)` — Filter
  nach Datum/Wochentag, Konfliktprüfung mit Pufferzeiten (REFERENCE.md
  Abschnitt 4), automatisches Anlegen unbekannter Musiker-Kürzel,
  `Kzt`-Sonderregel korrekt (Abschnitt 3), inkl. Wochentags-
  Raumbeschränkung (`raumTagErlaubt()`, ursprünglich in Phase 3 vergessen
  und erst in Phase 8 nachgerüstet — siehe REFERENCE.md Abschnitt 13).
- [ ] Raumpuffer-Matrix-Befüllung weiterhin offen (Default 0 Minuten,
  siehe Offene Fragen).

## Phase 4 — Raumplan- & Musiker-Ansicht
- [ ] **War ✅ abgeschlossen, Code Stand 06.09.2026 im Sandbox-Repo NICHT
  mehr vorhanden** (läuft aber produktiv auf dem VPS). Timeline-
  Bibliothek: **vis-timeline** (Begründung: Offene Fragen unten).
  Raumplan-Ansicht (`raumplan.html`) und Musiker-Ansicht
  (`musikerplan.html` + `musiker-logik.js`), Farblogik in `color.js`.
- [ ] **Bekannte Einschränkung** (Raumplan-/Musiker-ANSICHT, nicht die
  Terminverwaltung): zeigt nur Räume/Musiker:innen mit mindestens einem
  Termin an diesem Tag. `GET /api/musiker` fehlt weiterhin. Kein
  Blocker, sinnvolle Ergänzung für später.

## Phase 5 — Stand sperren & Änderungsmarkierung
- [ ] **War ✅ abgeschlossen, Code Stand 06.09.2026 im Sandbox-Repo NICHT
  mehr vorhanden** (läuft aber produktiv auf dem VPS). `GET /api/stand` +
  `POST /api/stand/sperren`, "neu/geändert" komplett in SQL berechnet
  (REFERENCE.md Abschnitt 5), Farbregel mit höchster Priorität in
  `color.js`. "Stand sperren"-Button in `raumplan.html`.

## Phase 6 — PDF-Export
- [ ] **War ✅ abgeschlossen, Code Stand 06.09.2026 im Sandbox-Repo NICHT
  mehr vorhanden** (läuft aber produktiv auf dem VPS). "Gesamtplan"-PDF
  (`GET /api/pdf/gesamtplan`) und individueller Musikerplan (`GET
  /api/pdf/musikerplan`), Bibliothek `pdfkit`, Details REFERENCE.md
  Abschnitt 7.
- [ ] QR-Code/Dropbox/TinyURL für die individuellen PDFs: laut
  REFERENCE.md Abschnitt 7 vermutlich unnötig für die Web-App (direkter
  Link reicht) — bei Bedarf mit Rafi klären. Kein Blocker.

## Phase 7 — Zugriff & Login
- [ ] **War ✅ abgeschlossen, Code Stand 06.09.2026 im Sandbox-Repo NICHT
  mehr vorhanden** (läuft aber produktiv auf dem VPS, von Rafi bestätigt).
  Zugriffsmodell A (REFERENCE.md Abschnitt 14): Lesen offen, Schreiben
  mit gemeinsamem Organisator:innen-Passwort (`server/auth.js`,
  `pruefeOrganisatorAuth`). `ORGANISATOR_PASSWORT` Pflicht in `.env`.

## Phase 8 — Parallelbetrieb & Testlauf
- [ ] **Terminverwaltung (`admin.html`) war fertig gebaut und lokal
  getestet (05.09.2026), aber noch NICHT auf dem VPS ausgerollt UND noch
  nicht als ZIP an Rafi verschickt — Stand 06.09.2026 im Sandbox-Repo
  NICHT mehr vorhanden. Das ist der eigentliche Verlust dieser Nacht,
  siehe "Kritischer Befund" oben.** Vollständige Spezifikation für einen
  Neuaufbau: REFERENCE.md Abschnitt 15 (inkl. der beiden dabei gefundenen
  Browser-Bugs, Abschnitt 13).
- [ ] Der eigentliche Parallelbetrieb/Testlauf mit einer realen
  Probenwoche (laut Migrationsplan das Kernstück von Phase 8) hat noch
  nicht begonnen.

## Phase 9 — Umstieg
- [ ] Noch nicht begonnen

## Offene Fragen / Annahmen

- **Duplizierte Kzt-Filterlogik**: `server/public/musiker-logik.js`
  (Browser, Musiker-Ansicht) und `server/pdf-layout.js`
  (`filterTermineFuerMusiker`, PDF-Export) enthielten beide dieselbe
  Business-Regel ("Kzt erscheint bei jedem Musiker, alle anderen nur
  bei passendem Kürzel") als separaten Code, nicht als gemeinsame
  Abhängigkeit — Annahme: eine echte Code-Teilung zwischen Browser-UMD-
  Modul und Node-only-Modul lohnt sich für zwei kurze Funktionen nicht.
  Bei einem Neuaufbau IMMER BEIDE Stellen berücksichtigen.
- "Stand sperren" (Phase 5): solange noch nie gesperrt wurde, gilt JEDER
  Termin als `neu=false` (kein Vergleichspunkt vorhanden) statt `true`.
  Bei Bedarf revidierbar.
- `musikerplan.html` hatte keinen eigenen "Stand sperren"-Button —
  Annahme: einer reicht, da das Sperren global (nicht pro Ansicht) wirkt.
- Timeline-Bibliothek für Phase 4: vis-timeline statt FullCalendar
  Resource-Timeline gewählt — MIT-Lizenz ohne kommerzielle
  Einschränkungen; FullCalendars Resource-Timeline-Plugin ist ein
  Premium-Feature mit eigenen Lizenzbedingungen.
- Verhältnis Spalte "Aud" (D) zu Spalte "Ort" (I) im Master-Sheet noch
  nicht abschliessend geklärt (siehe REFERENCE.md Abschnitt 1). Im Schema
  vorläufig als zwei unabhängige, je eindeutige Felder auf `raeume`
  abgebildet (`name`, `aud_code`), nicht als separate Zuordnungstabelle.
- Quelle der Raumwechsel-Pufferzeiten-Matrix ("roomIntervals") noch nicht
  lokalisiert (siehe REFERENCE.md Abschnitt 2). Angenommener Default für
  nicht erfasste Raumpaare: 0 Minuten Puffer.
- Noch kein echter Datenexport aus dem Google Sheet vorhanden — Migration
  arbeitet zunächst mit Beispieldaten im in REFERENCE.md beschriebenen
  Format.
- Unbekannte Raumnamen im Export führen im Migrationsskript NICHT zu
  einem Abbruch, sondern zu einer Warnung + einem automatisch angelegten
  Raum ohne Tages-Einschränkung.
- Backup-Ziel (Swiss Backup) noch nicht bestellt -> Backup-Cronjob in
  Phase 2 bewusst zurückgestellt statt mit Platzhalter-Zugangsdaten
  vorzubereiten.
- `git push` nach GitHub schlägt aktuell mit einem 403 des sitzungsinternen
  Git-Proxys fehl ("not in this session's authorized repository set")
  — ein bekannter, öffentlich gemeldeter Cowork-Bug
  (github.com/anthropics/claude-code/issues/84581), kein Problem mit
  Token/Repo/Rechten. Nicht mehrfach versuchen zu debuggen; einfach
  weiter lokal committen und optional einmal pro Nacht `git push`
  probieren, falls der Bug zwischenzeitlich behoben wurde. Ausserdem:
  falls eine nächtliche Sitzung ein leeres Verzeichnis vorfindet (siehe
  README.md), ist auch KEIN `git remote` konfiguriert — die GitHub-Repo-
  URL liegt nicht im Prompt vor, daher `git remote add origin ...` NICHT
  raten, sondern hier vermerken und überspringen. **Neu 06.09.2026**:
  Rafi wurde gebeten, die Repo-URL einmalig mitzuteilen, damit sie
  dauerhaft in README.md eingebettet werden kann (siehe Kritischer
  Befund oben) — noch keine Antwort.
- **Widerlegt 06.09.2026**: die frühere Notiz "der Prompt-Einbettungs-
  Mechanismus funktioniert zuverlässig ... auch mehrfach innerhalb
  derselben Nacht" bezog sich offenbar nur auf die drei Markdown-Dateien
  selbst, nicht auf den tatsächlichen Programmcode — der geht bei einer
  Neubereitstellung der Sandbox nachweislich komplett verloren, wenn er
  nicht zusätzlich per ZIP/GitHub gesichert wurde. Diese Unterscheidung
  war in früheren Fassungen nicht klar genug herausgestellt.

## Letzte Sicherung (ZIP an Nutzer per SendUserFile)
- 03.09.2026, 04.09.2026 (danach ZIPs im Rahmen interaktiver
  Tagsitzungen verschickt, aber laut vorgefundenem Text nicht in jedem
  Fall sofort bzw. nicht durchgängig unter diesem Punkt nachgetragen —
  vermutlich mitursächlich für den Verlust vom 05./06.09.2026, siehe
  "Kritischer Befund" oben).
- 06.09.2026 (nächtliche Sitzung): ZIP des aktuellen Repo-Stands
  verschickt — Hinweis: enthält NUR die drei Markdown-Dateien
  (README/REFERENCE/PROGRESS), da kein Programmcode mehr vorhanden ist.
