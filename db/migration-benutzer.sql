-- ZwT Probeplan — Mehrere Benutzer:innen mit eigenem Login (Erweiterung, 07.09.2026)
--
-- Rafi-Feedback: "Es sollte auch eine Username/Passwort Funktion geben
-- für verschiedene User." Ergänzt das bisherige Modell eines einzigen
-- gemeinsamen Organisator:innen-Passworts (server/auth.js, REFERENCE.md
-- Abschnitt 14) um echte Benutzerkonten mit eigenem Benutzernamen +
-- Passwort. Bewusst KEIN Rollen-/Rechte-System — jede:r Benutzer:in hat
-- dieselben Schreibrechte wie bisher "der Organisator" (das war nicht
-- Teil des Feedbacks; falls später Rollen gewünscht sind, hier
-- nachrüsten).
--
-- ORGANISATOR_BENUTZER/ORGANISATOR_PASSWORT (.env) funktionieren
-- WEITERHIN zusätzlich als "Notfallzugang" (z.B. falls die
-- benutzer-Tabelle noch leer ist oder alle Passwörter vergessen wurden)
-- — siehe server/auth.js. Das ist auch der Weg, wie das ERSTE eigene
-- Benutzerkonto angelegt wird: mit dem bisherigen gemeinsamen Passwort
-- einloggen, dann über die neue "Benutzer:innen"-Verwaltung in
-- admin.html eigene Konten anlegen.
--
-- Bewusst OHNE Saison-Bezug: Zugänge gelten saisonübergreifend
-- (dieselbe Person verwaltet typischerweise mehrere Saisons).
--
-- Anwenden NACH db/schema.sql (unabhängig von migration-werke.sql und
-- migration-saisons.sql, keine Abhängigkeit dazwischen):
--   docker compose exec -T db sh -c 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"' < ../db/migration-benutzer.sql

BEGIN;

CREATE TABLE IF NOT EXISTS benutzer (
  id            serial PRIMARY KEY,
  benutzername  text UNIQUE NOT NULL,
  passwort_hash text NOT NULL,
  erstellt_am   timestamptz NOT NULL DEFAULT now()
);

COMMIT;
