# ZwT Probeplan — Web-App-Migration

Ersetzt schrittweise das Google-Sheet "ZwT 2026 - Probeplan" durch eine
eigene, auf einem Infomaniak-VPS gehostete Web-Anwendung.

## Wichtige Dateien für jede (auch nächtliche) Arbeitssitzung

- **`PROGRESS.md`** — IMMER zuerst lesen. Zeigt, welche Phase/Aufgabe als
  nächstes dran ist, und was bereits erledigt ist. **Enthält aktuell
  (07.09.2026) einen kritischen Befund oben — zuerst lesen: dritter
  bestätigter Sandbox-Reset, Code erneut nicht vorhanden.**
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
   hat am 05./06.09.2026 vermutlich zu echtem Datenverlust geführt, und
   am 07.09.2026 ist die Sandbox ein DRITTES Mal komplett leer
   aufgewacht (siehe PROGRESS.md Abschnitt "Kritischer Befund
   07.09.2026") — diesmal ohne Rafis Anwesenheit, also ohne
   Rettungs-ZIP verfügbar. Ein ZIP-Versand ist billig, ein verlorener
   Arbeitstag nicht.
5. Vor Sitzungsende: `PROGRESS.md` aktualisieren (was wurde erledigt, was ist
   der nächste sinnvolle Schritt), committen. **`git push` NICHT mehr
   versuchen** — seit 07.09.2026 endgültig geklärt, dass das aus dieser
   Sandbox nicht funktioniert (siehe PROGRESS.md "Git-Push aus der
   Sandbox: ENDGÜLTIG GEKLÄRT"). Stattdessen: Code als ZIP an Rafi
   (Punkt 4), er pusht von seinem eigenen Rechner.
6. Lieber ein Teilstück sauber fertig als zwei Teilstücke halb — die nächste
   Sitzung baut direkt darauf auf.
7. Zu Beginn jeder Sitzung kurz prüfen, ob das Repo-Verzeichnis tatsächlich
   den erwarteten Code enthält (nicht nur die drei Markdown-Dateien) —
   siehe PROGRESS.md "Kritischer Befund". Ein leeres/nur aus Doku
   bestehendes Verzeichnis ist jetzt DREIMAL vorgekommen (04./05./06.09.
   und erneut 07.09.2026). Falls leer/unvollständig UND Rafi erkennbar
   anwesend/reagierend: IMMER zuerst fragen, ob er ein aktuelles ZIP hat,
   bevor aus REFERENCE.md neu gebaut wird. Falls NIEMAND da ist (echte
   unbeaufsichtigte Nacht, wie am 07.09.2026): Befund dokumentieren,
   Push-Benachrichtigung senden, NICHT blind nachbauen, NICHT warten.
8. **Jedes per SendUserFile verschickte ZIP bekommt einen Zeitstempel im
   Dateinamen** (z.B. `zwt-probeplan-app_2026-09-06_0734UTC.zip`), und
   der exakte Dateiname wird IMMER in der Begleitnachricht genannt (auf
   Rafis Wunsch, 06.09.2026 — bei ihm landen Downloads nicht zuverlässig
   im normalen Downloads-Ordner, der Dateiname ist sein einziger
   verlässlicher Anker, um Versionen auseinanderzuhalten).
9. **Neu 07.09.2026**: Die Prompt-Einbettung (README/REFERENCE/PROGRESS
   direkt im Scheduled-Task-Prompt) hat sich als robust erwiesen — diese
   drei Dateien sind jetzt zum dritten Mal erfolgreich aus dem Prompt
   heraus neu angelegt worden. Sie schützt aber NUR die Dokumentation,
   NICHT den eigentlichen Programmcode (`db/`, `migrate/`, `server/`,
   `deploy/`).
10. **Endgültig geklärt, 07.09.2026 (interaktive Folge-Sitzung)**:
    `git push` aus dieser Sandbox funktioniert NICHT und wird nicht
    mehr versucht — auch nicht nach Installation der GitHub-App (siehe
    PROGRESS.md "Git-Push aus der Sandbox: ENDGÜLTIG GEKLÄRT" für
    Details). Es gibt zudem keine offizielle, sichere
    Secrets-Verwaltung für Scheduled Tasks (Anthropic-Feature-Request
    #51854 als "not planned" geschlossen) — ein Zugangs-Token hier
    abzulegen wäre weder dauerhaft (Sandbox-Resets) noch sicher. Der
    EINZIGE Weg, wie Code diese Sandbox dauerhaft verlässt, ist ein
    ZIP an Rafi, das er selbst auf seinem Rechner mit seinen eigenen
    GitHub-Zugangsdaten pusht. In einer echten unbeaufsichtigten Nacht
    ohne frisches Rafi-ZIP gibt es AKTUELL KEINEN Weg, verlorenen Code
    wiederherzustellen — das ist eine bekannte, akzeptierte
    Einschränkung, kein zu lösendes Rätsel mehr.

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
06.09.2026 mitgeteilt). **`git push` aus dieser Sandbox NICHT
versuchen** — seit 07.09.2026 endgültig geklärt, dass das nicht
funktioniert (siehe Punkt 10 oben und PROGRESS.md). `git remote add
origin ...` beim Neuanlegen des Repos weiterhin sinnvoll (schadet
nicht, dokumentiert die Ziel-URL), aber kein `git push` danach.

**Der VPS (`83.228.213.202`) ist von alldem nicht betroffen** — er behält
seinen eigenen, unabhängigen Stand (produktiv bis Phase 7, Stand
05.09.2026) unabhängig davon, was in dieser Cloud-Sandbox passiert. Bei
Zweifel über den tatsächlichen Code-Stand ist der VPS die verlässlichste
Quelle (SSH nur bei Rafi möglich, nicht aus dieser Sandbox erreichbar).
