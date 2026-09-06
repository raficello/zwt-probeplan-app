# Fachliche Referenz: ZwT 2026 - Probeplan (Google Sheet)

Diese Datei fasst zusammen, was über viele Sitzungen hinweg über das
bestehende Google-Sheet-System herausgefunden/gebaut wurde. Ziel: eine
Sitzung ohne Zugriff auf die bisherige Chat-Historie soll hieraus die
fachliche Logik korrekt nachbauen können.

Wo unten "unklar/zu verifizieren" steht: eine sinnvolle Annahme treffen,
in `PROGRESS.md` unter "Offene Fragen / Annahmen" vermerken, NICHT auf
eine Antwort warten.

**Hinweis 06.09.2026**: Diese Datei beschreibt fachliche Regeln, ist aber
NICHT der Programmcode selbst. Nach dem in PROGRESS.md beschriebenen
Datenverlust vom 05./06.09.2026 ist der tatsächliche Code (der diese
Regeln umsetzte) im aktuellen Repo-Stand NICHT mehr vorhanden — nur diese
Spezifikation. Vor einem Neuaufbau von Phase 8 (oder früher) bitte
PROGRESS.md "Kritischer Befund" lesen.

## 1. Grunddaten: Sheet "Master"

Sieben Wochentagsblöcke (Mo–So), untereinander im selben Blatt. Jeder
Block:

- Eine "Dat"-Zeile: Spalte A = `"Dat"`, Spalte B = Datum.
- Eine Kopfzeile mit den Spaltennamen:
  `Nr | Anfangszeit | Endzeit | Aud | Typ | Zeitanzeige | Werk | Teilnehmer | Ort | Bemerkungen | Zeit | Konsolenmeldung`
- Darunter die eigentlichen Termine, eine Zeile pro Termin.

Spaltenbedeutung:

| Spalte | Name | Bedeutung |
|---|---|---|
| A | Nr | Laufnummer innerhalb des Tages (nur Anzeige) |
| B | Anfangszeit | Startzeit, Format HH:MM |
| C | Endzeit | Endzeit, Format HH:MM |
| D | Aud | Numerischer Raum-/Auditorium-Code (z.B. 802, 604) |
| E | Typ | Siehe Abschnitt 3 |
| F | Zeitanzeige | Anzeige-String "HH:MM - HH:MM" (im Sheet eine Formel aus B/C) |
| G | Werk | Bezeichnung des Termins/Stücks, Freitext |
| H | Teilnehmer | Leerzeichen-getrennte Kürzel der beteiligten Musiker:innen |
| I | Ort | Raumname als Text (z.B. "Kursaal", "Kirchgemeindehaus") — **unklar/zu verifizieren**: ob dies manuell per Dropdown gewählt wird (so legt es MasterOrtDayValidation.gs nahe) oder aus Spalte D per Formel abgeleitet ist. Beim Datenexport beide Spalten (D und I) mitnehmen und die tatsächliche Beziehung anhand der Live-Daten prüfen. |
| J | Bemerkungen | Freitext-Anmerkung, wird auch für die automatische "neu/geändert"-Markierung verwendet (siehe Abschnitt 5) |
| K | Zeit | Dauer, aus B/C berechnet |
| L | Konsolenmeldung | Wird von der Konfliktprüfung beschrieben (siehe Abschnitt 4), sonst leer |

Termine mit fehlender Anfangs-/Endzeit oder fehlendem Werk zählen nicht
als echter Termin (Leerzeile).

## 2. Konfiguration

- **Sheet "confRaeume"**: Spalte A = Liste aller Räume (Quelle für die
  Ort-Auswahl). Spalte N = "Erlaubte Tage" pro Raum als Text (z.B.
  `"Mo-Mi"`, `"Do-So"`, `"Mo,Mi,Fr"`), leer = an allen Tagen erlaubt.
  Deutsche Tages-Codes: Mo, Di, Mi, Do, Fr, Sa, So. War **durchgesetzt seit
  Phase 8** (`raeume.erlaubte_tage`, `raumTagErlaubt()` in
  `server/validation.js`, geprüft in `pruefeKonflikte()` bei
  POST/PUT `/api/termine`) — dieser Code ist Stand 06.09.2026 im
  aktuellen Repo NICHT mehr vorhanden (siehe PROGRESS.md "Kritischer
  Befund"), muss ggf. neu gebaut werden; die Business-Regel selbst
  bleibt gültig.
- **Raumwechsel-Pufferzeiten** ("roomIntervals"): eine Matrix, wie viel
  Minuten Puffer zwischen zwei Terminen im selben Raum nötig sind (bzw.
  zwischen verschiedenen Räumen bei Musiker-Übergängen). Quelle im
  Original-Apps-Script als globale Variable `roomIntervals` referenziert
  — **unklar/zu verifizieren**: die genaue Sheet-Quelle dieser Matrix
  wurde in der bisherigen Arbeit nicht abschliessend lokalisiert. Beim
  Datenexport gezielt danach suchen (vermutlich ein weiterer Bereich in
  "config" oder "confRaeume").

## 3. Termin-Typen (Spalte "Typ")

| Typ | Bedeutung | Teilnehmer-Feld |
|---|---|---|
| *(leer)* | normale Probe/Termin | gefüllt |
| `GP` | Generalprobe | gefüllt |
| `Kzt` | Konzertzeit-Blockkopf — fasst mehrere `K`-Termine zusammen, wird JEDER Musiker:in angezeigt | **immer leer** |
| `K` | einzelnes Konzertstück innerhalb eines `Kzt`-Blocks | gefüllt, normal filtern |
| `Klf` | vereinzelt beobachtet, Bedeutung nicht abschliessend geklärt | unklar — vermutlich Flügel-bezogen ("Klavierflügel"), bei Unsicherheit wie einen normalen Termin ohne Sonderbehandlung behandeln |

**Wichtige Regel** (mehrfach in der bisherigen Arbeit korrigiert): `Kzt`
wird JEDEM Musiker angezeigt (keine Teilnehmer-Prüfung nötig, da das Feld
ohnehin leer ist). ALLE anderen Typen — inklusive `K` — werden ganz normal
nach Teilnehmer-Kürzel gefiltert. Es gibt **keine** weitere
typ-basierte Ausnahme. Ein Musiker sieht einen `K`-Termin NUR, wenn sein
Kürzel in Spalte H steht.

## 4. Konfliktprüfung (Nachfolger von sortDay/checkDay)

Pro Tag, nach Sortieren nach Anfangszeit:

- Zwei Termine im selben Raum dürfen sich nicht überschneiden, und
  zwischen Ende des einen und Start des nächsten muss der raumspezifische
  Mindestabstand aus der Pufferzeiten-Matrix (Abschnitt 2) eingehalten
  werden.
- Verstösse werden aktuell als Text in Spalte "Konsolenmeldung"
  geschrieben. Im neuen System: als Validierungsfehler/-warnung bei
  Anlegen/Ändern eines Termins zurückgeben, nicht mehr in eine
  eigene Spalte schreiben.

## 5. "Stand sperren" / Änderungsmarkierung

Bisher (Sheets): ein Vergleichsschlüssel pro Termin aus
`Anfangszeit|Endzeit|Aud|Typ|Werk|Teilnehmer` (ausdrücklich NICHT Ort,
da von Aud abgeleitet/redundant, und NICHT Bemerkungen, da das
Schreibziel der Markierung selbst ist). Beim Sperren wird der aktuelle
Stand aller Schlüssel gespeichert. Danach wird jeder Termin, dessen
Schlüssel nicht im gespeicherten Stand vorkommt, mit `[NEW]` markiert.

**Im neuen System viel einfacher nachzubauen**: jeder Termin bekommt ein
`updated_at`. Eine Konfiguration speichert `locked_at`. Ein Termin gilt
als "neu/geändert" einfach wenn `updated_at > locked_at` bzw. wenn er
nach dem letzten Sperren angelegt wurde. Kein Schlüssel-Vergleich nötig.

## 6. Die zwei grafischen Ansichten

- **Raumplan-Ansicht**: Räume als Spalten, Zeit als Zeilen (15-Minuten-Raster
  im alten Sheet), Termine als farbige Blöcke.
- **Musiker-Ansicht**: dieselbe Logik, aber gewählte Musiker:innen als
  Spalten statt Räume. Pro Musiker: alle Termine, bei denen sein Kürzel in
  Teilnehmer steht, PLUS alle `Kzt`-Termine (siehe Abschnitt 3).

Bekannter Bug im alten Sheet-Ansatz (dort inzwischen gefixt, aber ein
guter Grund, im neuen System eine echte Timeline-Bibliothek statt eines
festen Zeilenrasters zu verwenden): bei unabhängigem Runden von Start-
und Endzeit auf ein festes Zeitraster können sehr kurze Termine (kürzer
als eine halbe Rasterzeile) rechnerisch auf dieselbe Position fallen wie
der nächste Termin und verschwinden. Mit einer kontinuierlichen
Zeitachse (z.B. FullCalendar Resource-Timeline, vis-timeline) tritt das
strukturell nicht auf.

Farbcodierung nach Typ (aus dem PDF-Export übernehmbar):

| Bedingung | Farbe |
|---|---|
| Typ = `Kzt` | Grün `#b6f2b6` |
| Typ = `K` | Helleres Grün `#d7f2d7` |
| Werk beginnt mit "GP" | Gelb `#fff3b0` |
| Bemerkungen/Werk enthält "aufbau"/"apero"/"logistik"/"musikeressen" | Rosa `#fbd7ea` |
| Bemerkungen/Werk enthält "stimmung" (Flügelstimmung) | Gelb `#fff3b0` |
| sonst | Weiss |
| "neu/geändert" seit letztem Sperren (Abschnitt 5) | eigene, deutlich abweichende Farbe (im Sheet: Orange `#ffd9a0`) — hat Vorrang vor allen anderen Regeln |

## 7. PDF-Export

- **Gesamtplan**: ein PDF pro Tag, alle Räume, farbige Kästchen wie oben,
  überlappende Termine im selben Raum nebeneinander ("Lanes"). War
  implementiert: `GET /api/pdf/gesamtplan?datum=YYYY-MM-DD` (Phase 6,
  `server/pdf.js` + `server/pdf-layout.js`). Bibliothek: `pdfkit`
  (reines JS, kein Chromium/Puppeteer nötig). Läuft produktiv auf dem
  VPS (Phase 6 war vor dem Datenverlust bereits ausgerollt).
- **Individuelle Musikerpläne**: ein PDF pro Musiker:in mit nur den
  eigenen Terminen (plus `Kzt`-Blöcke). War implementiert: `GET
  /api/pdf/musikerplan?datum=YYYY-MM-DD&kuerzel=AB` (Phase 6). Teilt sich
  die Zeichenlogik (`zeichneBaenderSeite`) mit dem Gesamtplan, eigene
  Filterfunktion `filterTermineFuerMusiker` in `pdf-layout.js` (bildet
  dieselbe Kzt-Regel wie `musiker-logik.js` ab, siehe PROGRESS.md
  "Offene Fragen" zur bewussten Code-Duplikation zwischen Browser- und
  Node-Modul). Ebenfalls bereits auf dem VPS ausgerollt.
- Bisher: Freigabe der individuellen PDFs per QR-Code, der auf einen
  Dropbox-Link (über TinyURL gekürzt) zeigt. **Für die neue Web-App**:
  vermutlich unnötig — ein direkter Link auf die eigene Seite in der
  Web-App reicht, Dropbox/TinyURL/QR nur falls explizit weiter gewünscht
  (z.B. für Aushänge ohne Internetzugriff am Ort selbst).

## 8. Was NICHT übernommen werden muss

- Die alten Google-Sheets-Buttons/Dropdowns ("Sortieren"/"Überprüfen")
  — in der neuen App ist jede Änderung sofort aktiv, keine manuelle
  Sortier-/Prüf-Aktion nötig.
- PropertiesService-Workarounds für Zeilen-Zuordnung — in einer echten
  Datenbank hat jeder Termin einfach eine ID.

## 9. Infrastruktur (VPS)

- **Bestellt und aktiv**: Infomaniak VPS Lite.
- **IPv4-Adresse**: `83.228.213.202`
- **SSH-Benutzername**: `ubuntu`
- **Betriebssystem**: Ubuntu 26.04 LTS, 64-bit
- Der private SSH-Schlüssel liegt ausschliesslich auf dem Computer von
  Rafi (dem Auftraggeber) — er ist NICHT Teil dieses Repos und wird auch
  nicht in Aufgaben-/Prompt-Texten hinterlegt.
- **Der VPS selbst behält seinen Stand unabhängig von dieser Sandbox** —
  er läuft mit dem produktiv bestätigten Code bis einschliesslich Phase 7
  (Stand 05.09.2026). Der Datenverlust vom 05./06.09.2026 (siehe
  PROGRESS.md) betrifft NUR diese Cloud-Sandbox, nicht den VPS. Falls
  jemals der Verdacht besteht, dass auch der VPS-Stand von der
  Spezifikation abweicht: den VPS als Quelle der Wahrheit behandeln,
  nicht REFERENCE.md/PROGRESS.md.

**Wichtige, verifizierte Einschränkung**: Eine Cloud-Sandbox-Sitzung
(auch eine nächtliche automatisierte Sitzung wie diese) hat **keinen
allgemeinen Internetzugang zu beliebigen Servern/Ports**. Ein direkter
TCP-Verbindungsversuch zur obigen IP auf Port 22 wurde getestet und
schlägt sofort fehl ("Failed to connect ... after 0 ms") — erreichbar
sind nur wenige fest erlaubte Hosts (z.B. npm-/PyPI-Registries,
Anthropic-eigene Endpunkte), sonst nichts.

**Konsequenz für Phase 2 ("Server-Grundgerüst")**: Eine nächtliche
Sitzung kann sich NICHT selbst per SSH auf den VPS verbinden und dort
etwas einrichten — das würde nur Zeit verschwenden. Stattdessen:
Konfigurationsdateien lokal vorbereiten und ins Repo committen
(Dockerfile, docker-compose.yml, Caddyfile, Setup-/Bootstrap-Skript
für unattended-upgrades, Backup-Cronjob usw.), und diese Dateien per
`SendUserFile` an den Nutzer schicken mit der Bitte, sie ihm entweder
selbst (Copy-Paste-Befehle) oder in einer Sitzung mit verlinktem
Computer auf den Server zu bringen. Erst wenn der Nutzer bestätigt,
dass die Dateien auf dem Server liegen und die Dienste laufen, gilt
Phase 2 als abgeschlossen.

**Update 05.09.2026 — bestätigt und erledigt**: Rafi hat die
Konfigurationsdateien über sein eigenes Terminal auf den VPS gebracht
und `deploy/README.md` durchgearbeitet. `http://83.228.213.202/health`
antwortet von aussen erfolgreich. Dabei gefundene, für künftige Arbeit
wichtige Stolpersteine:

- **Infomaniak hat eine eigene Firewall im Kundencenter/Manager**,
  getrennt von `ufw` auf dem Server selbst. Standardmässig ist dort nur
  SSH (Port 22) freigegeben. Symptom war: `ufw status` zeigt "inactive"
  (also OS-seitig nichts blockiert), `curl http://localhost/health` auf
  dem Server funktioniert, aber `curl http://<ip>/health` von aussen
  läuft in einen Timeout. Fix: im Manager (manager.infomaniak.com) beim
  VPS unter "Firewall"/"Pare-feu" eingehende Regeln für die benötigten
  Ports (80/TCP, 443/TCP) von 0.0.0.0/0 ergänzen. Bei jeder künftigen
  Portfreigabe auf diesem VPS zuerst hier nachsehen, nicht nur `ufw`.
- `docker compose exec <service> psql ... < datei.sql` (Input-
  Umleitung) braucht das `-T`-Flag (`docker compose exec -T ...`), sonst
  Fehler "cannot attach stdin to a TTY-enabled container".
- `$POSTGRES_USER`/`$POSTGRES_DB` aus der `.env`-Datei sind NUR
  `docker compose` selbst bekannt, nicht der interaktiven Shell des
  Nutzers. Ein Befehl wie `psql -U "$POSTGRES_USER" ...` direkt im
  Terminal scheitert deshalb mit "role root does not exist" (leere
  Variable → Fallback auf den OS-Benutzer). Entweder Werte explizit
  eintragen oder vorher `set -a; source .env; set +a` ausführen.

## 10. Relationales Datenmodell (Phase 1, Entwurf)

Entworfen aus Abschnitt 1–5. Ziel: das Master-Sheet plus confRaeume
1:1 fachlich abbilden, ohne die Sheet-Eigenheiten (Formeln, freie
Textspalten) zu übernehmen. War als `db/schema.sql` im Repo committet
und per `psql "$DATABASE_URL" -f db/schema.sql` anwendbar — Stand
06.09.2026 im aktuellen Repo NICHT mehr vorhanden (Datenverlust, siehe
PROGRESS.md), das Design unten bleibt aber die massgebliche Vorlage für
einen Neuaufbau:

```
raeume
  id            serial PK
  name          text UNIQUE NOT NULL      -- entspricht confRaeume Spalte A / Master Spalte I ("Ort")
  aud_code      text UNIQUE               -- entspricht Master Spalte D ("Aud"); nullable, da Beziehung
                                           -- zu "name" noch unklar (siehe Abschnitt 1) — vorläufig als
                                           -- eigenständiges, optionales Feld auf raeume statt als
                                           -- separate Zuordnungstabelle, siehe Offene Fragen.
  erlaubte_tage text[]                    -- Array von 'Mo'..'So'; NULL/leer = alle Tage erlaubt.
                                           -- confRaeume Spalte N ("Mo-Mi" etc.) wird beim Import in
                                           -- diese Liste expandiert (siehe migrate/lib.js: expandTageRange).

musiker
  id       serial PK
  kuerzel  text UNIQUE NOT NULL           -- Master Spalte H, Leerzeichen-getrennt; ein Kürzel = ein Musiker
  name     text                           -- Klarname, sofern bekannt; sonst NULL (nur Kürzel bekannt)

termine
  id           serial PK
  wochentag    text NOT NULL              -- 'Mo'..'So', aus dem Sheet-Block (Abschnitt 1)
  datum        date NOT NULL              -- aus der "Dat"-Zeile des jeweiligen Blocks
  anfangszeit  time NOT NULL
  endzeit      time NOT NULL
  raum_id      int REFERENCES raeume(id) NOT NULL
  typ          text                       -- NULL/'', 'GP', 'Kzt', 'K', 'Klf' (Abschnitt 3)
  werk         text NOT NULL
  bemerkungen  text
  created_at   timestamptz NOT NULL DEFAULT now()
  updated_at   timestamptz NOT NULL DEFAULT now()  -- Basis für Änderungsmarkierung, siehe Abschnitt 5

termin_musiker
  termin_id  int REFERENCES termine(id) ON DELETE CASCADE
  musiker_id int REFERENCES musiker(id) ON DELETE CASCADE
  PRIMARY KEY (termin_id, musiker_id)
  -- Auflösung von Master Spalte H (Teilnehmer). Bei Typ='Kzt' bleibt diese
  -- Tabelle für den Termin leer (siehe Abschnitt 3 — wird trotzdem jedem
  -- Musiker angezeigt, das ist Anwendungslogik, keine Datenbeziehung).

raum_puffer
  von_raum_id int REFERENCES raeume(id)
  bis_raum_id int REFERENCES raeume(id)
  puffer_minuten int NOT NULL
  PRIMARY KEY (von_raum_id, bis_raum_id)
  -- Abbildung der "roomIntervals"-Matrix (Abschnitt 2). Quelle im Sheet
  -- noch nicht lokalisiert -> Tabelle wird vorbereitet, aber der
  -- Migrations-Import befüllt sie vorerst nicht (siehe Offene Fragen).
  -- Fehlender Eintrag für ein Raumpaar = Default-Puffer 0 Minuten
  -- (Annahme, siehe Offene Fragen).

konfiguration
  schluessel text PRIMARY KEY
  wert       text
  -- z.B. schluessel='locked_at', wert=ISO-Timestamp des letzten "Stand
  -- sperren" (Abschnitt 5). Bewusst schlanke Key-Value-Tabelle statt
  -- eigener Spalte/Tabelle, da aktuell nur dieser eine Wert gebraucht wird.
```

Nicht übernommen aus dem Sheet, da abgeleitet/überflüssig (siehe auch
Abschnitt 8): `Nr` (Anzeige-Laufnummer -> ergibt sich aus Sortierung nach
`anfangszeit`), `Zeitanzeige` (Formel aus Anfangszeit/Endzeit -> im
Frontend berechnen), `Zeit`/Dauer (ebenso ableitbar), `Konsolenmeldung`
(wird durch Live-Validierung ersetzt, nicht mehr persistiert).

`[NEW]`-Markierung selbst wird NICHT in der Datenbank gespeichert
(kein Textmarker in `bemerkungen`), sondern rein aus `updated_at` vs.
`konfiguration.locked_at` berechnet (Abschnitt 5).

## 11. Migrationsskript-Grundgerüst (Phase 1)

War im Repo unter `migrate/` (Stand 06.09.2026 NICHT mehr vorhanden,
siehe PROGRESS.md — Design bleibt Vorlage für Neuaufbau):

- `migrate/lib.js` — reine Kernlogik, DB-frei, getestet:
  - `expandTageRange(raw)` — expandiert confRaeume-Spalte-N-Strings wie
    `"Mo-Mi"` oder `"Mo,Mi,Fr"` in ein Array von Tages-Codes; wickelt bei
    Bereichen über das Wochenende (`"So-Di"` -> `["So","Mo","Di"]`).
  - `istEchterTermin(row)` — Leerzeilen-Filter (Abschnitt 1, letzter Satz).
  - `parseTeilnehmer(raw)` — zerlegt Spalte H in Kürzel-Array.
  - `buildModel(masterBloecke, confRaeume)` — normalisiert Rohdaten
    (Array von Tagesblöcken + confRaeume-Array) in `{raeume, musiker,
    termine, warnings}`. Unbekannte Raumnamen führen NICHT zum Abbruch,
    sondern zu einer Warnung + automatisch angelegtem Raum ohne
    Tages-Einschränkung (Annahme, siehe PROGRESS.md).
- `migrate/migrate.js` — CLI: `node migrate/migrate.js [--master f]
  [--confraeume f] [--apply]`. Ohne `--apply`: Dry-Run, druckt nur
  Zusammenfassung + Warnungen. Mit `--apply` und `DATABASE_URL`
  gesetzt: schreibt via `pg` transaktional in Postgres (Upsert für
  raeume/musiker, Insert für termine/termin_musiker). `pg` wird nur bei
  `--apply` per `require` geladen, damit der Dry-Run ohne `npm install`
  läuft.
- `migrate/sample-master.json` + `migrate/sample-confraeume.json` —
  Platzhalterdaten im erwarteten Format (kein echter Sheet-Export
  verfügbar, siehe PROGRESS.md "Offene Fragen").
- `migrate/test/lib.test.js` — Tests für obige Funktionen, mit dem
  eingebauten Node-Test-Runner (`npm test` bzw.
  `node --test migrate/test/*.test.js` — WICHTIG: der Ordner-Modus
  `node --test migrate/test/` schlägt in der aktuellen Node-Version
  22.22 mit "Cannot find module" fehl, deshalb Glob auf `*.test.js`
  verwenden).

Bei Vorliegen eines echten Sheet-Exports: als JSON im selben Format wie
die sample-Dateien ablegen und per `--master`/`--confraeume` einlesen
(bei CSV-Export vorher mit einem kleinen Konvertierungsschritt nach
JSON wandeln).

## 12. Deployment-Konfiguration (Phase 2)

War im Repo unter `deploy/` (Details/Anleitung: `deploy/README.md`,
Stand 06.09.2026 NICHT mehr im Repo vorhanden — läuft aber unverändert
produktiv auf dem VPS, siehe Abschnitt 9: Docker-Compose-Setup mit
App-Container + Postgres + Caddy, Caddyfile mit Übergangs-/
Produktivvariante, `.env.example`, Bootstrap-Skript für
unattended-upgrades). Backup-Cronjob und Swiss-Backup-Integration:
noch nicht begonnen, wartet auf Bestellung von Swiss Backup (siehe
PROGRESS.md Phase 0/2).

## 13. Technische Lehren aus der Implementierung (Fallstricke)

Kurz gehaltene Sammlung von Fehlern, die während der Implementierung
auftraten und beim nächsten Mal von vornherein vermieden werden sollten.
Ausführlicher Kontext ggf. in der Git-Historie (`git log`).

- **Dockerfile-COPY vergessen**: jede neue Datei unter `server/`, die per
  `require()` oder `<script src>` eingebunden wird, muss auch im
  `Dockerfile` landen (COPY-Zeile) bzw. unter `COPY public ./public`
  (deckt alles unter `public/` automatisch ab) — sonst läuft es lokal,
  aber der Container crasht mit "Cannot find module ...".
- **node-postgres liefert `time`-Spalten als `"HH:MM:SS"`**, nicht
  `"HH:MM"`. Jede Zeit-Parsing-Funktion (`server/validation.js:
  timeToMinutes`) muss das akzeptieren, sonst brechen Vergleiche mit aus
  der DB gelesenen Werten still (JS: `null + x = x`, keine Exception,
  keine Fehlermeldung — nur falsches Ergebnis).
- **vis-timeline: bei Datenwechsel NICHT `destroy()` + neu erzeugen** —
  führt zu dauerhaft `visibility: hidden`. Stattdessen die bestehende
  Instanz mit `setGroups()`/`setItems()`/`setWindow()` aktualisieren.
- **Infomaniak-VPS hat eine eigene Firewall im Kundencenter/Manager**,
  getrennt von `ufw` auf dem Server selbst — bei jeder neuen
  Portfreigabe zuerst dort nachsehen (Details: Abschnitt 9).
- **`docker compose exec` + Input-Umleitung (`< datei.sql`) braucht
  `-T`** (sonst TTY-Konflikt); `$POSTGRES_USER`/`$POSTGRES_DB` aus
  `.env` sind nur `docker compose` selbst bekannt, nicht der
  interaktiven Shell (Details: Abschnitt 9).
- **Unit-Tests mit Hand-gebauten Mock-Daten reichen bei DB-/Browser-naher
  Logik nicht aus** — mehrere der obigen Bugs (Zeit-Format,
  Timeline-Rendering) wurden erst durch echte End-to-End-Tests gegen
  Postgres bzw. einen echten Browser (Playwright/Chromium) sichtbar.
  Vor "fertig" immer beides testen, nicht nur Unit-Tests mit Mock-Daten.
  Dasselbe gilt für PDF-Erzeugung: erst per echtem PDF-Tool prüfen (z.B.
  `qpdf --check`, `pdftotext`/`pdftoppm` aus poppler-utils), nicht nur
  "die Funktion wirft keinen Fehler".
- **npm-Paket `pdf-parse` ist inkompatibel mit von `pdfkit` erzeugten
  PDFs** — meldet "bad XRef entry" selbst bei einem minimalen
  pdfkit-"Hallo Welt"-PDF, obwohl `qpdf --check` und `pdftotext`
  dieselbe Datei klaglos akzeptieren und den Text korrekt extrahieren.
  Für Tests, die den Textinhalt eines erzeugten PDFs prüfen sollen,
  `pdftotext` (poppler-utils, per `child_process`) verwenden, nicht
  `pdf-parse`.
- **NIE einen `WWW-Authenticate`-Header auf eine 401-Antwort setzen, die
  per `fetch()` aus eigenem JavaScript geprüft werden soll** (Phase 7,
  Organisator:innen-Login) — der Browser fängt das selbst ab und
  versucht, sein EIGENES natives Zugangsdaten-Dialogfeld zu öffnen. In
  Headless-Umgebungen (z.B. Playwright-Tests) hängt der `fetch()`-Aufruf
  dadurch für immer, ohne jemals eine Antwort oder einen Fehler zu
  liefern — per echtem Browser-Test entdeckt, nicht durch `curl` (das
  Problem existiert dort nicht, weil `curl` keinen nativen Auth-Dialog
  kennt). In echten Browsern führt derselbe Header zu einem
  verwirrenden zweiten Login-Popup neben einem eigenen `prompt()`-Dialog.
  Eine 401-JSON-Antwort ohne diesen Header wird dagegen ganz normal an
  `fetch()` durchgereicht.
- **Ein als "✅ abgeschlossen" markierter Plan-Punkt war es nicht wirklich**:
  Phase 3 (Terminverwaltung) war seit ihrem Abschluss als fertig markiert
  und listete "Wochentags-Raumbeschränkung (Nachfolger
  MasterOrtDayValidation.gs)" explizit als erledigtes Deliverable — dabei
  gab es dafür nie Code (`raeume.erlaubte_tage` war im Schema angelegt,
  wurde aber nirgends geprüft). Aufgefallen erst beim Bau der
  Terminverwaltung (Phase 8), weil dort erstmals bewusst nachgesehen
  wurde, ob diese Regel überhaupt greift. Lehre: ein Haken in PROGRESS.md
  ist keine Garantie — bei Unsicherheit im Code selbst nachsehen (`grep`
  nach dem erwarteten Feld/der erwarteten Prüfung), nicht nur dem
  Status-Text vertrauen.
- **node-postgres liefert `date`-Spalten als JS-Date-Objekt** (Mitternacht
  UTC), nicht als `"YYYY-MM-DD"`-String — `JSON.stringify` macht daraus
  einen vollen ISO-Zeitstempel (`"2026-09-07T00:00:00.000Z"`). Ein
  `<input type="date">`, dem dieser Wert direkt zugewiesen wird, bleibt
  dadurch STILL leer (kein Fehler, keine Konsolen-Meldung) — per echtem
  Browser-Test gefunden, als die Terminverwaltung (Phase 8) `t.datum`
  aus der API-Antwort erstmals in ein Formular schrieb. Fix: zentral in
  `groupTermineRows` (`server/queries.js`) normalisieren, nicht jedem
  Aufrufer überlassen.
- **Ein `fetch()`-Erfolgs-Handler, der eine zweite asynchrone Funktion
  aufruft und DANACH synchron eine Statusmeldung setzt, kann sich selbst
  überschreiben**, wenn die zweite Funktion den Status ebenfalls setzt
  (z.B. "Lade..." beim Start, "" bei Erfolg) — die zweite (spätere)
  Zuweisung gewinnt, auch wenn sie aus dem "früheren" Aufruf stammt,
  weil beides Promises sind. Gefunden per echtem Browser-Test in
  `admin.html` (Phase 8): "Termin angelegt." verschwand sofort wieder,
  weil das anschliessende `ladeTag()` beim Abschluss seines eigenen
  Fetches den Status zurücksetzte. Fix: `ladeTag()` gibt sein Promise
  zurück, die Erfolgsmeldung wird erst in einem `.then()` NACH diesem
  Promise gesetzt, nicht direkt im Anschluss an den (nicht abgewarteten)
  Aufruf.
- **NEU 06.09.2026 — der wichtigste Fallstrick von allen: "im Repo
  committet" ist NICHT gleich "gesichert"**, solange `git push` nicht
  funktioniert. Die Cloud-Sandbox, in der eine nächtliche (und
  vermutlich auch eine interaktive Tages-) Sitzung läuft, kann
  zwischenzeitlich komplett und rückstandslos neu bereitgestellt
  werden — bestätigt in der Nacht vom 05. auf den 06.09.2026: das
  gesamte Verzeichnis inkl. `.git`-Historie war weg, keine Spuren im
  gesamten restlichen Dateisystem. Betroffen war der komplette
  Phase-8-Code (`admin.html`, `raumTagErlaubt`, `GET /api/raeume`,
  `server/test/index.test.js`, beide Bugfixes oben), der am Vortag
  gebaut, aber noch nicht per ZIP an Rafi verschickt worden war ("ZIP
  schicken, sobald er bereit ist zu deployen" — genau diese Verzögerung
  war die Lücke). Lehre: ein lokaler `git commit` schützt nur vor
  Verlust durch eigene Fehler in derselben Sitzung, NICHT vor einer
  Neubereitstellung der ganzen Sandbox. Die einzigen wirklich robusten
  Sicherungen sind (a) ein erfolgreicher `git push` zu GitHub (aktuell
  durch einen Proxy-Bug blockiert, siehe PROGRESS.md) und (b) ein
  tatsächlich an Rafi verschicktes ZIP (`SendUserFile`). Deshalb ab
  sofort: ZIP-Versand nach jeder Code-Änderung SOFORT, nicht erst bei
  Deploy-Bereitschaft (siehe README.md Arbeitsweise Punkt 4).

## 14. Zugriffsmodell (Phase 7)

Entschieden von Rafi (05.09.2026, interaktive Tagsitzung): **Variante A**
— Lesen ist für alle offen, die den Link/die VPS-Adresse kennen (Raumplan-
und Musiker-Ansicht, PDF-Export, `GET /api/*`); kein Login, kein Konto
pro Musiker:in nötig. NUR Schreiben (Termine anlegen/ändern/löschen,
`POST /api/termine`, `PUT /api/termine/:id`, `DELETE /api/termine/:id`,
sowie "Stand sperren", `POST /api/stand/sperren`) ist geschützt — mit
einem einzigen, gemeinsamen Passwort für Organisator:innen, nicht mit
individuellen Konten.

Umsetzung (läuft produktiv auf dem VPS, Code dort vorhanden, im
Sandbox-Repo Stand 06.09.2026 nicht mehr): `server/auth.js`, Middleware
`pruefeOrganisatorAuth`, auf die vier genannten Schreib-Routen
angewendet. Zugangsdaten werden im "Basic"-Format übertragen
(`Authorization: Basic base64(benutzer:passwort)`), aber bewusst OHNE
echten HTTP-Basic-Auth-Handshake (kein `WWW-Authenticate`-Header — siehe
Abschnitt 13, sonst hängt/stört das den Browser). Benutzername ist
serverseitig per `ORGANISATOR_BENUTZER` konfigurierbar (Default
`organisator`), das Frontend (`raumplan.html`) hat diesen Default fest
verdrahtet und fragt nur nach dem Passwort (`window.prompt`), einmal pro
Seitenaufruf, im Speicher gehalten statt persistiert.
`ORGANISATOR_PASSWORT` ist Pflicht in der `.env` — fehlt es, wird
Schreiben komplett deaktiviert (503) statt versehentlich offen zu
bleiben (analog zu `POSTGRES_PASSWORD`, siehe Abschnitt 12).

## 15. Terminverwaltung / Admin-Oberfläche (Phase 8)

**Stand 06.09.2026: dieser Code ist im aktuellen Sandbox-Repo NICHT mehr
vorhanden (Datenverlust, siehe PROGRESS.md "Kritischer Befund") und noch
nicht auf dem VPS ausgerollt — d.h. er existiert aktuell möglicherweise
nirgends mehr ausser evtl. in einem ZIP bei Rafi.** Die folgende
Beschreibung ist die Spezifikation für einen Neuaufbau, keine Bestätigung,
dass der Code noch existiert.

Bisher (bis Phase 7) gab es für Termine nur die rohe CRUD-API — Anlegen/
Ändern/Löschen musste per curl o.ä. passieren. Für den in Phase 8 vorgesehenen
Testlauf mit echten Terminen einer Probenwoche (siehe PROGRESS.md) reicht das
nicht: **`server/public/admin.html`** war die dafür gebaute Oberfläche.

- Tagesansicht (Datum vor/zurück wie Raumplan-/Musiker-Ansicht) mit
  Tabelle aller Termine dieses Tages; Zeilen mit "neu/geändert" seit dem
  letzten Sperren farblich hervorgehoben (Abschnitt 5).
- "+ Neuer Termin" öffnet ein Formular; "Bearbeiten" in einer Zeile
  öffnet dasselbe Formular vorausgefüllt (PUT statt POST).
- Raum-Auswahl über den in Phase 8 neu ergänzten Endpunkt **`GET
  /api/raeume`** (liefert ALLE Räume, auch ohne Termin an diesem Tag —
  vorher gab es dafür keinen Endpunkt, siehe PROGRESS.md "Bekannte
  Einschränkung" zu Phase 4). Zeigt pro Raum direkt die erlaubten
  Wochentage an (Abschnitt 2).
- Wochentag wird aus dem gewählten Datum automatisch berechnet
  (`wochentagVonDatum`), nicht separat vom Menschen ausgewählt — schliesst
  Tippfehler-Inkonsistenzen zwischen Datum und Wochentag von vornherein
  aus.
- Typ=Kzt sperrt das Teilnehmer-Feld im Formular (statt es nur zu
  verstecken) — visuelle Erinnerung an die Business-Regel aus
  Abschnitt 3, nicht nur serverseitig durchgesetzt.
- Validierungs- (400) und Konfliktfehler (409, inkl. der in Phase 8
  nachgerüsteten Wochentags-Raumbeschränkung) werden direkt im Formular
  angezeigt, nicht nur als generische Fehlermeldung.
- Auth-Muster identisch zu `raumplan.html` (Abschnitt 14):
  `window.prompt` einmal pro Seitenaufruf, Passwort verworfen bei 401.
- War end-to-end verifiziert: echtes Postgres (`server/test/index.test.js`)
  + echter Browser (Playwright: Anlegen/Bearbeiten/Löschen, falsches
  Passwort, Überschneidungs- und Wochentags-Konflikt, Kzt-Feldsperre).
  Dabei zwei echte Bugs gefunden und behoben — Details in Abschnitt 13
  (`datum` als Date-Objekt statt String; Status-Meldung, die sich selbst
  überschreibt).
- Nav-Links zwischen allen drei Seiten (`raumplan.html`,
  `musikerplan.html`, `admin.html`) ergänzt.
