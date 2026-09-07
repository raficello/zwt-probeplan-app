-- ZwT Probeplan — Terminplan-Import Saison 2026
-- Automatisch erzeugt aus dem Google-Sheet "ZwT 2026 - Probeplan",
-- Tab "Master" (per Google-Drive-Export als .xlsx, dann mit openpyxl
-- gelesen -- der Google-Drive-Connector selbst liefert bei diesem
-- grossen Sheet nur einen abgeschnittenen Teil, siehe REFERENCE.md
-- Abschnitt "Terminplan-Import"). Erzeugt mit
-- migrate/build-termine-sql.js.
--
-- WICHTIG: Re-Import-Semantik -- dieses Skript ERSETZT beim Anwenden
-- ALLE Termine der Saison durch den Stand aus dem Export (DELETE +
-- INSERT). Bewusst so, weil "der laufende Plan" sich vor dem
-- Festival noch ändert -- bei einer neuen Version des Sheets dieses
-- Skript einfach mit einem neuen Export erneut laufen lassen. Räume
-- werden NICHT verändert (siehe db/seed-raeume.sql, muss vorher
-- gelaufen sein); Musiker:innen werden nur ERGÄNZT, nie überschrieben
-- (ON CONFLICT DO NOTHING -- bereits erfasste Vollnamen bleiben
-- erhalten).
--
-- Anwenden auf dem VPS (nach seed-raeume.sql/seed-werke-2026.sql):
--   docker compose exec -T db sh -c 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"' \
--     < ../db/seed-termine-2026.sql

BEGIN;

-- Neue Musiker:innen-Kürzel ergänzen, die im Export auftauchen, aber
-- noch nicht erfasst sind (z.B. Sammel-Kürzel wie "Helpers" ohne
-- Vollnamen). Bestehende Einträge bleiben unangetastet.
INSERT INTO musiker (kuerzel, name, saison_id) VALUES ('AA', NULL, (SELECT id FROM saisons WHERE jahr = 2026)) ON CONFLICT (kuerzel, saison_id) DO NOTHING;
INSERT INTO musiker (kuerzel, name, saison_id) VALUES ('AL', NULL, (SELECT id FROM saisons WHERE jahr = 2026)) ON CONFLICT (kuerzel, saison_id) DO NOTHING;
INSERT INTO musiker (kuerzel, name, saison_id) VALUES ('CF', NULL, (SELECT id FROM saisons WHERE jahr = 2026)) ON CONFLICT (kuerzel, saison_id) DO NOTHING;
INSERT INTO musiker (kuerzel, name, saison_id) VALUES ('DU', NULL, (SELECT id FROM saisons WHERE jahr = 2026)) ON CONFLICT (kuerzel, saison_id) DO NOTHING;
INSERT INTO musiker (kuerzel, name, saison_id) VALUES ('EM', NULL, (SELECT id FROM saisons WHERE jahr = 2026)) ON CONFLICT (kuerzel, saison_id) DO NOTHING;
INSERT INTO musiker (kuerzel, name, saison_id) VALUES ('ER', NULL, (SELECT id FROM saisons WHERE jahr = 2026)) ON CONFLICT (kuerzel, saison_id) DO NOTHING;
INSERT INTO musiker (kuerzel, name, saison_id) VALUES ('Helpers', NULL, (SELECT id FROM saisons WHERE jahr = 2026)) ON CONFLICT (kuerzel, saison_id) DO NOTHING;
INSERT INTO musiker (kuerzel, name, saison_id) VALUES ('JK', NULL, (SELECT id FROM saisons WHERE jahr = 2026)) ON CONFLICT (kuerzel, saison_id) DO NOTHING;
INSERT INTO musiker (kuerzel, name, saison_id) VALUES ('LP', NULL, (SELECT id FROM saisons WHERE jahr = 2026)) ON CONFLICT (kuerzel, saison_id) DO NOTHING;
INSERT INTO musiker (kuerzel, name, saison_id) VALUES ('MEh', NULL, (SELECT id FROM saisons WHERE jahr = 2026)) ON CONFLICT (kuerzel, saison_id) DO NOTHING;
INSERT INTO musiker (kuerzel, name, saison_id) VALUES ('MEW', NULL, (SELECT id FROM saisons WHERE jahr = 2026)) ON CONFLICT (kuerzel, saison_id) DO NOTHING;
INSERT INTO musiker (kuerzel, name, saison_id) VALUES ('PFB', NULL, (SELECT id FROM saisons WHERE jahr = 2026)) ON CONFLICT (kuerzel, saison_id) DO NOTHING;
INSERT INTO musiker (kuerzel, name, saison_id) VALUES ('RR', NULL, (SELECT id FROM saisons WHERE jahr = 2026)) ON CONFLICT (kuerzel, saison_id) DO NOTHING;
INSERT INTO musiker (kuerzel, name, saison_id) VALUES ('SP', NULL, (SELECT id FROM saisons WHERE jahr = 2026)) ON CONFLICT (kuerzel, saison_id) DO NOTHING;
INSERT INTO musiker (kuerzel, name, saison_id) VALUES ('TH', NULL, (SELECT id FROM saisons WHERE jahr = 2026)) ON CONFLICT (kuerzel, saison_id) DO NOTHING;
INSERT INTO musiker (kuerzel, name, saison_id) VALUES ('VL', NULL, (SELECT id FROM saisons WHERE jahr = 2026)) ON CONFLICT (kuerzel, saison_id) DO NOTHING;
INSERT INTO musiker (kuerzel, name, saison_id) VALUES ('YL', NULL, (SELECT id FROM saisons WHERE jahr = 2026)) ON CONFLICT (kuerzel, saison_id) DO NOTHING;

-- Bisherige Termine der Saison 2026 verwerfen (termin_musiker fällt
-- automatisch per ON DELETE CASCADE mit weg) und frisch aus dem Export
-- aufbauen.
DELETE FROM termine WHERE saison_id = (SELECT id FROM saisons WHERE jahr = 2026);

-- Mo 2026-10-12 14:45-15:30 Kurtág Officium breve
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Mo', '2026-10-12', '14:45', '15:30',
    r.id, NULL, 'Kurtág Officium breve', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Pilatesraum' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['MEW','EM','AA','RR']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Mo 2026-10-12 15:30-15:45 Bach/Kurtag "Aus tiefer Not schrei...."
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Mo', '2026-10-12', '15:30', '15:45',
    r.id, NULL, 'Bach/Kurtag "Aus tiefer Not schrei...."', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kirchgemeindehaus' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['PFB','VL']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Mo 2026-10-12 15:30-16:15 Beethoven op. 135
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Mo', '2026-10-12', '15:30', '16:15',
    r.id, NULL, 'Beethoven op. 135', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Pilatesraum' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['MEW','EM','AA','RR']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Mo 2026-10-12 15:45-16:00 Bach "Gottes Zeit"
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Mo', '2026-10-12', '15:45', '16:00',
    r.id, NULL, 'Bach "Gottes Zeit"', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kirchgemeindehaus' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['PFB','VL']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Mo 2026-10-12 16:00-17:00 Kurtag from Jatekok
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Mo', '2026-10-12', '16:00', '17:00',
    r.id, NULL, 'Kurtag from Jatekok', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kirchgemeindehaus' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['PFB','VL']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Mo 2026-10-12 16:30-17:45 Kurtag from SGM
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Mo', '2026-10-12', '16:30', '17:45',
    r.id, NULL, 'Kurtag from SGM', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Pilatesraum' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['AA','YL','ER']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Mo 2026-10-12 17:00-18:00 Practising PFB
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Mo', '2026-10-12', '17:00', '18:00',
    r.id, NULL, 'Practising PFB', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kirchgemeindehaus' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['PFB']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Mo 2026-10-12 17:15-20:00 Practising VL
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Mo', '2026-10-12', '17:15', '20:00',
    r.id, NULL, 'Practising VL', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Sonnwendhof' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['VL']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Mo 2026-10-12 18:00-20:00 Holliger Romancendres
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Mo', '2026-10-12', '18:00', '20:00',
    r.id, NULL, 'Holliger Romancendres', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kirchgemeindehaus' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['RR','PFB']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Mo 2026-10-12 18:00-20:00 Mozart StrQuintet D-Dur
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Mo', '2026-10-12', '18:00', '20:00',
    r.id, NULL, 'Mozart StrQuintet D-Dur', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Pilatesraum' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['MEW','AA','DU','YL','ER']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Di 2026-10-13 10:00-11:45 Clara Schumann Klaviertrio
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Di', '2026-10-13', '10:00', '11:45',
    r.id, NULL, 'Clara Schumann Klaviertrio', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kirchgemeindehaus' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['VL','DU','ER']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Di 2026-10-13 10:00-11:30 Brahms Sextett G-Dur
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Di', '2026-10-13', '10:00', '11:30',
    r.id, NULL, 'Brahms Sextett G-Dur', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Pilatesraum' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['MEW','EM','AA','RR','YL','JK']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Di 2026-10-13 10:00-12:00 Practising PFB
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Di', '2026-10-13', '10:00', '12:00',
    r.id, NULL, 'Practising PFB', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Sonnwendhof' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['PFB']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Di 2026-10-13 10:00-11:45 Practising AL
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Di', '2026-10-13', '10:00', '11:45',
    r.id, NULL, 'Practising AL', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Musiksaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['AL']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Di 2026-10-13 11:30-11:45 Zugabe Schubert Ungarische Melodie
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Di', '2026-10-13', '11:30', '11:45',
    r.id, NULL, 'Zugabe Schubert Ungarische Melodie', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Pilatesraum' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['MEW','EM','AA','RR','YL','JK']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Di 2026-10-13 12:00-12:20 Bach "Gottes Zeit"
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Di', '2026-10-13', '12:00', '12:20',
    r.id, NULL, 'Bach "Gottes Zeit"', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Sonnwendhof' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['PFB','VL']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Di 2026-10-13 12:00-12:30 Kurtag from SGM Va/VC
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Di', '2026-10-13', '12:00', '12:30',
    r.id, NULL, 'Kurtag from SGM Va/VC', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Alpenclub' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['AA','ER']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Di 2026-10-13 12:15-13:00 Haydn Klaviertrio G-Dur Nr. 39
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Di', '2026-10-13', '12:15', '13:00',
    r.id, NULL, 'Haydn Klaviertrio G-Dur Nr. 39', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kirchgemeindehaus' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['AL','DU','JK']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Di 2026-10-13 12:20-12:45 Bach/Kurtag "Aus tiefer Not schrei...."
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Di', '2026-10-13', '12:20', '12:45',
    r.id, NULL, 'Bach/Kurtag "Aus tiefer Not schrei...."', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Sonnwendhof' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['PFB','VL']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Di 2026-10-13 12:30-13:30 Kodaly Duo
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Di', '2026-10-13', '12:30', '13:30',
    r.id, NULL, 'Kodaly Duo', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Alpenclub' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['RR','YL']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Di 2026-10-13 13:45-14:45 Beethoven op. 135
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Di', '2026-10-13', '13:45', '14:45',
    r.id, NULL, 'Beethoven op. 135', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Pilatesraum' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['MEW','EM','AA','RR']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Di 2026-10-13 14:00-16:00 Mozart Kegelstatt
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Di', '2026-10-13', '14:00', '16:00',
    r.id, NULL, 'Mozart Kegelstatt', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Sonnwendhof' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['PFB','YL','CF']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Di 2026-10-13 14:00-15:00 Coaching
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Di', '2026-10-13', '14:00', '15:00',
    r.id, NULL, 'Coaching', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kirchgemeindehaus' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['AL','VL']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Di 2026-10-13 14:45-15:45 Hefti «The Broken Column»
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Di', '2026-10-13', '14:45', '15:45',
    r.id, NULL, 'Hefti «The Broken Column»', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Pilatesraum' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['MEW','EM','AA','RR']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Di 2026-10-13 15:15-16:00 Schumann Adagio aus VlKonz
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Di', '2026-10-13', '15:15', '16:00',
    r.id, NULL, 'Schumann Adagio aus VlKonz', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kirchgemeindehaus' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['VL','DU','ER']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Di 2026-10-13 16:15-18:15 Schumann Piano Quartet
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Di', '2026-10-13', '16:15', '18:15',
    r.id, NULL, 'Schumann Piano Quartet', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kirchgemeindehaus' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['AL','DU','YL','JK']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Di 2026-10-13 16:30-18:00 Schumann 3 Romanzen op. 94
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Di', '2026-10-13', '16:30', '18:00',
    r.id, NULL, 'Schumann 3 Romanzen op. 94', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Sonnwendhof' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['VL','CF']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Di 2026-10-13 16:30-18:15 Practising PFB
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Di', '2026-10-13', '16:30', '18:15',
    r.id, NULL, 'Practising PFB', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Musiksaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['PFB']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Di 2026-10-13 17:00-18:00 Ligeti Solosonate
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Di', '2026-10-13', '17:00', '18:00',
    r.id, NULL, 'Ligeti Solosonate', 'Coaching', s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Pilatesraum' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['ER','RR']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Di 2026-10-13 18:30-20:15 Schumann F-Dur Klaviertrio op. 80
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Di', '2026-10-13', '18:30', '20:15',
    r.id, NULL, 'Schumann F-Dur Klaviertrio op. 80', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kirchgemeindehaus' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['RR','AL','DU']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Di 2026-10-13 18:30-20:15 Practising VL
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Di', '2026-10-13', '18:30', '20:15',
    r.id, NULL, 'Practising VL', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Musiksaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['VL']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Di 2026-10-13 18:45-20:15 Kurtág Hommage à R. Sch.
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Di', '2026-10-13', '18:45', '20:15',
    r.id, NULL, 'Kurtág Hommage à R. Sch.', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Sonnwendhof' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['AA','PFB','CF']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Mi 2026-10-14 10:00-11:15 Brahms Sextett G-Dur
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Mi', '2026-10-14', '10:00', '11:15',
    r.id, NULL, 'Brahms Sextett G-Dur', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Pilatesraum' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['MEW','EM','AA','RR','YL','JK']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Mi 2026-10-14 10:00-12:15 Clara Schumann Klaviertrio
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Mi', '2026-10-14', '10:00', '12:15',
    r.id, NULL, 'Clara Schumann Klaviertrio', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Sonnwendhof' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['VL','DU','ER']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Mi 2026-10-14 10:00-12:00 Practising PFB
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Mi', '2026-10-14', '10:00', '12:00',
    r.id, NULL, 'Practising PFB', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kirchgemeindehaus' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['PFB']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Mi 2026-10-14 10:00-14:30 Practising AL
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Mi', '2026-10-14', '10:00', '14:30',
    r.id, NULL, 'Practising AL', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Musiksaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['AL']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Mi 2026-10-14 11:15-11:30 Zugabe Schubert Ungarische Melodie
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Mi', '2026-10-14', '11:15', '11:30',
    r.id, NULL, 'Zugabe Schubert Ungarische Melodie', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Pilatesraum' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['MEW','EM','AA','RR','YL','JK']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Mi 2026-10-14 11:45-12:45 Hefti «The Broken Column»
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Mi', '2026-10-14', '11:45', '12:45',
    r.id, NULL, 'Hefti «The Broken Column»', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Pilatesraum' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['MEW','EM','AA','RR']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Mi 2026-10-14 12:00-13:15 Mozart Kegelstatt
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Mi', '2026-10-14', '12:00', '13:15',
    r.id, NULL, 'Mozart Kegelstatt', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kirchgemeindehaus' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['PFB','YL','CF']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Mi 2026-10-14 12:30-13:00 Schumann Adagio aus VlKonz
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Mi', '2026-10-14', '12:30', '13:00',
    r.id, NULL, 'Schumann Adagio aus VlKonz', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Sonnwendhof' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['VL','DU','ER']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Mi 2026-10-14 13:30-14:30 Veress Introduzione e Coda
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Mi', '2026-10-14', '13:30', '14:30',
    r.id, NULL, 'Veress Introduzione e Coda', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kirchgemeindehaus' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['EM','JK','CF']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Mi 2026-10-14 14:00-14:45 Kurtag from Jatekok
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Mi', '2026-10-14', '14:00', '14:45',
    r.id, NULL, 'Kurtag from Jatekok', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Sonnwendhof' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['PFB','VL']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Mi 2026-10-14 14:00-14:40 Mozart Duo B-Dur
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Mi', '2026-10-14', '14:00', '14:40',
    r.id, NULL, 'Mozart Duo B-Dur', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kloster Barocksaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['DU','YL']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Mi 2026-10-14 14:40-15:40 Mozart StrQuintet D-Dur
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Mi', '2026-10-14', '14:40', '15:40',
    r.id, NULL, 'Mozart StrQuintet D-Dur', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kloster Barocksaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['MEW','AA','DU','YL','ER']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Mi 2026-10-14 15:00-16:00 Webern op.11
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Mi', '2026-10-14', '15:00', '16:00',
    r.id, NULL, 'Webern op.11', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Sonnwendhof' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['PFB','JK']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Mi 2026-10-14 15:00-16:00 Brahms Variationen 4-Händig
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Mi', '2026-10-14', '15:00', '16:00',
    r.id, NULL, 'Brahms Variationen 4-Händig', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kirchgemeindehaus' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['AL','VL']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Mi 2026-10-14 15:40-16:00 Ligeti Solosonate
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Mi', '2026-10-14', '15:40', '16:00',
    r.id, NULL, 'Ligeti Solosonate', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kloster Barocksaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['ER']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Mi 2026-10-14 16:15-17:45 Kurtág Hommage à R. Sch.
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Mi', '2026-10-14', '16:15', '17:45',
    r.id, NULL, 'Kurtág Hommage à R. Sch.', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Sonnwendhof' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['AA','PFB','CF']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Mi 2026-10-14 16:15-17:45 Schumann Piano Quartet
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Mi', '2026-10-14', '16:15', '17:45',
    r.id, NULL, 'Schumann Piano Quartet', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kirchgemeindehaus' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['AL','DU','YL','JK']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Mi 2026-10-14 16:30-19:45 Practising VL
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Mi', '2026-10-14', '16:30', '19:45',
    r.id, NULL, 'Practising VL', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Musiksaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['VL']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Mi 2026-10-14 18:00-19:30 Schumann Märchenerzählungen
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Mi', '2026-10-14', '18:00', '19:30',
    r.id, NULL, 'Schumann Märchenerzählungen', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kirchgemeindehaus' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['AL','YL','CF']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Mi 2026-10-14 18:15-19:45 Schubert T&M
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Mi', '2026-10-14', '18:15', '19:45',
    r.id, NULL, 'Schubert T&M', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Alpenclub' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['MEW','EM','AA','RR']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Mi 2026-10-14 18:15-19:45 Schumann Klaviertrio g-moll
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Mi', '2026-10-14', '18:15', '19:45',
    r.id, NULL, 'Schumann Klaviertrio g-moll', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Sonnwendhof' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['PFB','DU','JK']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Mi 2026-10-14 20:15-22:00 Musikeressen
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Mi', '2026-10-14', '20:15', '22:00',
    r.id, NULL, 'Musikeressen', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Hotel Hahnenblick' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['MEW','EM','AA','RR','AL','PFB','VL','DU','YL','JK','ER','CF']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Do 2026-10-15 07:00-09:30 Anlieferung/Stimmung Flügel
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Do', '2026-10-15', '07:00', '09:30',
    r.id, NULL, 'Anlieferung/Stimmung Flügel', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['MEh']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Do 2026-10-15 09:30-10:30 Practising AL
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Do', '2026-10-15', '09:30', '10:30',
    r.id, NULL, 'Practising AL', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Sonnwendhof' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['AL']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Do 2026-10-15 09:30-10:00 Aufbau Technik, Licht
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Do', '2026-10-15', '09:30', '10:00',
    r.id, NULL, 'Aufbau Technik, Licht', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['TH','LP']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Do 2026-10-15 09:45-11:45 Holliger Romancendres
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Do', '2026-10-15', '09:45', '11:45',
    r.id, NULL, 'Holliger Romancendres', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kirchgemeindehaus' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['RR','PFB']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Do 2026-10-15 10:00-11:00 Practising VL
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Do', '2026-10-15', '10:00', '11:00',
    r.id, NULL, 'Practising VL', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['VL']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Do 2026-10-15 10:00-11:00 Mozart StrQuintet D-Dur
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Do', '2026-10-15', '10:00', '11:00',
    r.id, NULL, 'Mozart StrQuintet D-Dur', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Pilatesraum' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['MEW','AA','DU','YL','ER']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Do 2026-10-15 10:00-11:30 Veress Introduzione e Coda
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Do', '2026-10-15', '10:00', '11:30',
    r.id, NULL, 'Veress Introduzione e Coda', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Alpenclub' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['EM','JK','CF']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Do 2026-10-15 11:00-11:45 Kurtag from SGM
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Do', '2026-10-15', '11:00', '11:45',
    r.id, NULL, 'Kurtag from SGM', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Pilatesraum' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['AA','YL','ER']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Do 2026-10-15 11:00-12:00 Brahms Variationen 4-Händig
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Do', '2026-10-15', '11:00', '12:00',
    r.id, NULL, 'Brahms Variationen 4-Händig', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['AL','VL']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Do 2026-10-15 12:00-14:00 Aufbau Apero
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Do', '2026-10-15', '12:00', '14:00',
    r.id, NULL, 'Aufbau Apero', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kirchgemeindehaus' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
SELECT 1 FROM neuer_termin;

-- Do 2026-10-15 12:00-12:45 Webern op.11
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Do', '2026-10-15', '12:00', '12:45',
    r.id, NULL, 'Webern op.11', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['PFB','JK']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Do 2026-10-15 12:15-13:15 Practising AL
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Do', '2026-10-15', '12:15', '13:15',
    r.id, NULL, 'Practising AL', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Sonnwendhof' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['AL']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Do 2026-10-15 12:15-13:15 Kurtág Officium breve
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Do', '2026-10-15', '12:15', '13:15',
    r.id, NULL, 'Kurtág Officium breve', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Alpenclub' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['MEW','EM','AA','RR']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Do 2026-10-15 12:45-13:30 Practising PFB
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Do', '2026-10-15', '12:45', '13:30',
    r.id, NULL, 'Practising PFB', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['PFB']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Do 2026-10-15 13:00-14:00 Mozart Duo B-Dur
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Do', '2026-10-15', '13:00', '14:00',
    r.id, NULL, 'Mozart Duo B-Dur', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Pilatesraum' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['DU','YL']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Do 2026-10-15 13:15-14:00 Schumann 3 Romanzen op. 94
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Do', '2026-10-15', '13:15', '14:00',
    r.id, NULL, 'Schumann 3 Romanzen op. 94', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Sonnwendhof' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['VL','CF']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Do 2026-10-15 13:30-14:30 Practising AL
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Do', '2026-10-15', '13:30', '14:30',
    r.id, NULL, 'Practising AL', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['AL']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Do 2026-10-15 14:00-15:15 Practising VL
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Do', '2026-10-15', '14:00', '15:15',
    r.id, NULL, 'Practising VL', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Sonnwendhof' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['VL']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Do 2026-10-15 14:15-15:45 Kodaly Duo
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Do', '2026-10-15', '14:15', '15:45',
    r.id, NULL, 'Kodaly Duo', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Pilatesraum' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['RR','YL']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Do 2026-10-15 14:30-16:15 Haydn Klaviertrio G-Dur Nr. 39
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Do', '2026-10-15', '14:30', '16:15',
    r.id, NULL, 'Haydn Klaviertrio G-Dur Nr. 39', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['AL','DU','JK']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Do 2026-10-15 14:45-15:15 Kurtag from SGM Va/VC
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Do', '2026-10-15', '14:45', '15:15',
    r.id, NULL, 'Kurtag from SGM Va/VC', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kirchgemeindehaus' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['AA','ER']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Do 2026-10-15 15:15-15:30 Bach "Gottes Zeit"
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Do', '2026-10-15', '15:15', '15:30',
    r.id, NULL, 'Bach "Gottes Zeit"', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Sonnwendhof' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['PFB','VL']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Do 2026-10-15 15:15-16:00 GP: Ligeti Solo
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Do', '2026-10-15', '15:15', '16:00',
    r.id, 'GP', 'GP: Ligeti Solo', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kirchgemeindehaus' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['ER']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Do 2026-10-15 15:30-15:45 Bach/Kurtag "Aus tiefer Not schrei...."
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Do', '2026-10-15', '15:30', '15:45',
    r.id, NULL, 'Bach/Kurtag "Aus tiefer Not schrei...."', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Sonnwendhof' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['PFB','VL']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Do 2026-10-15 15:45-16:30 Kurtág Hommage à R. Sch.
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Do', '2026-10-15', '15:45', '16:30',
    r.id, NULL, 'Kurtág Hommage à R. Sch.', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Sonnwendhof' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['AA','PFB','CF']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Do 2026-10-15 16:00-17:00 GP: Schumann 3 Fantasiestücke op. 11
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Do', '2026-10-15', '16:00', '17:00',
    r.id, 'GP', 'GP: Schumann 3 Fantasiestücke op. 11', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kirchgemeindehaus' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['VL']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Do 2026-10-15 16:30-18:00 Schumann Märchenerzählungen
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Do', '2026-10-15', '16:30', '18:00',
    r.id, NULL, 'Schumann Märchenerzählungen', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Sonnwendhof' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['AL','YL','CF']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Do 2026-10-15 16:45-18:25 Schumann Klaviertrio g-moll
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Do', '2026-10-15', '16:45', '18:25',
    r.id, NULL, 'Schumann Klaviertrio g-moll', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['PFB','DU','JK']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Do 2026-10-15 17:00-18:15 GP: Beethoven op. 135
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Do', '2026-10-15', '17:00', '18:15',
    r.id, 'GP', 'GP: Beethoven op. 135', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kirchgemeindehaus' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['MEW','EM','AA','RR']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Do 2026-10-15 18:15-19:00 Aufbau Apero
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Do', '2026-10-15', '18:15', '19:00',
    r.id, NULL, 'Aufbau Apero', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kirchgemeindehaus' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
SELECT 1 FROM neuer_termin;

-- Do 2026-10-15 18:35-19:35 GP: Mozart Kegelstatt
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Do', '2026-10-15', '18:35', '19:35',
    r.id, 'GP', 'GP: Mozart Kegelstatt', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['PFB','YL','CF']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Do 2026-10-15 19:00-20:00 0| Freundeskonzert Do 19.00 Kgh
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Do', '2026-10-15', '19:00', '20:00',
    r.id, 'Kzt', '0| Freundeskonzert Do 19.00 Kgh', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kirchgemeindehaus' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
SELECT 1 FROM neuer_termin;

-- Do 2026-10-15 19:01-19:06 Konzert: Freundeskonzert Rede
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Do', '2026-10-15', '19:01', '19:06',
    r.id, 'K', 'Konzert: Freundeskonzert Rede', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kirchgemeindehaus' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
SELECT 1 FROM neuer_termin;

-- Do 2026-10-15 19:06-19:18 Konzert: Schumann 3 Fantasiestücke op. 11
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Do', '2026-10-15', '19:06', '19:18',
    r.id, 'K', 'Konzert: Schumann 3 Fantasiestücke op. 11', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kirchgemeindehaus' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['VL']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Do 2026-10-15 19:20-19:29 Konzert: Ligeti Solosonate
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Do', '2026-10-15', '19:20', '19:29',
    r.id, 'K', 'Konzert: Ligeti Solosonate', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kirchgemeindehaus' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['ER']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Do 2026-10-15 19:30-19:54 Konzert: Beethoven op. 135
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Do', '2026-10-15', '19:30', '19:54',
    r.id, 'K', 'Konzert: Beethoven op. 135', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kirchgemeindehaus' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['MEW','EM','AA','RR']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Do 2026-10-15 19:40-20:40 GP: Schumann Piano Quartet
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Do', '2026-10-15', '19:40', '20:40',
    r.id, 'GP', 'GP: Schumann Piano Quartet', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['AL','DU','YL','JK']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Do 2026-10-15 19:45-20:00 Grosse Trommel in Kursaal
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Do', '2026-10-15', '19:45', '20:00',
    r.id, NULL, 'Grosse Trommel in Kursaal', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Sonnwendhof' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['SP','MEh']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Do 2026-10-15 20:00-22:00 Practising PFB
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Do', '2026-10-15', '20:00', '22:00',
    r.id, NULL, 'Practising PFB', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Sonnwendhof' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['PFB']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Do 2026-10-15 20:05-21:00 Apero Freundeskonzert
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Do', '2026-10-15', '20:05', '21:00',
    r.id, NULL, 'Apero Freundeskonzert', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kirchgemeindehaus' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['MEW','EM','AA','RR','VL','ER']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Do 2026-10-15 20:40-22:00 Practising AL
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Do', '2026-10-15', '20:40', '22:00',
    r.id, NULL, 'Practising AL', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['AL']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Fr 2026-10-16 09:00-09:45 GP: Kurtag from Jatekok
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Fr', '2026-10-16', '09:00', '09:45',
    r.id, 'GP', 'GP: Kurtag from Jatekok', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['PFB','VL']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Fr 2026-10-16 09:30-11:00 Brahms Sextett G-Dur
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Fr', '2026-10-16', '09:30', '11:00',
    r.id, NULL, 'Brahms Sextett G-Dur', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Pilatesraum' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['MEW','EM','AA','RR','YL','JK']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Fr 2026-10-16 10:00-10:50 GP: Schumann Kinderszenen
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Fr', '2026-10-16', '10:00', '10:50',
    r.id, 'GP', 'GP: Schumann Kinderszenen', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['AL']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Fr 2026-10-16 10:45-12:00 Practising PFB
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Fr', '2026-10-16', '10:45', '12:00',
    r.id, NULL, 'Practising PFB', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kirchgemeindehaus' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['PFB']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Fr 2026-10-16 11:00-11:30 GP: Schumann Adagio aus VlKonz
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Fr', '2026-10-16', '11:00', '11:30',
    r.id, 'GP', 'GP: Schumann Adagio aus VlKonz', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['VL','DU','ER']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Fr 2026-10-16 11:00-11:15 Zugabe Schubert Ungarische Melodie
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Fr', '2026-10-16', '11:00', '11:15',
    r.id, NULL, 'Zugabe Schubert Ungarische Melodie', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Pilatesraum' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['MEW','EM','AA','RR','YL','JK']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Fr 2026-10-16 11:10-12:00 Practising AL
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Fr', '2026-10-16', '11:10', '12:00',
    r.id, NULL, 'Practising AL', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Sonnwendhof' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['AL']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Fr 2026-10-16 11:30-12:30 Schubert T&M
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Fr', '2026-10-16', '11:30', '12:30',
    r.id, NULL, 'Schubert T&M', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Pilatesraum' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['MEW','EM','AA','RR']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Fr 2026-10-16 11:40-13:00 GP: Attila Mihó és barátai
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Fr', '2026-10-16', '11:40', '13:00',
    r.id, 'GP', 'GP: Attila Mihó és barátai', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['Helpers']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Fr 2026-10-16 12:00-13:30 Schumann Klaviertrio g-moll
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Fr', '2026-10-16', '12:00', '13:30',
    r.id, NULL, 'Schumann Klaviertrio g-moll', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kirchgemeindehaus' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['PFB','DU','JK']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Fr 2026-10-16 12:00-13:00 Schumann 3 Romanzen op. 94
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Fr', '2026-10-16', '12:00', '13:00',
    r.id, NULL, 'Schumann 3 Romanzen op. 94', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Sonnwendhof' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['VL','CF']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Fr 2026-10-16 13:00-13:45 Flügelstimmung
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Fr', '2026-10-16', '13:00', '13:45',
    r.id, NULL, 'Flügelstimmung', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['MEh']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Fr 2026-10-16 13:30-14:15 Kurtág Officium breve
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Fr', '2026-10-16', '13:30', '14:15',
    r.id, NULL, 'Kurtág Officium breve', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Sonnwendhof' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['MEW','EM','AA','RR']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Fr 2026-10-16 13:30-14:15 Practising VL
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Fr', '2026-10-16', '13:30', '14:15',
    r.id, NULL, 'Practising VL', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kirchgemeindehaus' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['VL']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Fr 2026-10-16 13:45-14:30 GP: Schumann Märchenerzählungen
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Fr', '2026-10-16', '13:45', '14:30',
    r.id, 'GP', 'GP: Schumann Märchenerzählungen', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['AL','YL','CF']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Fr 2026-10-16 14:15-15:15 Hefti «The Broken Column»
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Fr', '2026-10-16', '14:15', '15:15',
    r.id, NULL, 'Hefti «The Broken Column»', 'mit Hefti', s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Sonnwendhof' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['MEW','EM','AA','RR']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Fr 2026-10-16 14:30-15:20 GP: Clara Schumann Klaviertrio
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Fr', '2026-10-16', '14:30', '15:20',
    r.id, 'GP', 'GP: Clara Schumann Klaviertrio', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['VL','DU','ER']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Fr 2026-10-16 14:30-15:00 Webern op.11
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Fr', '2026-10-16', '14:30', '15:00',
    r.id, NULL, 'Webern op.11', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kirchgemeindehaus' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['PFB','JK']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Fr 2026-10-16 15:20-15:45 GP: Schumann Nachtstücke Op 23
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Fr', '2026-10-16', '15:20', '15:45',
    r.id, 'GP', 'GP: Schumann Nachtstücke Op 23', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['PFB']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Fr 2026-10-16 15:20-15:50 Veress Introduzione e Coda
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Fr', '2026-10-16', '15:20', '15:50',
    r.id, NULL, 'Veress Introduzione e Coda', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Sonnwendhof' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['EM','JK','CF']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Fr 2026-10-16 15:30-17:00 Schumann F-Dur Klaviertrio op. 80
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Fr', '2026-10-16', '15:30', '17:00',
    r.id, NULL, 'Schumann F-Dur Klaviertrio op. 80', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kirchgemeindehaus' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['RR','AL','DU']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Fr 2026-10-16 15:45-16:15 GP: Kurtag from SGM
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Fr', '2026-10-16', '15:45', '16:15',
    r.id, 'GP', 'GP: Kurtag from SGM', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['AA','YL','ER']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Fr 2026-10-16 15:50-16:45 Practising VL
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Fr', '2026-10-16', '15:50', '16:45',
    r.id, NULL, 'Practising VL', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Sonnwendhof' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['VL']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Fr 2026-10-16 16:15-17:00 GP: Kurtág Hommage à R. Sch.
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Fr', '2026-10-16', '16:15', '17:00',
    r.id, 'GP', 'GP: Kurtág Hommage à R. Sch.', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['AA','PFB','CF']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Fr 2026-10-16 17:00-17:30 Brahms Variationen 4-Händig
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Fr', '2026-10-16', '17:00', '17:30',
    r.id, NULL, 'Brahms Variationen 4-Händig', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kirchgemeindehaus' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['AL','VL']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Fr 2026-10-16 17:00-17:15 Flügelstimmung
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Fr', '2026-10-16', '17:00', '17:15',
    r.id, NULL, 'Flügelstimmung', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['MEh']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Fr 2026-10-16 17:15-17:30 Saaleinlass
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Fr', '2026-10-16', '17:15', '17:30',
    r.id, NULL, 'Saaleinlass', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
SELECT 1 FROM neuer_termin;

-- Fr 2026-10-16 17:30-18:35 1| Eröffnungskonzert «Zeichen» Fr 17.30
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Fr', '2026-10-16', '17:30', '18:35',
    r.id, 'Kzt', '1| Eröffnungskonzert «Zeichen» Fr 17.30', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
SELECT 1 FROM neuer_termin;

-- Fr 2026-10-16 17:30-18:45 Practising PFB
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Fr', '2026-10-16', '17:30', '18:45',
    r.id, NULL, 'Practising PFB', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kirchgemeindehaus' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['PFB']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Fr 2026-10-16 17:31-17:35 Konzert: Rede
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Fr', '2026-10-16', '17:31', '17:35',
    r.id, 'K', 'Konzert: Rede', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['RR']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Fr 2026-10-16 17:36-18:00 Konzert: Beethoven op. 135
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Fr', '2026-10-16', '17:36', '18:00',
    r.id, 'K', 'Konzert: Beethoven op. 135', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['MEW','EM','AA','RR']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Fr 2026-10-16 18:03-18:30 Konzert: Schumann Piano Quartet
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Fr', '2026-10-16', '18:03', '18:30',
    r.id, 'K', 'Konzert: Schumann Piano Quartet', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['AL','DU','YL','JK']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Fr 2026-10-16 18:45-19:30 Mozart Duo B-Dur
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Fr', '2026-10-16', '18:45', '19:30',
    r.id, NULL, 'Mozart Duo B-Dur', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kirchgemeindehaus' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['DU','YL']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Fr 2026-10-16 19:00-19:15 Flügelstimmung
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Fr', '2026-10-16', '19:00', '19:15',
    r.id, NULL, 'Flügelstimmung', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['MEh']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Fr 2026-10-16 19:15-19:30 Saaleinlass
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Fr', '2026-10-16', '19:15', '19:30',
    r.id, NULL, 'Saaleinlass', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
SELECT 1 FROM neuer_termin;

-- Fr 2026-10-16 19:30-20:35 2| Abendkonzert «Spiele» Fr 19.30
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Fr', '2026-10-16', '19:30', '20:35',
    r.id, 'Kzt', '2| Abendkonzert «Spiele» Fr 19.30', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
SELECT 1 FROM neuer_termin;

-- Fr 2026-10-16 19:31-19:51 Konzert: Kurtag from Jatekok
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Fr', '2026-10-16', '19:31', '19:51',
    r.id, 'K', 'Konzert: Kurtag from Jatekok', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['PFB','VL']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Fr 2026-10-16 19:52-20:12 Konzert: Mozart Kegelstatt
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Fr', '2026-10-16', '19:52', '20:12',
    r.id, 'K', 'Konzert: Mozart Kegelstatt', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['PFB','YL','CF']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Fr 2026-10-16 20:14-20:32 Konzert: Schumann Kinderszenen
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Fr', '2026-10-16', '20:14', '20:32',
    r.id, 'K', 'Konzert: Schumann Kinderszenen', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['AL']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Fr 2026-10-16 20:35-21:15 Umbau Saal
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Fr', '2026-10-16', '20:35', '21:15',
    r.id, NULL, 'Umbau Saal', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
SELECT 1 FROM neuer_termin;

-- Fr 2026-10-16 21:15-21:30 Flügelstimmung
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Fr', '2026-10-16', '21:15', '21:30',
    r.id, NULL, 'Flügelstimmung', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['MEh']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Fr 2026-10-16 21:30-22:00 Attila Mihó és barátai
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Fr', '2026-10-16', '21:30', '22:00',
    r.id, NULL, 'Attila Mihó és barátai', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
SELECT 1 FROM neuer_termin;

-- Fr 2026-10-16 22:00-22:15 Saaleinlass
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Fr', '2026-10-16', '22:00', '22:15',
    r.id, NULL, 'Saaleinlass', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
SELECT 1 FROM neuer_termin;

-- Fr 2026-10-16 22:15-23:20 3| «Late Night» Fr 22.15
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Fr', '2026-10-16', '22:15', '23:20',
    r.id, 'Kzt', '3| «Late Night» Fr 22.15', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
SELECT 1 FROM neuer_termin;

-- Fr 2026-10-16 22:16-23:20 Konzert: Attila Mihó és barátai
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Fr', '2026-10-16', '22:16', '23:20',
    r.id, 'K', 'Konzert: Attila Mihó és barátai', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
SELECT 1 FROM neuer_termin;

-- Fr 2026-10-16 23:20-00:00 Umbau Saal
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Fr', '2026-10-16', '23:20', '00:00',
    r.id, NULL, 'Umbau Saal', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
SELECT 1 FROM neuer_termin;

-- Sa 2026-10-17 09:00-09:30 Flügelstimmung
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Sa', '2026-10-17', '09:00', '09:30',
    r.id, NULL, 'Flügelstimmung', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['MEh']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Sa 2026-10-17 09:05-09:15 GP: Ligeti Solosonate
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Sa', '2026-10-17', '09:05', '09:15',
    r.id, 'GP', 'GP: Ligeti Solosonate', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kloster Barocksaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['ER']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Sa 2026-10-17 09:15-10:00 Holliger Romancendres
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Sa', '2026-10-17', '09:15', '10:00',
    r.id, NULL, 'Holliger Romancendres', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kirchgemeindehaus' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['RR','PFB']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Sa 2026-10-17 09:15-09:35 GP: Mozart Duo B-Dur
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Sa', '2026-10-17', '09:15', '09:35',
    r.id, 'GP', 'GP: Mozart Duo B-Dur', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kloster Barocksaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['DU','YL']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Sa 2026-10-17 09:35-10:25 GP: Mozart StrQuintet D-Dur
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Sa', '2026-10-17', '09:35', '10:25',
    r.id, 'GP', 'GP: Mozart StrQuintet D-Dur', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kloster Barocksaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['MEW','AA','DU','YL','ER']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Sa 2026-10-17 09:50-10:20 GP: Brahms Variationen 4-Händig
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Sa', '2026-10-17', '09:50', '10:20',
    r.id, 'GP', 'GP: Brahms Variationen 4-Händig', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['AL','VL']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Sa 2026-10-17 10:20-10:30 GP: Bach/Kurtag "Aus tiefer Not schrei...."
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Sa', '2026-10-17', '10:20', '10:30',
    r.id, 'GP', 'GP: Bach/Kurtag "Aus tiefer Not schrei...."', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['PFB','VL']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Sa 2026-10-17 10:30-10:40 GP: Bach "Gottes Zeit"
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Sa', '2026-10-17', '10:30', '10:40',
    r.id, 'GP', 'GP: Bach "Gottes Zeit"', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['PFB','VL']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Sa 2026-10-17 10:30-10:45 Saaleinlass
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Sa', '2026-10-17', '10:30', '10:45',
    r.id, NULL, 'Saaleinlass', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kloster Barocksaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
SELECT 1 FROM neuer_termin;

-- Sa 2026-10-17 10:45-11:10 GP: Webern op.11
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Sa', '2026-10-17', '10:45', '11:10',
    r.id, 'GP', 'GP: Webern op.11', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['PFB','JK']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Sa 2026-10-17 10:45-11:50 4| Matinee Kloster «Dialoge» Sa 10.45
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Sa', '2026-10-17', '10:45', '11:50',
    r.id, 'Kzt', '4| Matinee Kloster «Dialoge» Sa 10.45', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kloster Barocksaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
SELECT 1 FROM neuer_termin;

-- Sa 2026-10-17 10:45-12:15 Practising AL
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Sa', '2026-10-17', '10:45', '12:15',
    r.id, NULL, 'Practising AL', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Sonnwendhof' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['AL']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Sa 2026-10-17 10:47-11:07 Konzert: Mozart Duo B-Dur
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Sa', '2026-10-17', '10:47', '11:07',
    r.id, 'K', 'Konzert: Mozart Duo B-Dur', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kloster Barocksaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['DU','YL']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Sa 2026-10-17 11:08-11:17 Konzert: Ligeti Solosonate
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Sa', '2026-10-17', '11:08', '11:17',
    r.id, 'K', 'Konzert: Ligeti Solosonate', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kloster Barocksaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['ER']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Sa 2026-10-17 11:15-11:45 GP: Schumann 3 Romanzen op. 94
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Sa', '2026-10-17', '11:15', '11:45',
    r.id, 'GP', 'GP: Schumann 3 Romanzen op. 94', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['VL','CF']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Sa 2026-10-17 11:20-13:00 Practising PFB
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Sa', '2026-10-17', '11:20', '13:00',
    r.id, NULL, 'Practising PFB', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kirchgemeindehaus' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['PFB']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Sa 2026-10-17 11:20-11:48 Konzert: Mozart StrQuintet D-Dur
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Sa', '2026-10-17', '11:20', '11:48',
    r.id, 'K', 'Konzert: Mozart StrQuintet D-Dur', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kloster Barocksaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['MEW','AA','DU','YL','ER']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Sa 2026-10-17 11:45-12:00 Flügelstimmung
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Sa', '2026-10-17', '11:45', '12:00',
    r.id, NULL, 'Flügelstimmung', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['MEh']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Sa 2026-10-17 12:00-12:45 GP: Veress Introduzione e Coda
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Sa', '2026-10-17', '12:00', '12:45',
    r.id, 'GP', 'GP: Veress Introduzione e Coda', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['EM','JK','CF']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Sa 2026-10-17 12:15-15:00 Practising VL
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Sa', '2026-10-17', '12:15', '15:00',
    r.id, NULL, 'Practising VL', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Sonnwendhof' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['VL']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Sa 2026-10-17 12:45-13:45 Schumann F-Dur Klaviertrio op. 80
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Sa', '2026-10-17', '12:45', '13:45',
    r.id, NULL, 'Schumann F-Dur Klaviertrio op. 80', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['RR','AL','DU']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Sa 2026-10-17 13:50-14:30 GP: Schubert T&M
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Sa', '2026-10-17', '13:50', '14:30',
    r.id, 'GP', 'GP: Schubert T&M', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['MEW','EM','AA','RR']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Sa 2026-10-17 14:00-14:45 Haydn Klaviertrio G-Dur Nr. 39
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Sa', '2026-10-17', '14:00', '14:45',
    r.id, NULL, 'Haydn Klaviertrio G-Dur Nr. 39', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kirchgemeindehaus' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['AL','DU','JK']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Sa 2026-10-17 14:30-15:00 GP: Hefti «The Broken Column»
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Sa', '2026-10-17', '14:30', '15:00',
    r.id, 'GP', 'GP: Hefti «The Broken Column»', 'mit Hefti', s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['MEW','EM','AA','RR']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Sa 2026-10-17 15:00-15:15 Saaleinlass
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Sa', '2026-10-17', '15:00', '15:15',
    r.id, NULL, 'Saaleinlass', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
SELECT 1 FROM neuer_termin;

-- Sa 2026-10-17 15:15-16:30 5| «The Broken Column» Sat 15.15
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Sa', '2026-10-17', '15:15', '16:30',
    r.id, 'Kzt', '5| «The Broken Column» Sat 15.15', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
SELECT 1 FROM neuer_termin;

-- Sa 2026-10-17 15:16-15:19 Konzert: Webern op.11
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Sa', '2026-10-17', '15:16', '15:19',
    r.id, 'K', 'Konzert: Webern op.11', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['PFB','JK']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Sa 2026-10-17 15:21-15:33 Konzert: Kurtag from SGM
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Sa', '2026-10-17', '15:21', '15:33',
    r.id, 'K', 'Konzert: Kurtag from SGM', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['AA','YL','ER']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Sa 2026-10-17 15:35-15:50 Konzert: Hefti «The Broken Column»
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Sa', '2026-10-17', '15:35', '15:50',
    r.id, 'K', 'Konzert: Hefti «The Broken Column»', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['MEW','EM','AA','RR']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Sa 2026-10-17 15:53-16:23 Konzert: Clara Schumann Klaviertrio
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Sa', '2026-10-17', '15:53', '16:23',
    r.id, 'K', 'Konzert: Clara Schumann Klaviertrio', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['VL','DU','ER']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Sa 2026-10-17 16:30-17:00 Flügelstimmung
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Sa', '2026-10-17', '16:30', '17:00',
    r.id, NULL, 'Flügelstimmung', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['MEh']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Sa 2026-10-17 17:00-17:15 Saaleinlass
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Sa', '2026-10-17', '17:00', '17:15',
    r.id, NULL, 'Saaleinlass', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
SELECT 1 FROM neuer_termin;

-- Sa 2026-10-17 17:15-18:22 6|«Hommage à Robert Schumann» Sat 17.15
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Sa', '2026-10-17', '17:15', '18:22',
    r.id, 'Kzt', '6|«Hommage à Robert Schumann» Sat 17.15', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
SELECT 1 FROM neuer_termin;

-- Sa 2026-10-17 17:16-17:32 Konzert: Schumann Nachtstücke Op 23
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Sa', '2026-10-17', '17:16', '17:32',
    r.id, 'K', 'Konzert: Schumann Nachtstücke Op 23', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['PFB']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Sa 2026-10-17 17:34-17:49 Konzert: Schumann Märchenerzählungen
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Sa', '2026-10-17', '17:34', '17:49',
    r.id, 'K', 'Konzert: Schumann Märchenerzählungen', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['AL','YL','CF']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Sa 2026-10-17 17:52-18:02 Konzert: Kurtág Hommage à R. Sch.
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Sa', '2026-10-17', '17:52', '18:02',
    r.id, 'K', 'Konzert: Kurtág Hommage à R. Sch.', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['AA','PFB','CF']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Sa 2026-10-17 18:04-18:20 Konzert: Brahms Variationen 4-Händig
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Sa', '2026-10-17', '18:04', '18:20',
    r.id, 'K', 'Konzert: Brahms Variationen 4-Händig', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['AL','VL']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Sa 2026-10-17 18:30-19:00 Kodaly Duo
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Sa', '2026-10-17', '18:30', '19:00',
    r.id, NULL, 'Kodaly Duo', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kirchgemeindehaus' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['RR','YL']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Sa 2026-10-17 18:30-19:00 GP: Bartok Solosonate Vl
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Sa', '2026-10-17', '18:30', '19:00',
    r.id, 'GP', 'GP: Bartok Solosonate Vl', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['DU']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Sa 2026-10-17 19:00-19:15 Saaleinlass
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Sa', '2026-10-17', '19:00', '19:15',
    r.id, NULL, 'Saaleinlass', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
SELECT 1 FROM neuer_termin;

-- Sa 2026-10-17 19:15-20:35 7| Abendkonzert «Aus tiefer Not» Sat 19.15
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Sa', '2026-10-17', '19:15', '20:35',
    r.id, 'Kzt', '7| Abendkonzert «Aus tiefer Not» Sat 19.15', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
SELECT 1 FROM neuer_termin;

-- Sa 2026-10-17 19:16-19:20 Konzert: Bach/Kurtag "Aus tiefer Not schrei...."
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Sa', '2026-10-17', '19:16', '19:20',
    r.id, 'K', 'Konzert: Bach/Kurtag "Aus tiefer Not schrei...."', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['PFB','VL']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Sa 2026-10-17 19:21-19:48 Konzert: Bartok Solosonate Vl
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Sa', '2026-10-17', '19:21', '19:48',
    r.id, 'K', 'Konzert: Bartok Solosonate Vl', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['DU']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Sa 2026-10-17 19:52-20:32 Konzert: Schubert T&M
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Sa', '2026-10-17', '19:52', '20:32',
    r.id, 'K', 'Konzert: Schubert T&M', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['MEW','EM','AA','RR']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Sa 2026-10-17 20:45-21:15 GP: Kurtág Officium breve
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Sa', '2026-10-17', '20:45', '21:15',
    r.id, 'GP', 'GP: Kurtág Officium breve', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['MEW','EM','AA','RR']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Sa 2026-10-17 21:00-23:00 Dîner
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Sa', '2026-10-17', '21:00', '23:00',
    r.id, NULL, 'Dîner', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Schweizerhof' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['AL','PFB','VL','DU','YL','JK','ER','CF','MEh']) AND m.saison_id = s.id AND s.jahr = 2026;

-- Sa 2026-10-17 21:30-23:00 Dîner
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'Sa', '2026-10-17', '21:30', '23:00',
    r.id, NULL, 'Dîner', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Schweizerhof' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['MEW','EM','AA','RR']) AND m.saison_id = s.id AND s.jahr = 2026;

-- So 2026-10-18 08:00-08:30 Flügelstimmung
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'So', '2026-10-18', '08:00', '08:30',
    r.id, NULL, 'Flügelstimmung', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['MEh']) AND m.saison_id = s.id AND s.jahr = 2026;

-- So 2026-10-18 08:45-09:00 Transport Steinway KGH-Kursaal
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'So', '2026-10-18', '08:45', '09:00',
    r.id, NULL, 'Transport Steinway KGH-Kursaal', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kirchgemeindehaus' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['MEh']) AND m.saison_id = s.id AND s.jahr = 2026;

-- So 2026-10-18 08:45-09:30 GP: Schumann Klaviertrio g-moll
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'So', '2026-10-18', '08:45', '09:30',
    r.id, 'GP', 'GP: Schumann Klaviertrio g-moll', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['PFB','DU','JK']) AND m.saison_id = s.id AND s.jahr = 2026;

-- So 2026-10-18 09:00-20:00 Kein Flügel!
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'So', '2026-10-18', '09:00', '20:00',
    r.id, NULL, 'Kein Flügel!', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kirchgemeindehaus' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
SELECT 1 FROM neuer_termin;

-- So 2026-10-18 09:30-11:00 Practising VL
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'So', '2026-10-18', '09:30', '11:00',
    r.id, NULL, 'Practising VL', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Sonnwendhof' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['VL']) AND m.saison_id = s.id AND s.jahr = 2026;

-- So 2026-10-18 09:35-10:10 GP: Holliger Romancendres
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'So', '2026-10-18', '09:35', '10:10',
    r.id, 'GP', 'GP: Holliger Romancendres', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['RR','PFB']) AND m.saison_id = s.id AND s.jahr = 2026;

-- So 2026-10-18 10:00-11:00 Gottesdienst
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'So', '2026-10-18', '10:00', '11:00',
    r.id, NULL, 'Gottesdienst', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kirchgemeindehaus' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['MEW','ER']) AND m.saison_id = s.id AND s.jahr = 2026;

-- So 2026-10-18 10:15-11:00 Einführung Holliger
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'So', '2026-10-18', '10:15', '11:00',
    r.id, NULL, 'Einführung Holliger', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['RR','PFB']) AND m.saison_id = s.id AND s.jahr = 2026;

-- So 2026-10-18 11:00-12:30 Practising AL
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'So', '2026-10-18', '11:00', '12:30',
    r.id, NULL, 'Practising AL', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Sonnwendhof' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['AL']) AND m.saison_id = s.id AND s.jahr = 2026;

-- So 2026-10-18 11:00-11:15 Saaleinlass
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'So', '2026-10-18', '11:00', '11:15',
    r.id, NULL, 'Saaleinlass', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
SELECT 1 FROM neuer_termin;

-- So 2026-10-18 11:15-12:50 8| Matinee «zu Asche» Sun 11.15
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'So', '2026-10-18', '11:15', '12:50',
    r.id, 'Kzt', '8| Matinee «zu Asche» Sun 11.15', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
SELECT 1 FROM neuer_termin;

-- So 2026-10-18 11:16-11:28 Konzert: Schumann 3 Romanzen op. 94
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'So', '2026-10-18', '11:16', '11:28',
    r.id, 'K', 'Konzert: Schumann 3 Romanzen op. 94', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['VL','CF']) AND m.saison_id = s.id AND s.jahr = 2026;

-- So 2026-10-18 11:31-11:44 Konzert: Kurtág Officium breve
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'So', '2026-10-18', '11:31', '11:44',
    r.id, 'K', 'Konzert: Kurtág Officium breve', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['MEW','EM','AA','RR']) AND m.saison_id = s.id AND s.jahr = 2026;

-- So 2026-10-18 11:47-11:53 Konzert: Schumann Adagio aus VlKonz
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'So', '2026-10-18', '11:47', '11:53',
    r.id, 'K', 'Konzert: Schumann Adagio aus VlKonz', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['VL','DU','ER']) AND m.saison_id = s.id AND s.jahr = 2026;

-- So 2026-10-18 11:55-12:17 Konzert: Holliger Romancendres
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'So', '2026-10-18', '11:55', '12:17',
    r.id, 'K', 'Konzert: Holliger Romancendres', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['RR','PFB']) AND m.saison_id = s.id AND s.jahr = 2026;

-- So 2026-10-18 12:20-12:49 Konzert: Schumann Klaviertrio g-moll
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'So', '2026-10-18', '12:20', '12:49',
    r.id, 'K', 'Konzert: Schumann Klaviertrio g-moll', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['PFB','DU','JK']) AND m.saison_id = s.id AND s.jahr = 2026;

-- So 2026-10-18 13:00-13:10 GP: Bach "Gottes Zeit"
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'So', '2026-10-18', '13:00', '13:10',
    r.id, 'GP', 'GP: Bach "Gottes Zeit"', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['PFB','VL']) AND m.saison_id = s.id AND s.jahr = 2026;

-- So 2026-10-18 13:10-13:40 GP: Haydn Klaviertrio G-Dur Nr. 39
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'So', '2026-10-18', '13:10', '13:40',
    r.id, 'GP', 'GP: Haydn Klaviertrio G-Dur Nr. 39', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['AL','DU','JK']) AND m.saison_id = s.id AND s.jahr = 2026;

-- So 2026-10-18 13:30-14:40 Practising VL
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'So', '2026-10-18', '13:30', '14:40',
    r.id, NULL, 'Practising VL', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Sonnwendhof' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['VL']) AND m.saison_id = s.id AND s.jahr = 2026;

-- So 2026-10-18 13:40-14:20 GP: Kodaly Duo
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'So', '2026-10-18', '13:40', '14:20',
    r.id, 'GP', 'GP: Kodaly Duo', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['RR','YL']) AND m.saison_id = s.id AND s.jahr = 2026;

-- So 2026-10-18 14:20-14:30 GP: Kurtag In Nomine Va solo
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'So', '2026-10-18', '14:20', '14:30',
    r.id, 'GP', 'GP: Kurtag In Nomine Va solo', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['YL']) AND m.saison_id = s.id AND s.jahr = 2026;

-- So 2026-10-18 14:30-15:30 GP: Brahms Sextett G-Dur
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'So', '2026-10-18', '14:30', '15:30',
    r.id, 'GP', 'GP: Brahms Sextett G-Dur', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['MEW','EM','AA','RR','YL','JK']) AND m.saison_id = s.id AND s.jahr = 2026;

-- So 2026-10-18 14:40-15:45 Practising PFB
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'So', '2026-10-18', '14:40', '15:45',
    r.id, NULL, 'Practising PFB', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Sonnwendhof' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['PFB']) AND m.saison_id = s.id AND s.jahr = 2026;

-- So 2026-10-18 15:30-15:40 GP: Zugabe Schubert Ungarische Melodie
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'So', '2026-10-18', '15:30', '15:40',
    r.id, 'GP', 'GP: Zugabe Schubert Ungarische Melodie', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['MEW','EM','AA','RR','YL','JK']) AND m.saison_id = s.id AND s.jahr = 2026;

-- So 2026-10-18 15:40-16:00 Flügelstimmung
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'So', '2026-10-18', '15:40', '16:00',
    r.id, NULL, 'Flügelstimmung', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['MEh']) AND m.saison_id = s.id AND s.jahr = 2026;

-- So 2026-10-18 16:00-16:15 Saaleinlass
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'So', '2026-10-18', '16:00', '16:15',
    r.id, NULL, 'Saaleinlass', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
SELECT 1 FROM neuer_termin;

-- So 2026-10-18 16:15-17:20 9| «All’ongherese» Sun 16.00
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'So', '2026-10-18', '16:15', '17:20',
    r.id, 'Kzt', '9| «All’ongherese» Sun 16.00', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
SELECT 1 FROM neuer_termin;

-- So 2026-10-18 16:16-16:30 Konzert: Haydn Klaviertrio G-Dur Nr. 39
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'So', '2026-10-18', '16:16', '16:30',
    r.id, 'K', 'Konzert: Haydn Klaviertrio G-Dur Nr. 39', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['AL','DU','JK']) AND m.saison_id = s.id AND s.jahr = 2026;

-- So 2026-10-18 16:32-16:37 Konzert: Kurtag In Nomine Va solo
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'So', '2026-10-18', '16:32', '16:37',
    r.id, 'K', 'Konzert: Kurtag In Nomine Va solo', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['YL']) AND m.saison_id = s.id AND s.jahr = 2026;

-- So 2026-10-18 16:39-16:49 Konzert: Veress Introduzione e Coda
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'So', '2026-10-18', '16:39', '16:49',
    r.id, 'K', 'Konzert: Veress Introduzione e Coda', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['EM','JK','CF']) AND m.saison_id = s.id AND s.jahr = 2026;

-- So 2026-10-18 16:51-17:18 Konzert: Kodaly Duo
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'So', '2026-10-18', '16:51', '17:18',
    r.id, 'K', 'Konzert: Kodaly Duo', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['RR','YL']) AND m.saison_id = s.id AND s.jahr = 2026;

-- So 2026-10-18 17:30-18:15 GP: Schumann F-Dur Klaviertrio op. 80
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'So', '2026-10-18', '17:30', '18:15',
    r.id, 'GP', 'GP: Schumann F-Dur Klaviertrio op. 80', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['RR','AL','DU']) AND m.saison_id = s.id AND s.jahr = 2026;

-- So 2026-10-18 18:15-18:30 Saaleinlass
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'So', '2026-10-18', '18:15', '18:30',
    r.id, NULL, 'Saaleinlass', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
SELECT 1 FROM neuer_termin;

-- So 2026-10-18 18:30-20:10 10| Abschlusskonzert Sun 18.30
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'So', '2026-10-18', '18:30', '20:10',
    r.id, 'Kzt', '10| Abschlusskonzert Sun 18.30', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
SELECT 1 FROM neuer_termin;

-- So 2026-10-18 18:31-18:34 Konzert: Bach "Gottes Zeit"
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'So', '2026-10-18', '18:31', '18:34',
    r.id, 'K', 'Konzert: Bach "Gottes Zeit"', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['PFB','VL']) AND m.saison_id = s.id AND s.jahr = 2026;

-- So 2026-10-18 18:35-19:05 Konzert: Schumann F-Dur Klaviertrio op. 80
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'So', '2026-10-18', '18:35', '19:05',
    r.id, 'K', 'Konzert: Schumann F-Dur Klaviertrio op. 80', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['RR','AL','DU']) AND m.saison_id = s.id AND s.jahr = 2026;

-- So 2026-10-18 19:09-19:49 Konzert: Brahms Sextett G-Dur
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'So', '2026-10-18', '19:09', '19:49',
    r.id, 'K', 'Konzert: Brahms Sextett G-Dur', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['MEW','EM','AA','RR','YL','JK']) AND m.saison_id = s.id AND s.jahr = 2026;

-- So 2026-10-18 19:52-19:56 Konzert: Zugabe Schubert Ungarische Melodie
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'So', '2026-10-18', '19:52', '19:56',
    r.id, 'K', 'Konzert: Zugabe Schubert Ungarische Melodie', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['MEW','EM','AA','RR','YL','JK']) AND m.saison_id = s.id AND s.jahr = 2026;

-- So 2026-10-18 19:56-20:10 Konzert: Abschlussrede und Bedankungen
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'So', '2026-10-18', '19:56', '20:10',
    r.id, 'K', 'Konzert: Abschlussrede und Bedankungen', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['MEW','EM','AA','RR','AL','PFB','VL','DU','YL','JK','ER','CF','MEh']) AND m.saison_id = s.id AND s.jahr = 2026;

-- So 2026-10-18 20:10-21:10 Abtransport Flügel
WITH neuer_termin AS (
  INSERT INTO termine (wochentag, datum, anfangszeit, endzeit, raum_id, typ, werk, bemerkungen, saison_id)
  SELECT
    'So', '2026-10-18', '20:10', '21:10',
    r.id, NULL, 'Abtransport Flügel', NULL, s.id
  FROM raeume r, saisons s
  WHERE r.name = 'Kursaal' AND r.saison_id = s.id AND s.jahr = 2026
  RETURNING id
)
INSERT INTO termin_musiker (termin_id, musiker_id)
SELECT nt.id, m.id FROM neuer_termin nt, musiker m, saisons s
WHERE m.kuerzel = ANY(ARRAY['MEh']) AND m.saison_id = s.id AND s.jahr = 2026;

COMMIT;

-- 228 Termine erzeugt.
-- 1 Warnung(en) beim Aufbau des Modells (siehe Konsolen-Ausgabe von build-termine-sql.js):
--   - Termin ohne Raumangabe (Tag So, Werk "Schlussapero") — übersprungen.
