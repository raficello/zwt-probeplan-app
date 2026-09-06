# ZwT Probeplan — Web-App-Migration

Ersetzt schrittweise das Google-Sheet "ZwT 2026 - Probeplan" durch eine
eigene, auf einem Infomaniak-VPS gehostete Web-Anwendung.

## Wichtige Dateien für jede (auch nächtliche) Arbeitssitzung

- **`PROGRESS.md`** — IMMER zuerst lesen. Zeigt, welche Phase/Aufgabe als
  nächstes dran ist, und was bereits erledigt ist. **Enthält aktuell
  (06.09.2026) einen kritischen Befund oben — zuerst lesen.**
- **`REFERENCE.md`** — die komplette fachliche Spezifikation: wie das
  Master-Sheet aufgebaut ist, welche Geschäftsregeln gelten (Konfliktprüfung,
  Raum-Wochentag-Beschränkung, Änderungsmarkierung, PDF-Export). Das ist das
  Wissen, das sonst nur in der Google-Sheets/Apps-Script-Historie steckt.

## Arbeitsweise für nächtliche/eigenständige Sitzungen

1. `PROGRESS.md` lesen, nächste offene Aufgabe identifizieren.
2. Bei Unklarheiten: sinnvolle Annahme treffen, in `PROGRESS.md` unter
   "Offene Fragen / Annahmen" festhalten — NICHT auf eine Antwort warten,
   niemand ist da, um nachts zu antworten.
3. In kleinen, funktionierenden Schritten committen (nicht alles in einen
   Riesen-Commit packen).
4. **Sobald in irgendeiner Sitzung (nächtlich ODER interaktiv am Tag)
   Code entsteht/ändert, der nicht sofort auf den VPS ausgerollt wird:
   SOFORT ein ZIP des Repos per SendUserFile an Rafi schicken — NICHT
   erst "wenn er bereit ist zu deployen" abwarten.** Diese Verzögerung
   hat am 05./06.09.2026 vermutlich zu echtem Datenverlust geführt
   (kompletter Phase-8-Code verschwand über Nacht, siehe PROGRESS.md
   Abschnitt "Kritischer Befund"). Ein ZIP-Versand ist billig, ein
   verlorener Arbeitstag nicht.
5. Vor Sitzungsende: `PROGRESS.md` aktualisieren (was wurde erledigt, was ist
   der nächste sinnvolle Schritt), committen, pushen (`git push` probieren,
   siehe PROGRESS.md zum aktuellen Status des Push-Bugs).
6. Lieber ein Teilstück sauber fertig als zwei Teilstücke halb — die nächste
   Sitzung baut direkt darauf auf.
7. Zu Beginn jeder Sitzung kurz prüfen, ob das Repo-Verzeichnis tatsächlich
   den erwarteten Code enthält (nicht nur die drei Markdown-Dateien) —
   siehe PROGRESS.md "Kritischer Befund" vom 06.09.2026: ein leeres/nur
   aus Doku bestehendes Verzeichnis ist real vorgekommen und wurde erst
   bemerkt, weil bewusst nachgesehen wurde. Falls leer/unvollständig:
   IMMER zuerst Rafi fragen, ob er ein aktuelles ZIP hat, bevor aus
   REFERENCE.md neu gebaut wird — hat am 06.09.2026 den grössten Teil
   eines vermeintlichen Totalverlusts gerettet.
8. **Jedes per SendUserFile verschickte ZIP bekommt einen Zeitstempel im
   Dateinamen** (z.B. `zwt-probeplan-app_2026-09-06_0734UTC.zip`), und
   der exakte Dateiname wird IMMER in der Begleitnachricht genannt (auf
   Rafis Wunsch, 06.09.2026 — bei ihm landen Downloads nicht zuverlässig
   im normalen Downloads-Ordner, der Dateiname ist sein einziger
   verlässlicher Anker, um Versionen auseinanderzuhalten).

## Stack (Stand Migrationsplan)

- Postgres (auf dem VPS)
- Node.js Backend
- Timeline-Ansicht für Raumplan/Musikerplan: **vis-timeline** (entschieden,
  siehe PROGRESS.md Phase 4)
- Deployment: Infomaniak VPS Lite, Caddy als Reverse-Proxy, unattended-upgrades,
  automatisiertes Backup nach Swiss Backup (Backup-Teil noch offen)

Der vollständige Ablaufplan mit allen 10 Phasen:
https://claude.ai/code/artifact/f8082705-72cd-41e7-b8c7-63f1ff74fe81

## GitHub-Repo

`https://github.com/raficello/zwt-probeplan-app.git` (von Rafi am
06.09.2026 mitgeteilt). Bei leerem Verzeichnis: `git remote add origin
https://github.com/raficello/zwt-probeplan-app.git` setzen und `git push
origin HEAD:main` versuchen (Push war zuvor durch einen Cowork-internen
Proxy-Bug blockiert, siehe PROGRESS.md "Offene Fragen" — Status jede
Nacht neu prüfen, nicht mehrfach pro Sitzung versuchen).
