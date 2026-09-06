# Fortschritt

Migrationsplan (alle 10 Phasen):
https://claude.ai/code/artifact/f8082705-72cd-41e7-b8c7-63f1ff74fe81

Immer zuerst diese Datei lesen, dann REFERENCE.md (Abschnitt 13: Fallstricke).

## ⚠️ KRITISCHER BEFUND (06.09.2026): Code-Verlust bestätigt

Sitzung fand `/home/claude/zwt-probeplan-app` komplett leer vor (kein
`.git`) — bestätigt per Suche über das gesamte Dateisystem, ergebnislos.
Betroffen: der GESAMTE Programmcode (`db/`, `migrate/`, `server/`,
`deploy/`), nicht nur diese 3 Markdown-Dateien. Am kritischsten: der erst
am Vortag (05.09.2026) gebaute Phase-8-Code (`admin.html`,
`raumTagErlaubt()`, `GET /api/raeume`, Tests — REFERENCE.md Abschnitt 15)
war laut vorgefundenem Text noch NICHT als ZIP an Rafi verschickt —
vermutlich echter, nicht wiederherstellbarer Verlust.

NICHT betroffen: Phase 0–7 laufen unverändert produktiv auf dem VPS
(`83.228.213.202`) — nur die Sandbox war leer, der VPS nicht.

Bewusst NICHT versucht, den Code blind aus REFERENCE.md nachzubauen
(kein kleines Teilstück mehr, hohes Risiko stiller Fehler ohne
menschliche Verifikation). Stattdessen: Befund dokumentiert, Rafi per
Push-Benachrichtigung informiert, Prozess gefixt (README.md Punkt 4: ZIP
SOFORT nach jeder Code-Änderung, nicht erst bei Deploy-Bereitschaft).
Diese Datei und REFERENCE.md ausserdem am 06.09.2026 stark gekürzt
(update_trigger-Grössenlimit ~konnte ~50 KB nicht verarbeiten, ~20 KB
ging durch) — Detailnarrative gingen dabei verloren, Kernfakten blieben.

**Für Rafi**: prüfen ob vom 05.09.2026-Abend doch ein ZIP mit admin.html
vorliegt — falls ja, in neuer Sitzung hochladen, kein Neuaufbau nötig.
Falls nein: Phase 8 in Tagsitzung neu bauen (Spez.: REFERENCE.md
Abschnitt 15). Ausserdem: GitHub-Repo-URL einmalig mitteilen, damit sie
dauerhaft in README.md eingebettet werden kann.

**Nächster Schritt**: prüfen ob Rafi reagiert hat. Sonst Neuaufbau
beginnend mit `db/schema.sql` (Abschnitt 10), `migrate/*` (Abschnitt 11),
dann Phase 8 (Abschnitt 15).

## Phasenstatus

- **Phase 0** (Vorbereitung): [x] GitHub-Repo (Push blockiert), [x] VPS
  bestellt/aktiv (`83.228.213.202`, ubuntu, Ubuntu 26.04), [ ] Swiss
  Backup (Rafi), [ ] Domain (Rafi, Caddyfile hat IP-Übergangslösung),
  [x] Zugriffsmodell A entschieden (05.09.2026).
- **Phase 1** (Datenmodell/Migration): war fertig gebaut+getestet
  (`db/schema.sql` Abschnitt 10, `migrate/*` Abschnitt 11). **Code
  verloren** — Neuaufbau aus Spezifikation risikoarm möglich. Offen:
  `raum_puffer`-Befüllung sobald echter Export vorliegt.
- **Phase 2** (Server-Grundgerüst): war abgeschlossen bis auf Backup,
  läuft unverändert auf VPS. **`deploy/*` im Repo verloren**, Inhalt lebt
  auf VPS. Backup-Cronjob wartet auf Swiss Backup.
- **Phase 3** (Terminverwaltung-API): war abgeschlossen, läuft produktiv:
  CRUD `/api/termine`, Konfliktprüfung, Kzt-Regel, Wochentags-
  Raumbeschränkung (nachgerüstet in Phase 8). **Code verloren.**
  Raumpuffer-Matrix weiterhin leer (Default 0 Min).
- **Phase 4** (Raumplan/Musiker-Ansicht): war abgeschlossen, läuft
  produktiv: vis-timeline, `raumplan.html`, `musikerplan.html`,
  `color.js`. **Code verloren.** Bekannte Einschränkung: zeigt nur
  Räume/Musiker mit Termin an dem Tag; `GET /api/musiker` fehlt.
- **Phase 5** (Stand sperren): war abgeschlossen, läuft produktiv:
  `GET/POST /api/stand*`, SQL-basierte Änderungsmarkierung. **Code
  verloren.**
- **Phase 6** (PDF-Export): war abgeschlossen, läuft produktiv:
  Gesamtplan+Musikerplan-PDFs (`pdfkit`). **Code verloren.** QR/Dropbox
  vermutlich unnötig.
- **Phase 7** (Zugriff/Login): war abgeschlossen, läuft produktiv, von
  Rafi bestätigt: Passwortschutz für Schreiben. **Code verloren.**
- **Phase 8** (Parallelbetrieb/Testlauf): [ ] **admin.html fertig gebaut+
  getestet (05.09.2026), aber weder deployed noch als ZIP verschickt —
  DER Verlust dieser Nacht** (siehe Kritischer Befund). Spezifikation:
  REFERENCE.md Abschnitt 15. [ ] Echter Testlauf mit realer Probenwoche
  noch nicht begonnen.
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
- `git push` schlägt mit 403 fehl (bekannter Cowork-Proxy-Bug,
  github.com/anthropics/claude-code/issues/84581) — nicht mehrfach
  debuggen. Bei leerem Verzeichnis zusätzlich kein `git remote`
  konfiguriert, keine Repo-URL im Prompt — nicht raten. Rafi um
  einmalige URL-Mitteilung gebeten (06.09.2026, noch keine Antwort).
- Wichtig: Prompt-Einbettung schützt NUR die 3 Markdown-Dateien vor
  leerer Sandbox, NICHT den Programmcode — der geht ohne zusätzliche
  ZIP-/GitHub-Sicherung nachweislich komplett verloren (Kritischer
  Befund oben).
- update_trigger hat ein Grössenlimit für den `prompt`-Parameter (in
  dieser Nacht empirisch ermittelt: ein ~52-KB-Gesamtprompt und auch
  ein ~46-KB-Prompt wurden abgelehnt/"exceeds maximum allowed tokens").
  Die 3 Dateien müssen daher zusammen deutlich unter ~20 KB bleiben, was
  die Detailtiefe von REFERENCE.md/PROGRESS.md strukturell begrenzt.
  Falls künftig mehr Detail nötig ist: eventuell in mehrere kleinere
  Dateien aufteilen oder prüfen ob der Cap wirklich bei ~20-25 KB liegt
  (bei "48 KB abgelehnt / 41 KB abgelehnt / ~20 KB versucht" noch nicht
  abschliessend bestätigt, nur der letzte Versuch war erfolgreich).

## Letzte Sicherung (ZIP an Nutzer per SendUserFile)
- 03.09.2026, 04.09.2026; danach unregelmässig während Tagsitzungen.
- 06.09.2026 (nächtlich): ZIP verschickt — enthält NUR die 3
  Markdown-Dateien (kein Programmcode mehr vorhanden).
