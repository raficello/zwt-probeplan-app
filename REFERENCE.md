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
Musiker:innen=Spalten, je alle eigenen Termine + alle `Kzt`).

**Vertikale Tagesansicht (Rafi-Feedback, 07.09.2026)**: `raumplan.html`
und `musikerplan.html` zeigen die Termine als eigenes, selbstgebautes
Zeitraster — Zeit läuft von oben nach unten, Räume/Musiker:innen sind
Spalten — analog zu den Tabs "Raumplan Grafik"/"Musiker Grafik" im
Original-Google-Sheet. Ersetzt die bisherige `vis-timeline`-Bibliothek
(horizontale Zeitachse, Gruppen als Zeilen), die dafür kein passendes
Layout bot; Abhängigkeit `vis-timeline` deshalb aus `package.json`
entfernt (`npm install` neu ausgeführt, `package-lock.json` aktualisiert
— beim nächsten Deploy zieht `docker compose up -d --build app` das
automatisch nach).

Aufbau: `server/public/tagesraster.js` enthält NUR reine, in Node
testbare Positions-/Zeitfenster-Mathematik (`berechnePosition`,
`ermittleFenster`, `stundenraster` — Tests in
`server/test/tagesraster.test.js`); das eigentliche DOM-Rendering steht
direkt in `raumplan.html`/`musikerplan.html` (bewusst dupliziert, siehe
PROGRESS.md "Offene Fragen" zur bestehenden Duplizierung kurzer
Bau-Logik zwischen den beiden Ansichten). Die bestehenden
Gruppen/Items-Bau-Funktionen (`baueGroupsUndItems` in raumplan.html,
`baueMusikerGroupsUndItems` in musiker-logik.js) blieben unverändert —
sie liefern weiterhin `{id, content}`-Gruppen und
`{group, content, start, end, style}`-Items, nur die Rendering-Schicht
wurde ausgetauscht. Sichtfenster ist mindestens 07:00–23:00 Uhr, wird
aber automatisch erweitert, falls ein Termin ausserhalb liegt (siehe
`ermittleFenster`), damit nichts abgeschnitten wird. `PX_PRO_MINUTE`
(aktuell 1.2) und `MINDESTHOEHE_PX` (16px, gegen unlesbar schmale
Kurz-Termine) sind in jeder der beiden HTML-Dateien oben als Konstante
gesetzt.

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
  **Seit 07.09.2026 nicht mehr relevant**: vis-timeline wurde durch die
  eigene vertikale Tagesansicht ersetzt (Abschnitt 6) — dort baut jeder
  Aufruf das DOM komplett neu auf (`innerHTML = ''` + neu befüllen), das
  ist bei der Datenmenge (ein Tag) unproblematisch und einfacher als
  inkrementelles Update. Beim Ersetzen selbst blieb in
  `musikerplan.html` ein `if (timeline) ...`-Wächter um den
  Kürzel-Filter-Eingabefeld-Listener stehen, der die (nicht mehr
  deklarierte) Variable `timeline` referenzierte — dadurch blieb das
  Live-Filtern beim Tippen STILL kaputt (kein Fehler, einfach nichts
  passierte), bis es beim nächsten Feature-Umbau (Saison-Verwaltung,
  07.09.2026) zufällig auffiel. Lehre: bei einem Bibliotheks-Ausbau
  gezielt nach Referenzen auf die alten, jetzt entfernten Variablen
  suchen (grep), nicht nur den offensichtlichen Hauptcode ersetzen.
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

**admin.html: Login-Sperre beim Laden (Rafi-Feedback, 07.09.2026)**: nur
in `admin.html` (nicht in `raumplan.html`/`musikerplan.html`, die bleiben
bewusst frei zugänglich zum Ansehen) wird das Passwort SOFORT beim Laden
der Seite abgefragt UND geprüft, nicht erst beim ersten Speichern-Klick.
Neuer, nebenwirkungsfreier Prüf-Endpunkt `GET /api/auth/pruefen` (nutzt
dieselbe `pruefeOrganisatorAuth`-Middleware, gibt bei Erfolg nur
`{status:'ok'}` zurück, sonst 401 wie gehabt). Solange keine gültige
Anmeldung vorliegt, bleibt `#hauptinhalt` per `hidden`-Attribut komplett
versteckt und nur `#loginSperre` (Meldungstext + "Passwort eingeben"-
Button) sichtbar — verhindert, dass jemand ohne Passwort die
Terminverwaltung überhaupt sieht oder öffnet, bevor er/sie zum Speichern
kommt. Bei falschem Passwort bleibt die Sperre mit Fehlermeldung stehen,
erneuter Klick auf den Button fragt neu. Die bestehende
Schreib-Middleware/-route bleibt unverändert — dieser Endpunkt ist rein
zusätzlich für die Früh-Prüfung im Frontend.

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
(Abschnitt 14, inkl. Login-Sperre beim Laden seit 07.09.2026). War
end-to-end verifiziert (echtes Postgres + Playwright: Anlegen/Bearbeiten/
Löschen, falsches Passwort, Konflikte, Kzt-Feldsperre) — dabei 2 Bugs
gefunden+behoben (Abschnitt 13: Date-Objekt-Bug,
Status-Meldung-überschreibt-sich-Bug). Nav-Links zwischen `raumplan.html`,
`musikerplan.html`, `admin.html` ergänzt.

**Zeit-Felder (`fAnfang`/`fEnde`)**: `normalisiereZeit()` akzeptiert
neben "14" → "14:00" und "9:5" → "09:05" seit 07.09.2026 (Rafi-Feedback)
auch rein numerische Kurzeingaben ohne Doppelpunkt: 4-stellig "1230" →
"12:30", 3-stellig "930" → "09:30". Reihenfolge der Regex-Prüfungen ist
wichtig (erst 1-2-stellig, dann mit Doppelpunkt, dann 4-/3-stellig ohne
Doppelpunkt) — siehe Kommentar direkt bei der Funktion in admin.html.

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

### Deploy-Fallstrick (07.09.2026): mehrere Dateien in einem scp-Befehl

Rafi meldete, dass das Werk-Autocomplete nach Befolgen der Deploy-
Anleitung nicht sichtbar war. Vermutliche Ursache: eine frühere
Anleitung bündelte `server/index.js`, `server/queries.js` UND
`server/public/admin.html` in einem einzigen
`scp datei1 datei2 datei3 ziel/`-Befehl. Ein flacher scp-Mehrfach-
Befehl erhält die Unterordnerstruktur NICHT — `admin.html` landet dabei
direkt in `server/` statt in `server/public/`, das alte `admin.html`
bleibt unverändert liegen (Docker-Build kopiert weiterhin die alte
Version), während index.js/queries.js korrekt aktualisiert werden.

**Regel ab jetzt: JEDE Datei einzeln kopieren, mit explizitem
Zielpfad inkl. Dateiname**, nie mehrere Quelldateien in einem scp-
Aufruf gegen ein Zielverzeichnis. Ausserdem nach jedem Deploy per
`grep` auf dem VPS verifizieren, dass die neue Datei wirklich
angekommen ist, bevor `docker compose up -d --build app` läuft (siehe
Beispiel-Befehlsfolge unten in PROGRESS.md "Offene Fragen").

## 17. Saison-Verwaltung (Rafi-Feedback, 07.09.2026)

Rafis Anfrage: "Es muss dann eine Verwaltung geben für eine neue
Saison. Daten, Musiker, Konzerte, Werke pro Konzert etc. Die
vergangenen Saisons sollen als Archiv bleiben. Man sollte also jeweils
das Jahr in einem Dropdown wählen können." Zuerst (06.09.2026) bewusst
auf nach dem Festival vertagt, dann auf Rafis explizite Bestätigung
("ja mache es") umgesetzt.

### Datenmodell (`db/migration-saisons.sql`)

Neue Tabelle `saisons` (id, jahr UNIQUE, bezeichnung, aktiv,
erstellt_am). `raeume`, `musiker`, `termine`, `konfiguration`,
`konzerte`, `werke`, `werk_vorlagen` bekommen je eine Pflicht-Spalte
`saison_id`. Bisher globale Eindeutigkeit gilt jetzt nur noch PRO
Saison (z.B. `UNIQUE (kuerzel, saison_id)` statt `UNIQUE (kuerzel)`
bei `musiker`) — derselbe Raumname/Musiker-Kürzel/Werk-Nummer darf in
verschiedenen Saisons unabhängig wieder vorkommen. `konfiguration`
(bisher PK nur `schluessel`, z.B. "locked_at" für "Stand sperren")
hat jetzt PK `(saison_id, schluessel)` — jede Saison sperrt
unabhängig.

**Modell "genau eine aktive Saison"**: Ein partieller Unique-Index
(`saisons_nur_eine_aktiv_idx ON saisons (aktiv) WHERE aktiv`) erzwingt
auf DB-Ebene, dass höchstens eine Saison gleichzeitig `aktiv=true`
ist. Bewusst KEIN separates "archiviert"-Flag — alles, was nicht die
eine aktive Saison ist, gilt automatisch als Archiv (nur lesbar).
Eine neue Saison anlegen macht sie NICHT automatisch aktiv (sonst
würde das Vorbereiten einer künftigen Saison die gerade laufende
versehentlich einfrieren) — Umschalten ist ein bewusster zweiter
Schritt (`POST /api/saisons/:jahr/aktivieren`).

**Wichtiger Fallstrick, per echtem Postgres-Test gefunden** (siehe
Abschnitt 13): eine Saison zu aktivieren wurde zuerst als EINE einzige
Anweisung geschrieben (`UPDATE saisons SET aktiv = (id = $1)`). Das
verletzt den partiellen Unique-Index — Postgres prüft Eindeutigkeit
pro Zeile SOFORT beim Schreiben, nicht erst am Ende der Anweisung; je
nach physischer Scan-Reihenfolge kann die neu zu aktivierende Zeile
VOR der noch alten aktiven Zeile verarbeitet werden, wodurch
kurzzeitig zwei Zeilen `aktiv=true` wären. Fix: ZWEI Anweisungen in
derselben Transaktion (erst alle deaktivieren, dann genau eine
aktivieren) — siehe `queries.js` `DEAKTIVIERE_ALLE_SAISONS_SQL` +
`AKTIVIERE_SAISON_SQL`.

**ALTER-basiert, nicht CREATE TABLE**, da die Migration auf der bereits
produktiv befüllten 2026er-Datenbank laufen musste — bestehende Zeilen
werden per Backfill automatisch der Saison 2026 zugeordnet, nichts
wird gelöscht. Idempotent (`ADD COLUMN IF NOT EXISTS`,
`DROP CONSTRAINT IF EXISTS` vor `ADD CONSTRAINT`), lokal sowohl gegen
eine frische als auch gegen eine bereits befüllte Test-Datenbank
verifiziert. `db/seed-raeume.sql`/`db/seed-werke-2026.sql` wurden
nachträglich ebenfalls auf Saison 2026 skaliert (Unterabfrage
`(SELECT id FROM saisons WHERE jahr = 2026)` in jeder betroffenen
INSERT-Zeile), damit ein künftiger Fresh-Install
(`schema.sql` → `migration-werke.sql` → `migration-saisons.sql` →
Seeds) weiterhin funktioniert.

### API

Jede season-abhängige Route akzeptiert optional `?saison=<Jahr>` —
ohne Angabe wird die aktive Saison verwendet (`resolveSaison()` in
`index.js`), damit bestehende Aufrufe ohne den neuen Parameter
weiterlaufen. Betroffen: `GET /api/termine`, `GET /api/raeume`,
`GET /api/werke/vorschlaege`, `GET/POST /api/stand*`,
`GET /api/pdf/*`. Neu: `GET /api/saisons` (Liste, offen),
`POST /api/saisons` (anlegen, geschützt), `POST /api/saisons/:jahr/
aktivieren` (umschalten, geschützt).

Schreib-Routen (`POST/PUT/DELETE /api/termine*`,
`POST /api/stand/sperren`) prüfen zusätzlich, ob die betroffene Saison
aktiv ist — sonst 403 ("... ist nicht aktiv und kann deshalb nicht
bearbeitet werden"). Bei `POST` wird die Saison aus `?saison=`
aufgelöst (Default: aktive Saison); bei `PUT`/`DELETE` wird sie DIREKT
vom bestehenden Termin abgelesen (`SELECT_TERMIN_SAISON_SQL`), nicht
aus dem Query-Parameter — ein Termin wechselt nie die Saison, und ein
falscher/fehlender `?saison=`-Parameter beim Bearbeiten soll nicht
versehentlich den falschen Zustand prüfen. `pruefeKonflikte()` prüft
zusätzlich, dass die gewählte `raumId` zur selben Saison gehört wie
der Termin (sonst gilt der Raum als "unbekannt", genau wie ein
nicht-existierender).

### Frontend

`admin.html`, `raumplan.html`, `musikerplan.html` haben je ein
Jahres-Dropdown (`#saisonAuswahl`, befüllt aus `GET /api/saisons`) —
seit Rafi-Feedback vom selben Tag ("den Saison-Wähler oben neben den
Titel machen") in einer eigenen `.kopfzeile` direkt neben dem `<h1>`,
nicht mehr in der Toolbar. In `admin.html` ist der Wähler bewusst
AUSSERHALB von `#hauptinhalt` platziert und wird schon vor dem Login
geladen/verdrahtet (Lesen ist ja ohnehin offen) — nur die
"Saison-Verwaltung…" selbst (Schreib-Aktionen) bleibt hinter dem
Login. Default-Auswahl: `?saison=`-URL-Parameter falls gültig, sonst
die aktive Saison, sonst die erste in der Liste. Bei einer
nicht-aktiven Saison: gelbes Banner "Diese Saison ist nicht aktiv
(Archiv oder noch nicht gestartet) — nur lesbar" UND die
Schreib-Bedienelemente werden ausgeblendet (`admin.html`:
"+ Neuer Termin" sowie Bearbeiten/Löschen-Buttons pro Zeile;
`raumplan.html`: "Stand sperren"). Das ist reiner Komfort/Anzeige —
der Server erzwingt dieselbe Regel nochmal (siehe oben), ein direkter
API-Aufruf ohne UI bekommt trotzdem 403.

`admin.html` hat einen "Saison-Verwaltung…"-Bereich (auf-/zuklappbar):
neue Saison anlegen (Jahr + Bezeichnung, startet LEER und inaktiv),
die im Dropdown gewählte Saison aktivieren (schaltet alle anderen
automatisch auf inaktiv/nur lesbar) — UND (Rafi-Feedback, selber Tag:
"Dann die Raumliste, Musikerliste, Konzertliste, Werkeliste steuern",
"und dort keine Termine anzeigen") vier Tabs mit CRUD-Listen für
Räume/Musiker:innen/Konzerte/Werke DER GEWÄHLTEN SAISON — bewusst
GETRENNT von der normalen Tagesansicht darunter, hier stehen nur
Stammdaten, keine Termine. Jede Zeile ist direkt inline editierbar
(Eingabefelder + "Speichern"/"Löschen"), darunter eine "+"-Zeile zum
Neuanlegen. Werke zeigen zusätzlich ein Konzert-Dropdown und ein
Teilnehmer-Textfeld (Kürzel, kommagetrennt — gleiches Muster wie das
Teilnehmer-Feld bei Terminen, inkl. automatischem Anlegen unbekannter
Kürzel). Alle vier Listen sind bei einer nicht-aktiven Saison ebenfalls
nur lesbar (Speichern/Löschen-Buttons werden dann gar nicht erst
gerendert, siehe `stammdatenAktionsZelle()`).

Löschen ist mit Bedacht gebaut, nicht einfach mit CASCADE durchgereicht:
Räume können nicht gelöscht werden, solange ein Termin darauf verweist
(`termine.raum_id` hat kein `ON DELETE CASCADE`, der natürliche
FK-Fehler 23503 wird in eine verständliche 409 übersetzt). Musiker:innen
und Konzerte hingegen HÄNGEN an Tabellen mit `ON DELETE CASCADE`
(`termin_musiker`/`werk_musiker`/`werk_vorlage_musiker` bzw. `werke`) —
ein Löschen dort würde SONST unbemerkt Teilnahme-Einträge bzw. ganze
Werklisten mitreissen. Deshalb dort ein bewusster Vorab-Zähl-Check
(`ZAEHLE_MUSIKER_VERWENDUNG_SQL`/`ZAEHLE_WERKE_IM_KONZERT_SQL`) VOR dem
DELETE, mit klarer 409-Fehlermeldung statt stillem Datenverlust. Werke
selbst haben keine solche Falle (Termine referenzieren Werke nur als
freien Text, kein Fremdschlüssel) — Löschen ist dort immer gefahrlos.

Für die Mehrfachauswahl-Liste in `musikerplan.html` (Rafi-Feedback:
"Könnte das Musiker-Kürzel Feld eine Liste haben mit Mehrfachauswahl,
Kürzel und Vollnamen", "Wenn ich Musiker neu wähle, sollte es neu
laden") wurde das bisherige freie Text-Eingabefeld durch
`<select id="kuerzel" multiple>` ersetzt, befüllt aus `GET
/api/musiker` (Format je Option: "Kürzel — Vollname", ohne Vollname
nur "Kürzel"). `change`-Event (nicht mehr `input`) löst das Neuladen
aus. Bewusst KEIN `.toUpperCase()` mehr auf die Auswahl (anders als
vorher) — die Options-Werte kommen exakt so aus der Datenbank, manche
Kürzel im Bestand sind bewusst gemischt geschrieben (z.B. "MEh").

### Verifikation

Vollständig end-to-end getestet: 18 neue automatisierte Tests
(`server/test/index.test.js`, u.a. Saison anlegen bleibt inaktiv,
Aktivieren schaltet alte Saison automatisch auf inaktiv, PUT/DELETE/
POST auf inaktiver Saison → 403, Lesen bleibt möglich, Räume-/
Musiker-/Konzerte-/Werke-CRUD inkl. Teilnehmer, Lösch-Blockade bei
Verwendung), ausserdem manuell per echtem Postgres + Playwright-Browser:
neue Saison 2027 anlegen → leer → aktivieren → 2026 wird automatisch
Archiv-Banner+gesperrte Buttons in `admin.html` UND `raumplan.html`,
alter 2026-Termin bleibt lesbar, direkter API-Schreibversuch auf 2026
liefert 403; ausserdem Raum/Musiker:in/Konzert/Werk (inkl. Teilnehmer)
über die neue Verwaltungsoberfläche angelegt, bearbeitet und wieder
gelöscht, neu angelegtes Werk sofort im bestehenden Werk-Autocomplete
nutzbar bestätigt, Lösch-Blockade bei referenzierter Person per
409-Meldung in der Oberfläche sichtbar bestätigt.
