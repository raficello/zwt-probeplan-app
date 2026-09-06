-- ZwT Probeplan — Saison-Verwaltung (Erweiterung, 07.09.2026)
--
-- Rafi-Feedback: "Es muss dann eine Verwaltung geben für eine neue
-- Saison. Daten, Musiker, Konzerte, Werke pro Konzert etc. Die
-- vergangenen Saisons sollen als Archiv bleiben. Man sollte also
-- jeweils das Jahr in einem Dropdown wählen können." Siehe REFERENCE.md
-- (neuer Abschnitt "Saison-Verwaltung") für die volle Herleitung.
--
-- WICHTIG: läuft auf einer bereits produktiv befüllten Datenbank (die
-- 2026er-Saison läuft live) — deshalb bewusst ALTER-basiert statt
-- CREATE TABLE, idempotent (kann gefahrlos mehrfach angewendet werden:
-- ADD COLUMN IF NOT EXISTS, DROP CONSTRAINT IF EXISTS vor ADD
-- CONSTRAINT). Bestehende Daten werden automatisch der Saison "2026"
-- zugeordnet (Backfill), NICHTS wird gelöscht.
--
-- Anwenden NACH db/schema.sql UND db/migration-werke.sql:
--   docker compose exec -T db sh -c 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"' < ../db/migration-saisons.sql
--
-- Modell: genau EINE Saison ist zu jedem Zeitpunkt "aktiv" (schreibbar,
-- partieller Unique-Index erzwingt das auf DB-Ebene). Alle anderen
-- Saisons sind automatisch "Archiv" (nur lesbar) — es gibt bewusst
-- keinen separaten "archiviert"-Schalter, das wäre redundant. Eine neue
-- Saison anzulegen macht sie NICHT automatisch aktiv (sonst würde das
-- Anlegen einer zukünftigen Saison versehentlich die laufende
-- einfrieren) — Umschalten ist ein bewusster zweiter Schritt
-- (`POST /api/saisons/:jahr/aktivieren`).

BEGIN;

CREATE TABLE IF NOT EXISTS saisons (
  id           serial PRIMARY KEY,
  jahr         int UNIQUE NOT NULL,
  bezeichnung  text NOT NULL,
  aktiv        boolean NOT NULL DEFAULT false,
  erstellt_am  timestamptz NOT NULL DEFAULT now()
);

-- Höchstens eine aktive Saison gleichzeitig (Datenbank-Ebene, nicht nur
-- Anwendungslogik).
CREATE UNIQUE INDEX IF NOT EXISTS saisons_nur_eine_aktiv_idx ON saisons (aktiv) WHERE aktiv;

-- Die laufende Saison 2026 anlegen (falls nicht schon vorhanden) und
-- als aktiv markieren -- Backfill unten ordnet ihr alle bestehenden
-- Daten zu.
INSERT INTO saisons (jahr, bezeichnung, aktiv)
  VALUES (2026, 'ZwT 2026', true)
  ON CONFLICT (jahr) DO NOTHING;

-- saison_id auf allen Saison-abhängigen Tabellen ergänzen (zunächst
-- NULLable, damit ADD COLUMN auf bereits befüllten Tabellen sofort
-- funktioniert), bestehende Zeilen der Saison 2026 zuordnen, dann erst
-- NOT NULL erzwingen.
ALTER TABLE raeume        ADD COLUMN IF NOT EXISTS saison_id int REFERENCES saisons(id);
ALTER TABLE musiker       ADD COLUMN IF NOT EXISTS saison_id int REFERENCES saisons(id);
ALTER TABLE termine       ADD COLUMN IF NOT EXISTS saison_id int REFERENCES saisons(id);
ALTER TABLE konfiguration ADD COLUMN IF NOT EXISTS saison_id int REFERENCES saisons(id);
ALTER TABLE konzerte      ADD COLUMN IF NOT EXISTS saison_id int REFERENCES saisons(id);
ALTER TABLE werke         ADD COLUMN IF NOT EXISTS saison_id int REFERENCES saisons(id);
ALTER TABLE werk_vorlagen ADD COLUMN IF NOT EXISTS saison_id int REFERENCES saisons(id);

UPDATE raeume        SET saison_id = (SELECT id FROM saisons WHERE jahr = 2026) WHERE saison_id IS NULL;
UPDATE musiker        SET saison_id = (SELECT id FROM saisons WHERE jahr = 2026) WHERE saison_id IS NULL;
UPDATE termine        SET saison_id = (SELECT id FROM saisons WHERE jahr = 2026) WHERE saison_id IS NULL;
UPDATE konfiguration   SET saison_id = (SELECT id FROM saisons WHERE jahr = 2026) WHERE saison_id IS NULL;
UPDATE konzerte        SET saison_id = (SELECT id FROM saisons WHERE jahr = 2026) WHERE saison_id IS NULL;
UPDATE werke           SET saison_id = (SELECT id FROM saisons WHERE jahr = 2026) WHERE saison_id IS NULL;
UPDATE werk_vorlagen   SET saison_id = (SELECT id FROM saisons WHERE jahr = 2026) WHERE saison_id IS NULL;

ALTER TABLE raeume        ALTER COLUMN saison_id SET NOT NULL;
ALTER TABLE musiker       ALTER COLUMN saison_id SET NOT NULL;
ALTER TABLE termine       ALTER COLUMN saison_id SET NOT NULL;
ALTER TABLE konfiguration ALTER COLUMN saison_id SET NOT NULL;
ALTER TABLE konzerte      ALTER COLUMN saison_id SET NOT NULL;
ALTER TABLE werke         ALTER COLUMN saison_id SET NOT NULL;
ALTER TABLE werk_vorlagen ALTER COLUMN saison_id SET NOT NULL;

CREATE INDEX IF NOT EXISTS raeume_saison_idx        ON raeume (saison_id);
CREATE INDEX IF NOT EXISTS musiker_saison_idx        ON musiker (saison_id);
CREATE INDEX IF NOT EXISTS termine_saison_idx        ON termine (saison_id);
CREATE INDEX IF NOT EXISTS konzerte_saison_idx        ON konzerte (saison_id);
CREATE INDEX IF NOT EXISTS werke_saison_idx           ON werke (saison_id);
CREATE INDEX IF NOT EXISTS werk_vorlagen_saison_idx   ON werk_vorlagen (saison_id);

-- Bisher globale Eindeutigkeit (name/kürzel/nummer) gilt jetzt nur noch
-- PRO Saison -- derselbe Raumname, dasselbe Musiker-Kürzel oder dieselbe
-- Werk-Nummer darf in verschiedenen Saisons unabhängig wieder vorkommen.
ALTER TABLE raeume  DROP CONSTRAINT IF EXISTS raeume_name_key;
ALTER TABLE raeume  DROP CONSTRAINT IF EXISTS raeume_aud_code_key;
ALTER TABLE raeume  DROP CONSTRAINT IF EXISTS raeume_name_saison_id_key;
ALTER TABLE raeume  ADD CONSTRAINT raeume_name_saison_id_key UNIQUE (name, saison_id);

ALTER TABLE musiker DROP CONSTRAINT IF EXISTS musiker_kuerzel_key;
ALTER TABLE musiker DROP CONSTRAINT IF EXISTS musiker_kuerzel_saison_id_key;
ALTER TABLE musiker ADD CONSTRAINT musiker_kuerzel_saison_id_key UNIQUE (kuerzel, saison_id);

ALTER TABLE konzerte DROP CONSTRAINT IF EXISTS konzerte_nummer_key;
ALTER TABLE konzerte DROP CONSTRAINT IF EXISTS konzerte_nummer_saison_id_key;
ALTER TABLE konzerte ADD CONSTRAINT konzerte_nummer_saison_id_key UNIQUE (nummer, saison_id);

ALTER TABLE werke DROP CONSTRAINT IF EXISTS werke_nummer_key;
ALTER TABLE werke DROP CONSTRAINT IF EXISTS werke_nummer_saison_id_key;
ALTER TABLE werke ADD CONSTRAINT werke_nummer_saison_id_key UNIQUE (nummer, saison_id);

ALTER TABLE werk_vorlagen DROP CONSTRAINT IF EXISTS werk_vorlagen_nummer_key;
ALTER TABLE werk_vorlagen DROP CONSTRAINT IF EXISTS werk_vorlagen_nummer_saison_id_key;
ALTER TABLE werk_vorlagen ADD CONSTRAINT werk_vorlagen_nummer_saison_id_key UNIQUE (nummer, saison_id);

-- konfiguration (bisher PK auf schluessel allein, z.B. "locked_at" für
-- "Stand sperren") muss pro Saison unabhängig sein -- jede Saison hat
-- ihren eigenen Sperr-Zeitpunkt.
ALTER TABLE konfiguration DROP CONSTRAINT IF EXISTS konfiguration_pkey;
ALTER TABLE konfiguration ADD CONSTRAINT konfiguration_pkey PRIMARY KEY (saison_id, schluessel);

COMMIT;
