# Fachliche Referenz: ZwT 2026 - Probeplan (Google Sheet)

Zusammenfassung der über viele Sitzungen ermittelten fachlichen Logik, damit
eine Sitzung ohne Chat-Historie das System korrekt nachbauen kann. Wo
"unklar/zu verifizieren" steht: sinnvolle Annahme treffen, in PROGRESS.md
"Offene Fragen" vermerken, nicht auf Antwort warten.

**Update 07.09.2026, nachmittags**: Beim Auspacken von Rafis ZIP
(`zwtprobeplanapp_20260906_1600UTC.zip`) stellte sich heraus, dass der
tatsächliche Code deutlich weiter ist als der bis dahin in dieser Datei
dokumentierte Stand ("Phase 8 = Terminverwaltung/admin.html fertig").
Der Code enthält zusätzlich eine vollständige **Saison-Verwaltung**
sowie eine **Konzert-/Werkliste mit Autocomplete** (neue Abschnitte 16
und 17 unten) — beides mit Datenbank-Migrationen, Tests (in die 108
grünen Tests eingeschlossen) und UI in `admin.html`, laut Code-
Kommentaren aus "Rafi-Feedback" vom 06./07.09.2026. **Diese Arbeit ist
in keiner der bisherigen PROGRESS.md/REFERENCE.md-Fassungen dieser
Cloud-Sandbox vermerkt** — sie muss in einer anderen Sitzung (vermutlich
mit Rechner-Anbindung, ausserhalb dieser nächtlichen Cowork-Routine)
entstanden sein. Unklar (siehe PROGRESS.md "Offene Fragen"): ob diese
Erweiterung schon auf dem VPS eingespielt ist, oder der VPS noch auf
dem alten Phase-7-Stand läuft.

Der Dateiname (`..._20260906_1600UTC.zip`, suggeriert 06.09. 16:00 UTC)
passt nicht ganz zum internen Datum in `db/migration-saisons.sql`
("Erweiterung, 07.09.2026") — vermutlich wurde die Datei nach der
Erstellung nicht mehr umbenannt, oder der Dateiname stammt aus einer
älteren Version, die später (am 07.09.) noch einmal ergänzt wurde,
bevor Rafi sie in dieser Sitzung hochgeladen hat. Nicht weiter
aufgeklärt — für die Praxis unerheblich, der Code-Inhalt zählt.

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

- Sheet "confRaeume": Spalte A = Raumliste, Spalte N = erlaubte Tage
  (`"Mo-Mi"`, `"Do-So"`, `"Mo,Mi,Fr"`, leer=alle Tage; Codes Mo-So). War
  durchgesetzt seit Phase 8 (`raeume.erlaubte_tage`, `raumTagErlaubt()` in
  `server/validation.js`).
- Pufferzeiten-Matrix ("roomIntervals"): Minuten Puffer zwischen Terminen
  im selben Raum. Sheet-Quelle nie abschliessend lokalisiert (unklar).

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
(Phase 6, `server/pdf.js`+`pdf-layout.js`), lief/läuft produktiv auf VPS
(Stand 05.09.2026). QR/Dropbox/TinyURL für Web-App vermutlich unnötig
(direkter Link reicht).

## 8. Nicht zu übernehmen

Alte Sheets-Buttons ("Sortieren"/"Überprüfen") — App ist immer live.
PropertiesService-Workarounds für Zeilen — DB hat IDs.

## 9. Infrastruktur (VPS)

Infomaniak VPS Lite, IPv4 `83.228.213.202`, SSH-User `ubuntu`, Ubuntu
26.04 LTS 64-bit. SSH-Key nur bei Rafi, nicht im Repo. VPS behält seinen
Stand unabhängig von der Sandbox — läuft produktiv bis Phase 7 (Stand
05.09.2026), von Sandbox-Datenverlusten NICHT betroffen; bei Zweifel VPS
als Quelle der Wahrheit behandeln.

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

Design bleibt massgeblich (Stand zuletzt verifiziert 06.09.2026):

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

Zuletzt verifiziert 06.09.2026, 13 Tests grün: `migrate/lib.js` (DB-frei,
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

Zuletzt verifiziert 06.09.2026, läuft unverändert auf VPS: Docker-Compose
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
- Eine synchrone Express-Middleware `async` zu machen (z.B. für einen
  neuen DB-Zweig, siehe Abschnitt 18) kann bestehende synchrone Tests
  brechen, OBWOHL der neue Codepfad im konkreten Testfall gar nicht
  wirklich etwas "wartet": jedes `await`, auch auf ein sofort
  aufgelöstes Promise, verschiebt die Fortsetzung auf den nächsten
  Microtask. Ein Test, der die Funktion ohne `await`/Promise-Rückgabe
  aufruft und danach sofort Assertions prüft, sieht dann den ALTEN
  (falschen) Zustand. Fix: den teuren/asynchronen Zweig hinter einem
  synchronen Kurzschluss-`if` verstecken (z.B. `if (pool) { await ... }`),
  damit der schnelle Pfad wirklich synchron bleibt — oder die Tests auf
  `await`/`async` umstellen, falls Asynchronität tatsächlich gewollt ist.
- **Wichtigster Fallstrick, bestätigt mehrfach (04./05./06./07.09.2026)**:
  "im Repo committet" ist NICHT gleich "gesichert", solange `git push`
  nicht funktioniert. Die Cloud-Sandbox kann zwischen Sitzungen komplett
  neu bereitgestellt werden — das ist jetzt DREIMAL bestätigt passiert,
  zuletzt 07.09.2026 in einer unbeaufsichtigten Nacht ohne jede Möglichkeit,
  aus einem Rafi-ZIP wiederherzustellen. Einzige robuste Sicherung:
  erfolgreicher `git push` ODER tatsächlich verschicktes ZIP, das Rafi
  selbst noch besitzt. Deshalb: ZIP SOFORT nach jeder Code-Änderung,
  nicht erst bei Deploy-Bereitschaft. Solange `git push` nicht
  funktioniert, ist eine unbeaufsichtigte Nacht nach einem Sandbox-Reset
  strukturell nicht in der Lage, verlorenen Code wiederherzustellen —
  das ist kein Einzelfall mehr, sondern ein wiederkehrendes Muster, das
  eine Lösung ausserhalb dieser Sitzung braucht (z.B. Repo-Autorisierung
  für den Git-Proxy klären, oder Rafi richtet eine eigene, robustere
  Backup-Quelle ein statt sich auf Sandbox-Persistenz zu verlassen).

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
komplett deaktiviert (503). Lief/läuft produktiv auf VPS, von Rafi
bestätigt (Stand 05.09.2026).

## 15. Terminverwaltung / admin.html (Phase 8)

`server/public/admin.html` — Stand zuletzt verifiziert 06.09.2026, noch
NICHT auf dem VPS ausgerollt.

Tagesansicht mit Terminliste (neu/geändert farblich hervorgehoben, siehe
Abschnitt 5), "+ Neuer Termin"/"Bearbeiten"-Formular (POST/PUT). Raum-
Auswahl über `GET /api/raeume` (neu in Phase 8: liefert ALLE Räume, auch
ohne Termin heute — zeigt erlaubte Wochentage pro Raum). Wochentag aus
Datum automatisch berechnet (`wochentagVonDatum`), nicht manuell wählbar.
Typ=Kzt sperrt Teilnehmer-Feld im Formular. Validierungs-(400)/Konflikt-
(409)-Fehler direkt im Formular angezeigt. Auth wie `raumplan.html`
(Abschnitt 14). War end-to-end verifiziert (echtes Postgres + Playwright:
Anlegen/Bearbeiten/Löschen, falsches Passwort, Konflikte, Kzt-Feldsperre)
— dabei 2 Bugs gefunden+behoben (Abschnitt 13: Date-Objekt-Bug,
Status-Meldung-überschreibt-sich-Bug). Nav-Links zwischen `raumplan.html`,
`musikerplan.html`, `admin.html` ergänzt.

## 16. Konzert-/Werkliste mit Autocomplete (Erweiterung, 06.09.2026)

Rekonstruiert aus Code-Kommentaren in `db/migration-werke.sql` und
`server/index.js` (keine Chat-Historie dazu vorhanden — bei Bedarf Rafi
fragen, ob es dazu noch Details/Entscheidungen gibt, die hier fehlen).

Bildet die im Google-Sheet-Tab "config" gefundene Konzert-/Werkliste ab:
`konzerte` (die 10 nummerierten Konzerte + "Freundeskonzert", Blockcode
000, `nummer` = Blockcode aus Spalte "Aud" bei Typ=`Kzt`, z.B. 100, 200
... 1000), `werke` (einzelne Konzertstücke, `nummer` = Sheet-Code, z.B.
401 = Konzert 4, Werk 1, referenziert `konzerte`), `werk_musiker`
(Standard-Teilnehmer pro Werk — "ist beteiligt" zählt, unabhängig von
"x"/Zahl/Stimmen-Kürzel wie "Va"/"Vl" im Sheet), `werk_vorlagen` (21
wiederkehrende Ablaufpunkte wie Saaleinlass, Dîner, Musikeressen,
Practising AL/PFB/VL — mit fester Standard-Teilnehmerliste über
`werk_vorlage_musiker`).

Zweck: `GET /api/werke/vorschlaege?q=<Text>` liefert Autocomplete-
Vorschläge fürs Werk-Feld in `admin.html` (Suche nach Nummer oder
Name), inkl. automatischem Teilnehmer-Vorschlag beim Auswählen (spart
manuelles Eintippen der Musiker:innen-Kürzel). Migration bewusst OHNE
Saison-Bezug angelegt (galt zum Zeitpunkt der Erweiterung als "die
eine Saison 2026") — durch die spätere Saison-Verwaltung (Abschnitt 17)
per `ALTER TABLE ... ADD COLUMN saison_id` nachgerüstet.

Migrationsdatei: `db/migration-werke.sql`, anzuwenden NACH `db/schema.sql`
(referenziert `musiker`), VOR `db/migration-saisons.sql`.

## 17. Saison-Verwaltung (Erweiterung, 07.09.2026)

Rekonstruiert aus Code-Kommentaren in `db/migration-saisons.sql`,
`server/index.js`, `server/public/admin.html` (keine Chat-Historie dazu
vorhanden). Rafi-Feedback laut Code-Kommentar: "Es muss dann eine
Verwaltung geben für eine neue Saison. Daten, Musiker, Konzerte, Werke
pro Konzert etc. Die vergangenen Saisons sollen als Archiv bleiben. Man
sollte also jeweils das Jahr in einem Dropdown wählen können."

Modell: Tabelle `saisons` (jahr, bezeichnung, aktiv). Genau EINE Saison
ist zu jedem Zeitpunkt aktiv/schreibbar (partieller Unique-Index auf
DB-Ebene erzwingt das, nicht nur Anwendungslogik) — alle anderen sind
automatisch Archiv/nur-lesbar, kein separater "archiviert"-Schalter.
Eine neue Saison anlegen (`POST /api/saisons`) macht sie NICHT
automatisch aktiv — Umschalten ist bewusst ein zweiter Schritt
(`POST /api/saisons/:jahr/aktivieren`), damit das Anlegen einer
zukünftigen Saison nicht versehentlich die laufende einfriert. Neue
Saisons starten leer (keine automatische Kopie der Vorjahres-Stammdaten
laut Code-Kommentar in `admin.html`).

`saison_id` wurde auf `raeume`, `musiker`, `termine`, `konfiguration`,
`konzerte`, `werke`, `werk_vorlagen` ergänzt (ALTER-basiert, idempotent,
Backfill auf Saison 2026, migriert eine bereits produktiv befüllte DB
ohne Datenverlust — siehe Kommentar in der Migrationsdatei). Bisher
global eindeutige Felder (Raumname, Musiker-Kürzel, Werk-/Konzert-
Nummer) gelten jetzt nur noch PRO Saison. `konfiguration` (u.a.
"Stand sperren", Abschnitt 5) hat jetzt Primärschlüssel
`(saison_id, schluessel)` — jede Saison ihren eigenen Sperr-Zeitpunkt.

API: `GET /api/saisons` (Liste, neueste zuerst, offen/kein Auth), `POST
/api/saisons` (anlegen, Organisator:innen-Auth), `POST
/api/saisons/:jahr/aktivieren` (umschalten, Organisator:innen-Auth).
Alle bestehenden Lese-Endpoints akzeptieren `?saison=<Jahr>` (ohne
Parameter = aktuell aktive Saison, `resolveSaison()` in `index.js`) —
so funktioniert alles ohne Änderung weiter, solange nur eine Saison
existiert. Schreibversuche gegen eine nicht-aktive (archivierte) Saison
liefern einen Fehler (`saisonArchiviertFehler()`).

`admin.html` hat dafür ein Jahres-Dropdown oben ("Saison") sowie einen
eigenen "Saison-Verwaltung…"-Bereich (neue Saison anlegen, aktivieren)
und Stammdaten-Tabs (Räume / Musiker:innen / Konzerte / Werke) zur
Verwaltung dieser Listen pro Saison.

Migrationsreihenfolge: `db/schema.sql` → `db/migration-werke.sql` →
`db/migration-saisons.sql` (siehe Kommentare in den Dateien selbst,
dort auch der genaue `docker compose exec`-Befehl).

**GEKLÄRT 07.09.2026 (Rafi bestätigt)**: die Saison-Verwaltung
(Abschnitt 17) läuft bereits auf dem VPS. Werkliste (Abschnitt 16)
vermutlich ebenfalls (nicht separat abgefragt, aber beide gehören
zusammen und migration-saisons.sql setzt migration-werke.sql voraus) —
bei Zweifel vor dem nächsten Rollout kurz `SELECT * FROM werke LIMIT 1;`
auf dem VPS prüfen. Für den Rollout der NEUEN Erweiterungen unten
(Abschnitt 18: Mehrere Benutzer:innen) heisst das: nur
`db/migration-benutzer.sql` ist auf dem VPS neu, Schema/Werkliste/
Saisons sind es nicht mehr.

## 18. Mehrere Benutzer:innen mit eigenem Login (Erweiterung, 07.09.2026)

Rafi-Feedback: "Es sollte auch eine Username/Passwort Funktion geben
für verschiedene User." Ergänzt (nicht ersetzt) das bisherige Modell
eines einzigen gemeinsamen Organisator:innen-Passworts (Abschnitt 14).

Neue Tabelle `benutzer` (`db/migration-benutzer.sql`, unabhängig von den
anderen Migrationen anwendbar, KEIN Saison-Bezug — Konten gelten
saisonübergreifend): `id`, `benutzername` (unique), `passwort_hash`,
`erstellt_am`. Passwort-Hashing mit Node-Bordmitteln
(`crypto.scrypt`, Format `<salt-hex>:<derivedKey-hex>`, siehe
`server/auth.js` `hashePasswort`/`pruefePasswort`) — bewusst KEINE neue
npm-Abhängigkeit (kein bcrypt/argon2).

`ORGANISATOR_BENUTZER`/`ORGANISATOR_PASSWORT` (.env) bleiben als
**Notfallzugang** zusätzlich gültig — funktioniert unabhängig davon, ob
die `benutzer`-Tabelle leer, unerreichbar oder befüllt ist. Das ist auch
der Weg, wie das ERSTE eigene Konto angelegt wird: mit dem bisherigen
gemeinsamen Passwort einloggen, dann in `admin.html` unter dem neuen
Tab "Benutzer:innen" (in der Saison-Verwaltung, neben Räume/Musiker:
innen/Konzerte/Werke) echte Konten anlegen. Bewusst KEIN Rollen-/
Rechte-System — jedes Konto hat dieselben Schreibrechte.

`pruefeOrganisatorAuth` (server/auth.js) ist jetzt `async`: prüft zuerst
synchron den Notfallzugang (kein DB-Zugriff nötig, funktioniert auch
bei nicht erreichbarer Datenbank), erst danach — nur falls eine
Datenbank verfügbar ist — gegen die `benutzer`-Tabelle. Wichtiger
Implementierungs-Fallstrick (siehe Abschnitt 13 unten): der DB-Zweig
darf nur BETRETEN werden, wenn `pool` existiert, sonst verschiebt allein
das `await` einer sofort aufgelösten Promise die Fortsetzung auf den
nächsten Microtask und macht die Middleware für den No-DB-Fall
fälschlich asynchron (Regressionstest: `auth.test.js`, "Await-Timing").

API: `GET/POST/PUT/DELETE /api/benutzer[/:id]`, alle
Organisator:innen-Auth-geschützt (jeder eingeloggte Zugang darf Konten
verwalten). `PUT` ändert nur das Passwort, nicht den Benutzernamen
(dafür löschen + neu anlegen). Passwort muss mind. 6 Zeichen haben.
Antworten geben NIE den Passwort-Hash nach aussen.

Frontend (`admin.html`, `raumplan.html`): der Login-Dialog fragt jetzt
per zwei `window.prompt()`-Aufrufen Benutzername UND Passwort ab (statt
nur Passwort mit fest verdrahtetem Benutzernamen "organisator"); bei
401 werden beide verworfen, damit der nächste Versuch neu fragt. Der
neue "Benutzer:innen"-Tab in `admin.html` zeigt Benutzername +
Anlegedatum, mit "Passwort ändern" (fragt per `window.prompt` ein neues
Passwort ab) und "Löschen" pro Zeile — bewusst OHNE die
"nur bearbeitbar wenn Saison aktiv"-Sperre der anderen Tabs, da Konten
nicht saisongebunden sind.

Getestet: `server/test/auth.test.js` (Hash-Rundreise DB-frei) und
`server/test/index.test.js` ("Benutzer-CRUD", End-to-End gegen echtes
Postgres — anlegen, damit einloggen, falsches Passwort ablehnen,
doppelter Benutzername → 400, Passwort ändern, löschen, Notfallzugang
funktioniert danach weiterhin). Am 07.09.2026 lokal gegen ein frisch
aufgesetztes Postgres 16 verifiziert: alle 136 Tests grün (0 übersprungen)
— erstes Mal, dass die komplette DB-abhängige Test-Suite in dieser
Sandbox tatsächlich ausgeführt statt nur übersprungen wurde.

## 19. Landingpage + Domain (07.09.2026)

Rafi-Feedback: "der Link schedule.zwischentoene.com zeigt jetzt auf
83.228.213.202. Man müsste dort eine Landingpage haben, einerseits für
alle ohne Passwort zur Ansicht, andererseits zum Admin mit PWD."

`server/public/index.html` (neu, wird von `express.static` automatisch
für `GET /` ausgeliefert, keine eigene Route in `index.js` nötig): zwei
Abschnitte — "Ansicht" (Links zu `raumplan.html`/`musikerplan.html`,
kein Login) und "Verwaltung" (Link zu `admin.html`, Login dort). Alle
drei bestehenden Seiten haben jetzt zusätzlich einen "Startseite"-Link
in der Nav-Leiste zurück zu `/`.

`deploy/Caddyfile` auf die echte Domain umgestellt
(`schedule.zwischentoene.com` statt der IP-Übergangsvariante) — Caddy
holt sich damit automatisch ein Let's-Encrypt-Zertifikat, sobald Port
80+443 von aussen erreichbar sind (siehe Abschnitt 9, Firewall). Die
alte `:80`-Variante bleibt auskommentiert im File für Testzwecke.
