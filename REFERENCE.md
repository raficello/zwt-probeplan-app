# Fachliche Referenz: ZwT 2026 - Probeplan (Google Sheet)

Zusammenfassung der über viele Sitzungen ermittelten fachlichen Logik, damit
eine Sitzung ohne Chat-Historie das System korrekt nachbauen kann. Wo
"unklar/zu verifizieren" steht: sinnvolle Annahme treffen, in PROGRESS.md
"Offene Fragen" vermerken, nicht auf Antwort warten.

**Update 06.09.2026**: Der komplette Code (Phase 1–8: `db/`, `migrate/`,
`server/` inkl. `admin.html`, `deploy/`) war nach einer Sandbox-
Neubereitstellung verloren, wurde aber NOCH IN DERSELBEN NACHT aus zwei
ZIP-Backups von Rafi vollständig wiederhergestellt (siehe PROGRESS.md)
— alle "Code verloren"-Hinweise, die in einer früheren Fassung dieser
Datei noch standen, sind damit überholt. Diese Datei wurde ausserdem am
06.09.2026 stark gekürzt (fälschlich angenommenes update_trigger-
Grössenlimit, siehe PROGRESS.md — Korrektur); Detailnarrative sind
dabei verlorengegangen, die Kernfakten (Regeln, Schema, Fixes) sind
erhalten.

## 1. Sheet "Master"

7 Wochentagsblöcke (Mo–So) im selben Blatt. Je Block: "Dat"-Zeile (A="Dat",
B=Datum), Kopfzeile, dann Termine. Spalten: A Nr (Anzeige) | B Anfangszeit
HH:MM | C Endzeit HH:MM | D Aud (Raum-Code, numerisch) | E Typ (Abschnitt 3)
| F Zeitanzeige (Formel) | G Werk (Freitext) | H Teilnehmer (Kürzel,
leerzeichengetrennt) | I Ort (Raumname als Text — Verhältnis zu D unklar,
siehe Offene Fragen) | J Bemerkungen | K Zeit (Dauer) | L Konsolenmeldung
(Konfliktprüfung). Zeilen ohne Anfangs-/Endzeit oder Werk = keine echten
Termine.

## 2. Konfiguration

- Sheet "confRaeume" (jetzt bestätigt: Tab **"Config"** im Google Sheet,
  benannte Bereiche `conf_raume`/`conf_intervals`): Spalte A = Raumliste,
  Spalte N = erlaubte Tage (`"Mo-Mi"`, `"Do-So"`, `"Mo,Mi,Fr"`, leer=alle
  Tage; Codes Mo-So). War durchgesetzt seit Phase 8 (`raeume.erlaubte_tage`,
  `raumTagErlaubt()` in `server/validation.js`). Code wiederhergestellt
  (06.09.2026, Rafis zweitem ZIP), läuft produktiv. Echte Raumliste (12
  Räume, Stand 06.09.2026 aus dem Config-Tab ausgelesen) + erlaubte Tage +
  Pufferzeiten in `db/seed-raeume.sql` — war vorher nie in die
  Produktions-DB eingespielt, deshalb leere Raumliste in `admin.html`.
- Pufferzeiten-Matrix ("roomIntervals"): Minuten Puffer beim Raumwechsel
  zwischen zwei Räumen (12×12-Matrix, symmetrisch, Diagonale=0). **Quelle
  jetzt gefunden** (06.09.2026): derselbe Config-Tab, benannter Bereich
  `conf_intervals`, direkt neben `conf_raume`. Werte in `db/seed-raeume.sql`
  eingetragen. **Wichtige Lücke entdeckt**: die aktuelle Konfliktprüfung
  (`SELECT_RAUM_PUFFER_SQL` in `server/queries.js`) fragt `raum_puffer`
  nur mit `von_raum_id = bis_raum_id` ab (derselbe Raum) — die Matrix ist
  aber für unterschiedliche Raumpaare gedacht (Wegzeit zwischen zwei
  verschiedenen Räumen für dieselbe Person). Diese raumübergreifende Logik
  fehlt in der Implementierung noch komplett; mit den echten Daten (kaum
  eine Null auf der Diagonale ausser sich selbst) wirkt sich das aktuell
  so aus, dass praktisch NIE ein Pufferzeit-Konflikt gemeldet wird. Noch
  nicht behoben, siehe PROGRESS.md "Offene Fragen".

## 3. Termin-Typen

Leer/GP = normaler Termin, Teilnehmer gefüllt. `Kzt` = Konzertzeit-
Blockkopf, fasst `K`-Termine zusammen, **wird JEDEM Musiker angezeigt**,
Teilnehmer-Feld immer leer. `K` = einzelnes Konzertstück, Teilnehmer
gefüllt, **normal filtern wie jeder andere Typ**. `Klf` unklar (vermutlich
Flügel), ohne Sonderbehandlung behandeln. Wichtig: `Kzt` ist die EINZIGE
Ausnahme von der Teilnehmer-Filterung — auch `K` wird normal gefiltert.

## 4. Konfliktprüfung

Pro Tag nach Anfangszeit sortiert: zwei Termine im selben Raum dürfen sich
nicht überschneiden und brauchen den raumspezifischen Mindestabstand
(Abschnitt 2) zwischen Ende/Start. Im neuen System: Validierungsfehler bei
Anlegen/Ändern zurückgeben statt in Spalte schreiben.

## 5. "Stand sperren" / Änderungsmarkierung

Neues System: jeder Termin hat `updated_at`, Konfiguration speichert
`locked_at`. "neu/geändert" = `updated_at > locked_at`. Kein
Schlüsselvergleich wie im alten Sheet nötig.

## 6. Ansichten & Farben

Raumplan-Ansicht (Räume=Spalten) und Musiker-Ansicht (gewählte
Musiker:innen=Spalten, je alle eigenen Termine + alle `Kzt`). Echte
Timeline-Bibliothek (nicht festes Zeitraster) nötig, sonst können kurze
Termine bei unabhängigem Runden von Start/Ende verschwinden.

Farben nach Typ: `Kzt`=Grün `#b6f2b6`, `K`=Hellgrün `#d7f2d7`, Werk beginnt
"GP"=Gelb `#fff3b0`, Bemerkungen/Werk enthält aufbau/apero/logistik/
musikeressen=Rosa `#fbd7ea`, enthält "stimmung"=Gelb, sonst Weiss.
"Neu/geändert" (Abschnitt 5) = Orange `#ffd9a0`, hat Vorrang vor allem.

## 7. PDF-Export

`GET /api/pdf/gesamtplan?datum=YYYY-MM-DD`: ein PDF/Tag, alle Räume, Lanes
für Überschneidungen. `GET /api/pdf/musikerplan?datum=...&kuerzel=AB`:
nur eigene Termine + `Kzt`. Bibliothek `pdfkit`. War implementiert
(Phase 6, `server/pdf.js`+`pdf-layout.js`), Code wiederhergestellt
(06.09.2026, aus Rafis ZIP), lief/läuft produktiv auf VPS. QR/Dropbox/TinyURL für Web-App
vermutlich unnötig (direkter Link reicht).

## 8. Nicht zu übernehmen

Alte Sheets-Buttons ("Sortieren"/"Überprüfen") — App ist immer live.
PropertiesService-Workarounds für Zeilen — DB hat IDs.

## 9. Infrastruktur (VPS)

Infomaniak VPS Lite, IPv4 `83.228.213.202`, SSH-User `ubuntu`, Ubuntu
26.04 LTS 64-bit. SSH-Key nur bei Rafi, nicht im Repo. VPS behält seinen
Stand unabhängig von der Sandbox — läuft produktiv bis Phase 7 (Stand
05.09.2026), vom Datenverlust NICHT betroffen; bei Zweifel VPS als Quelle
der Wahrheit behandeln.

Sandbox hat KEINEN allgemeinen Internetzugang (nur npm/PyPI/Anthropic-
Hosts) — kein SSH zum VPS möglich, verifiziert. Deshalb: Config-Dateien
lokal vorbereiten, committen, per SendUserFile als ZIP schicken, Rafi
bringt sie selbst auf den Server.

Bekannte Stolperfallen (bestätigt 05.09.2026 beim ersten Rollout):
Infomaniak hat eine EIGENE Firewall im Kundencenter/Manager
(manager.infomaniak.com), getrennt von `ufw` — bei Portfreigabe (80/443)
zuerst dort nachsehen, nicht nur `ufw status`. `docker compose exec
<service> psql ... < datei.sql` braucht `-T`-Flag (sonst TTY-Fehler).
`$POSTGRES_USER`/`$POSTGRES_DB` aus `.env` kennt nur `docker compose`
selbst, nicht die interaktive Shell — vorher `set -a; source .env; set +a`.

## 10. Relationales Datenmodell (`db/schema.sql`)

War im Repo, Stand 06.09.2026 aus Rafis ZIP wiederhergestellt (siehe
PROGRESS.md), Design bleibt massgeblich:

```
raeume
  id serial PK
  name text UNIQUE NOT NULL      -- confRaeume Spalte A / Master Spalte I
  aud_code text UNIQUE           -- Master Spalte D; Beziehung zu name unklar
  erlaubte_tage text[]           -- 'Mo'..'So'; NULL/leer = alle Tage

musiker
  id serial PK
  kuerzel text UNIQUE NOT NULL   -- Master Spalte H, Leerzeichen-getrennt
  name text                      -- Klarname falls bekannt, sonst NULL

termine
  id serial PK
  wochentag text NOT NULL        -- 'Mo'..'So'
  datum date NOT NULL
  anfangszeit time NOT NULL
  endzeit time NOT NULL
  raum_id int REFERENCES raeume(id) NOT NULL
  typ text                       -- NULL/'', 'GP', 'Kzt', 'K', 'Klf'
  werk text NOT NULL
  bemerkungen text
  created_at timestamptz NOT NULL DEFAULT now()
  updated_at timestamptz NOT NULL DEFAULT now()

termin_musiker
  termin_id int REFERENCES termine(id) ON DELETE CASCADE
  musiker_id int REFERENCES musiker(id) ON DELETE CASCADE
  PRIMARY KEY (termin_id, musiker_id)
  -- bei Typ='Kzt' bleibt leer, wird trotzdem jedem Musiker angezeigt (Anwendungslogik)

raum_puffer
  von_raum_id int REFERENCES raeume(id)
  bis_raum_id int REFERENCES raeume(id)
  puffer_minuten int NOT NULL
  PRIMARY KEY (von_raum_id, bis_raum_id)
  -- fehlender Eintrag = Default 0 Minuten (Annahme)

konfiguration
  schluessel text PRIMARY KEY
  wert text                      -- z.B. 'locked_at' -> ISO-Timestamp
```

Nicht übernommen (abgeleitet/überflüssig): Nr, Zeitanzeige, Zeit/Dauer,
Konsolenmeldung (durch Live-Validierung ersetzt). `[NEW]` wird NICHT
gespeichert, nur aus `updated_at`/`locked_at` berechnet.

## 11. Migrationsskript (`migrate/`)

Stand 06.09.2026 aus Rafis ZIP wiederhergestellt, 13 Tests grün: `migrate/lib.js` (DB-frei,
getestet) mit `expandTageRange(raw)` (expandiert "Mo-Mi"/"Mo,Mi,Fr" inkl.
Wochenend-Wrap "So-Di"→[So,Mo,Di]), `istEchterTermin(row)` (Leerzeilen-
Filter), `parseTeilnehmer(raw)`, `buildModel(masterBloecke, confRaeume)`
(unbekannte Räume → Warnung + Auto-Anlage ohne Tagesbeschränkung, kein
Abbruch). `migrate/migrate.js` CLI: `--master`/`--confraeume`/`--apply`
(ohne `--apply` = Dry-Run ohne DB, `pg` nur bei `--apply` geladen).
Sample-Dateien `migrate/sample-master.json`+`sample-confraeume.json`
(kein echter Export vorhanden). Tests: `node --test migrate/test/*.test.js`
(Ordner-Modus schlägt in Node 22.22 fehl, Glob verwenden).

## 12. Deployment (`deploy/`)

Stand 06.09.2026 aus Rafis ZIP wiederhergestellt, läuft unverändert auf VPS: Docker-Compose
(App+Postgres+Caddy), Caddyfile mit IP-Übergangsvariante (kein HTTPS bis
Domain geklärt), `.env.example`, unattended-upgrades-Bootstrap.
Backup-Cronjob (Swiss Backup) noch nicht begonnen, wartet auf Bestellung.

## 13. Technische Lehren (Fallstricke)

- Jede neue `server/`-Datei braucht eine Dockerfile-COPY-Zeile (oder liegt
  unter `public/`, das komplett kopiert wird) — sonst crasht der Container.
- node-postgres liefert `time` als `"HH:MM:SS"`, nicht `"HH:MM"` —
  Zeit-Parsing muss das akzeptieren, sonst stille Fehlvergleiche.
- vis-timeline: bei Datenwechsel `setGroups()`/`setItems()`/`setWindow()`
  nutzen, NICHT `destroy()`+neu erzeugen (sonst dauerhaft `hidden`).
- `docker compose exec <service> psql ... < datei.sql` braucht `-T`.
- Unit-Tests mit Mock-Daten reichen bei DB-/Browser-naher Logik nicht —
  immer zusätzlich gegen echtes Postgres/Browser (Playwright) testen.
  Für PDFs: `qpdf --check`/`pdftotext` statt nur "wirft keinen Fehler".
- `pdf-parse` ist inkompatibel mit `pdfkit`-PDFs (false positive "bad
  XRef") — `pdftotext` (poppler-utils) für Textprüfung verwenden.
- NIE `WWW-Authenticate`-Header auf eine 401 setzen, die per `fetch()`
  geprüft wird — Browser versucht eigenen nativen Login-Dialog, `fetch()`
  hängt in Headless-Umgebungen für immer. Reines 401-JSON ohne den Header
  funktioniert normal.
- Ein "✅ abgeschlossen" in PROGRESS.md ist keine Garantie: die
  Wochentags-Raumbeschränkung stand als erledigt, war aber nie geprüft
  (Feld im Schema, aber nirgends abgefragt) — erst bei Phase 8 aufgefallen.
  Bei Unsicherheit im Code selbst nachsehen (grep), nicht nur Status-Text.
- node-postgres liefert `date` als JS-Date-Objekt (Mitternacht UTC), nicht
  als String — direkt in `<input type="date">` geschrieben bleibt es still
  leer. Zentral normalisieren (z.B. in der Query-Funktion), nicht jedem
  Aufrufer überlassen.
- Ein `fetch()`-Erfolgs-Handler, der danach eine zweite async Funktion
  aufruft, die selbst eine Statusmeldung setzt, kann sich selbst
  überschreiben (spätere Promise-Auflösung gewinnt) — Erfolgsmeldung erst
  im `.then()` NACH der zweiten Funktion setzen, nicht direkt danach.
- **NEU 06.09.2026, wichtigster Fallstrick**: "im Repo committet" ist
  NICHT gleich "gesichert", solange `git push` nicht funktioniert. Die
  Cloud-Sandbox kann zwischen Sitzungen komplett neu bereitgestellt
  werden (bestätigt in der Nacht 05./06.09.2026: kompletter Phase-8-Code
  weg, keine Spuren im Dateisystem) — betroffen war Code, der noch nicht
  per ZIP verschickt war. Einzige robuste Sicherung: erfolgreicher `git
  push` ODER tatsächlich verschicktes ZIP. Deshalb: ZIP SOFORT nach jeder
  Code-Änderung, nicht erst bei Deploy-Bereitschaft.

## 14. Zugriffsmodell (Phase 7)

Variante A (Rafi, 05.09.2026): Lesen komplett offen (Raumplan/Musiker-
Ansicht, PDF, `GET /api/*`), kein Login. NUR Schreiben (`POST/PUT/DELETE
/api/termine*`, `POST /api/stand/sperren`) geschützt mit einem
gemeinsamen Organisator:innen-Passwort (nicht individuell). War
umgesetzt: `server/auth.js`, `pruefeOrganisatorAuth`-Middleware,
`Authorization: Basic base64(benutzer:passwort)` OHNE echten
Basic-Auth-Handshake (kein `WWW-Authenticate`, siehe Abschnitt 13).
`ORGANISATOR_BENUTZER` konfigurierbar (Default `organisator`), Frontend
fragt Passwort per `window.prompt` einmal pro Seitenaufruf, nur im
Speicher. `ORGANISATOR_PASSWORT` Pflicht in `.env` — fehlt es, Schreiben
komplett deaktiviert (503). Code Stand 06.09.2026 aus Rafis ZIP
wiederhergestellt, lief/läuft produktiv, von Rafi bestätigt.

## 15. Terminverwaltung / admin.html (Phase 8)

`server/public/admin.html` — **auf dem VPS ausgerollt und von Rafi
bestätigt (06.09.2026): Speichern/Löschen funktioniert produktiv.**

Tagesansicht mit Terminliste (neu/geändert farblich hervorgehoben, siehe
Abschnitt 5), "+ Neuer Termin"/"Bearbeiten"-Formular (POST/PUT). Raum-
Auswahl über `GET /api/raeume` (liefert ALLE Räume, auch ohne Termin
heute — zeigt erlaubte Wochentage pro Raum; Produktionsdaten dafür in
`db/seed-raeume.sql`, siehe Abschnitt 2). Datum ist eine Auswahlliste
der Festival-Tage (`FESTIVAL_TAGE`, siehe Abschnitt 6), Wochentag daraus
automatisch berechnet. Typ=Kzt sperrt Teilnehmer-Feld im Formular.
Werk-Feld hat Autocomplete (Abschnitt 16). Validierungs-(400)/Konflikt-
(409)-Fehler direkt im Formular angezeigt. Auth wie `raumplan.html`
(Abschnitt 14). War end-to-end verifiziert (echtes Postgres + Playwright:
Anlegen/Bearbeiten/Löschen, falsches Passwort, Konflikte, Kzt-Feldsperre)
— dabei 2 Bugs gefunden+behoben (Abschnitt 13: Date-Objekt-Bug,
Status-Meldung-überschreibt-sich-Bug). Nav-Links zwischen `raumplan.html`,
`musikerplan.html`, `admin.html` ergänzt.

## 16. Werk-/Konzertliste (Phase 8-Erweiterung, 06.09.2026)

Rafis Nummerierung ("401 = erstes Werk des Konzertes 4") ist jetzt
vollständig aus dem Google Sheet bestätigt (Excel-Export, Tab "config",
per `openpyxl` gelesen — zuverlässiger als der Google-Drive-Connector,
der diesen Tab nicht vollständig lieferte). Zwei getrennte Listen:

- **Konzertliste** (`konzerte`/`werke`-Tabellen): 11 Konzert-Blöcke
  (Blockcode 000 = "Freundeskonzert", dann 100–1000 = Konzert 1–10),
  je mit ihren Werken (Nummer = Konzert-Nr × 100 + Sequenz, z.B. 401 =
  Konzert 4, 1. Werk "Mozart Duo B-Dur", Standard-Teilnehmer DU/YL).
  36 Werke importiert (1 Eintrag "502a" mit nicht-numerischem Code
  bewusst übersprungen, siehe PROGRESS.md).
- **Werk-Vorlagen** (`werk_vorlagen`-Tabelle): 21 feste, wiederkehrende
  Ablaufpunkte mit fixer Nummer 1–23 (Lücken bei 12/13) und
  Standard-Teilnehmerkreis — Saaleinlass, Flügelstimmung, Dîner,
  Musikerführung im Kloster, Musikeressen, Gottesdienst, Rede, Apero
  Freundeskonzert, Abschlussrede und Bedankungen, Schlussapero,
  Anlieferung/Stimmung Flügel, Aufbau Technik/Licht, Soundcheck
  Mikrofon, Aufbau Apero, Freundeskonzert Rede, Umbau Saal, Practising
  AL/PFB/VL, Apero bei Birgit Miller, Einführung Holliger.

Beide Listen sind Datenquelle für `GET /api/werke/vorschlaege?q=<Text>`
(`server/queries.js`: `SELECT_WERK_VORSCHLAEGE_SQL`, `server/index.js`)
— Suche per Nummer- ODER Namens-Präfix über beide Tabellen kombiniert,
liefert je Treffer den Standard-Teilnehmerkreis mit. `admin.html`
nutzt das für ein `<datalist>`-Autocomplete am Werk-Feld: exakter
Treffer (Nummer oder Name) füllt Teilnehmer (+ Typ falls leer) vor,
bleibt änderbar. Musiker:innen jetzt mit echten Namen (17 Personen,
vorher nur Kürzel bekannt) aus derselben Quelle in `musiker.name`
nachgetragen.

Schema: `db/migration-werke.sql` (Tabellen), `db/seed-werke-2026.sql`
(Daten, programmatisch aus dem Excel generiert, nicht von Hand
abgetippt — Konsistenz mit dem Original garantiert). Beide lokal
end-to-end getestet (echtes Postgres, echter Server, echter
Playwright-Browser: Eingabe "401" → Teilnehmer-Feld füllt sich mit
"DU YL"). Bewusst OHNE Saison-Bezug — siehe PROGRESS.md "Offene
Fragen" zur separat angefragten, aber vertagten Saison-Verwaltung.
