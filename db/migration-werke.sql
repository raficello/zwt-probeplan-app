-- ZwT Probeplan — Konzert-/Werkliste (Erweiterung, 06.09.2026)
--
-- Bildet die im Google Sheet "ZwT 2026 - Probeplan", Tab "config"
-- gefundene Konzert-/Werkliste ab (siehe REFERENCE.md Abschnitt 16).
-- Ergänzt das bestehende Schema (db/schema.sql) um eine Datenquelle für
-- Werk-Autocomplete + automatischen Teilnehmer-Vorschlag in admin.html
-- (Rafi-Feedback, 06.09.2026).
--
-- Bewusst OHNE Saison-Bezug (siehe PROGRESS.md "Offene Fragen" zur
-- geplanten, aber auf später vertagten Saison-Verwaltung) -- diese
-- Tabellen gelten für die aktuell einzige Saison (2026). Bei Einführung
-- der Saison-Verwaltung müssen sie um saison_id ergänzt werden.
--
-- Anwenden NACH db/schema.sql (referenziert musiker von dort):
--   docker compose exec -T db sh -c 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"' < ../db/migration-werke.sql

BEGIN;

-- Die 10 nummerierten Konzerte plus das "Freundeskonzert" (Blockcode 000).
-- nummer = Blockcode aus dem Sheet (Spalte "Aud" bei Typ='Kzt'), z.B. 100,
-- 200 ... 1000 = Konzert-Nr * 100.
CREATE TABLE IF NOT EXISTS konzerte (
  id             serial PRIMARY KEY,
  nummer         int UNIQUE NOT NULL,
  name           text NOT NULL,
  dauer_minuten  numeric
);

-- Einzelne Konzertstücke. nummer = Sheet-Code, z.B. 401 = Konzert 4,
-- 1. Werk (Rafis Beispiel, jetzt aus dem Sheet bestätigt). Dient als
-- Sucheingabe für "Nummer eingeben" (Autocomplete-Anfrage a).
CREATE TABLE IF NOT EXISTS werke (
  id             serial PRIMARY KEY,
  konzert_id     int NOT NULL REFERENCES konzerte(id) ON DELETE CASCADE,
  nummer         int UNIQUE NOT NULL,
  name           text NOT NULL,
  dauer_minuten  numeric
);

-- Standard-Teilnehmer pro Werk (aus dem Sheet: jede belegte Musiker-Spalte
-- in der Zeile, unabhängig davon ob "x", eine Zahl oder ein Stimmen-Kürzel
-- wie "Va"/"Vl" eingetragen war -- für den Teilnehmer-Vorschlag zählt nur
-- "ist beteiligt", nicht die genaue Stimme/Anzahl).
CREATE TABLE IF NOT EXISTS werk_musiker (
  werk_id    int NOT NULL REFERENCES werke(id) ON DELETE CASCADE,
  musiker_id int NOT NULL REFERENCES musiker(id) ON DELETE CASCADE,
  PRIMARY KEY (werk_id, musiker_id)
);

-- Die 21 wiederkehrenden Ablaufpunkte (Saaleinlass, Dîner, Musikeressen,
-- Practising AL/PFB/VL, ...) mit fester Standard-Teilnehmerliste --
-- REFERENCE.md Abschnitt 16 für die Herleitung/Begründung.
CREATE TABLE IF NOT EXISTS werk_vorlagen (
  id             serial PRIMARY KEY,
  nummer         int UNIQUE NOT NULL,
  name           text NOT NULL,
  typ            text,
  dauer_minuten  numeric
);

CREATE TABLE IF NOT EXISTS werk_vorlage_musiker (
  werk_vorlage_id int NOT NULL REFERENCES werk_vorlagen(id) ON DELETE CASCADE,
  musiker_id      int NOT NULL REFERENCES musiker(id) ON DELETE CASCADE,
  PRIMARY KEY (werk_vorlage_id, musiker_id)
);

COMMIT;
