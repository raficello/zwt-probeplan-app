-- ZwT Probeplan — relationales Schema (Phase 1)
-- Siehe REFERENCE.md Abschnitt 10 für die Herleitung aus dem Google Sheet.
-- Anwenden mit: psql "$DATABASE_URL" -f db/schema.sql

BEGIN;

CREATE TABLE IF NOT EXISTS raeume (
  id            serial PRIMARY KEY,
  name          text UNIQUE NOT NULL,
  aud_code      text UNIQUE,
  erlaubte_tage text[]
);

CREATE TABLE IF NOT EXISTS musiker (
  id      serial PRIMARY KEY,
  kuerzel text UNIQUE NOT NULL,
  name    text
);

CREATE TABLE IF NOT EXISTS termine (
  id           serial PRIMARY KEY,
  wochentag    text NOT NULL CHECK (wochentag IN ('Mo','Di','Mi','Do','Fr','Sa','So')),
  datum        date NOT NULL,
  anfangszeit  time NOT NULL,
  endzeit      time NOT NULL,
  raum_id      int NOT NULL REFERENCES raeume(id),
  typ          text CHECK (typ IS NULL OR typ IN ('', 'GP', 'Kzt', 'K', 'Klf')),
  werk         text NOT NULL,
  bemerkungen  text,
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS termine_datum_idx ON termine (datum);
CREATE INDEX IF NOT EXISTS termine_raum_idx ON termine (raum_id);

CREATE TABLE IF NOT EXISTS termin_musiker (
  termin_id  int NOT NULL REFERENCES termine(id) ON DELETE CASCADE,
  musiker_id int NOT NULL REFERENCES musiker(id) ON DELETE CASCADE,
  PRIMARY KEY (termin_id, musiker_id)
);

CREATE TABLE IF NOT EXISTS raum_puffer (
  von_raum_id    int NOT NULL REFERENCES raeume(id),
  bis_raum_id    int NOT NULL REFERENCES raeume(id),
  puffer_minuten int NOT NULL,
  PRIMARY KEY (von_raum_id, bis_raum_id)
);

CREATE TABLE IF NOT EXISTS konfiguration (
  schluessel text PRIMARY KEY,
  wert       text
);

COMMIT;
