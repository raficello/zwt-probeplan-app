-- ZwT Probeplan — Räume, Wochentags-Einschränkungen und Raumwechsel-
-- Pufferzeiten aus dem Tab "Config" des Google Sheets "ZwT 2026 -
-- Probeplan" (Bereiche conf_raume / conf_intervals), am 06.09.2026
-- ausgelesen. Behebt: leere Raumliste in der Terminverwaltung.
--
-- Idempotent (ON CONFLICT ... DO UPDATE) — kann gefahrlos mehrfach
-- angewendet werden, z.B. wenn sich die Config-Werte später ändern.
--
-- Seit der Saison-Verwaltung (07.09.2026, siehe REFERENCE.md
-- "Saison-Verwaltung" und db/migration-saisons.sql) gehört jeder Raum zu
-- genau einer Saison -- dieses Skript bestückt bewusst die Saison 2026
-- (per Unterabfrage aufgelöst, kein hartkodiertes id). Muss NACH
-- db/migration-saisons.sql laufen.
--
-- Anwenden auf dem VPS:
--   docker compose exec -T db sh -c 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"' \
--     < ../db/seed-raeume.sql
-- (siehe REFERENCE.md Abschnitt 13: -T-Flag nötig, sonst TTY-Fehler)

BEGIN;

INSERT INTO raeume (name, erlaubte_tage, saison_id) VALUES
  ('Kursaal', ARRAY['Do','Fr','Sa','So'], (SELECT id FROM saisons WHERE jahr = 2026)),
  ('Kirchgemeindehaus', NULL, (SELECT id FROM saisons WHERE jahr = 2026)),
  ('Musiksaal', ARRAY['Mo','Di','Mi'], (SELECT id FROM saisons WHERE jahr = 2026)),
  ('Pilatesraum', NULL, (SELECT id FROM saisons WHERE jahr = 2026)),
  ('Sonnwendhof', NULL, (SELECT id FROM saisons WHERE jahr = 2026)),
  ('Hotel Hahnenblick', NULL, (SELECT id FROM saisons WHERE jahr = 2026)),
  ('Carol', NULL, (SELECT id FROM saisons WHERE jahr = 2026)),
  ('Elisabeth Brun, Mühlematt 33', NULL, (SELECT id FROM saisons WHERE jahr = 2026)),
  ('Garderobe', NULL, (SELECT id FROM saisons WHERE jahr = 2026)),
  ('Schweizerhof', NULL, (SELECT id FROM saisons WHERE jahr = 2026)),
  ('Kloster Barocksaal', NULL, (SELECT id FROM saisons WHERE jahr = 2026)),
  ('Alpenclub', NULL, (SELECT id FROM saisons WHERE jahr = 2026))
ON CONFLICT (name, saison_id) DO UPDATE SET erlaubte_tage = EXCLUDED.erlaubte_tage;

-- Pufferzeiten-Matrix (Minuten). Symmetrisch in den Quelldaten, daher
-- beide Richtungen eingetragen; Diagonale (derselbe Raum) ist 0 in den
-- Quelldaten -- siehe REFERENCE.md/PROGRESS.md "Offene Fragen" zur
-- noch ungeklärten Frage, ob/wie der Server diese Matrix für
-- raumübergreifende Wege aktuell auswertet (Stand 06.09.2026: die
-- vorhandene Konfliktprüfung fragt nur den Eintrag Raum->sich selbst
-- ab, nicht Raum-A->Raum-B -- die hier gesetzten Werte sind also schon
-- mal korrekt hinterlegt, auch wenn die Anwendung dieser Matrix noch
-- nachgezogen werden muss).
WITH matrix(von_name, bis_name, minuten) AS (
  VALUES
    ('Kursaal','Kursaal',0), ('Kursaal','Kirchgemeindehaus',10), ('Kursaal','Musiksaal',20), ('Kursaal','Pilatesraum',20), ('Kursaal','Sonnwendhof',15), ('Kursaal','Hotel Hahnenblick',20), ('Kursaal','Carol',10), ('Kursaal','Elisabeth Brun, Mühlematt 33',30), ('Kursaal','Garderobe',5), ('Kursaal','Schweizerhof',5), ('Kursaal','Kloster Barocksaal',20), ('Kursaal','Alpenclub',15),
    ('Kirchgemeindehaus','Kursaal',10), ('Kirchgemeindehaus','Kirchgemeindehaus',0), ('Kirchgemeindehaus','Musiksaal',20), ('Kirchgemeindehaus','Pilatesraum',20), ('Kirchgemeindehaus','Sonnwendhof',10), ('Kirchgemeindehaus','Hotel Hahnenblick',20), ('Kirchgemeindehaus','Carol',15), ('Kirchgemeindehaus','Elisabeth Brun, Mühlematt 33',30), ('Kirchgemeindehaus','Garderobe',15), ('Kirchgemeindehaus','Schweizerhof',5), ('Kirchgemeindehaus','Kloster Barocksaal',25), ('Kirchgemeindehaus','Alpenclub',15),
    ('Musiksaal','Kursaal',20), ('Musiksaal','Kirchgemeindehaus',20), ('Musiksaal','Musiksaal',0), ('Musiksaal','Pilatesraum',10), ('Musiksaal','Sonnwendhof',25), ('Musiksaal','Hotel Hahnenblick',15), ('Musiksaal','Carol',20), ('Musiksaal','Elisabeth Brun, Mühlematt 33',20), ('Musiksaal','Garderobe',20), ('Musiksaal','Schweizerhof',20), ('Musiksaal','Kloster Barocksaal',10), ('Musiksaal','Alpenclub',15),
    ('Pilatesraum','Kursaal',20), ('Pilatesraum','Kirchgemeindehaus',20), ('Pilatesraum','Musiksaal',10), ('Pilatesraum','Pilatesraum',0), ('Pilatesraum','Sonnwendhof',20), ('Pilatesraum','Hotel Hahnenblick',15), ('Pilatesraum','Carol',20), ('Pilatesraum','Elisabeth Brun, Mühlematt 33',20), ('Pilatesraum','Garderobe',15), ('Pilatesraum','Schweizerhof',20), ('Pilatesraum','Kloster Barocksaal',15), ('Pilatesraum','Alpenclub',10),
    ('Sonnwendhof','Kursaal',15), ('Sonnwendhof','Kirchgemeindehaus',10), ('Sonnwendhof','Musiksaal',25), ('Sonnwendhof','Pilatesraum',20), ('Sonnwendhof','Sonnwendhof',0), ('Sonnwendhof','Hotel Hahnenblick',30), ('Sonnwendhof','Carol',15), ('Sonnwendhof','Elisabeth Brun, Mühlematt 33',30), ('Sonnwendhof','Garderobe',15), ('Sonnwendhof','Schweizerhof',10), ('Sonnwendhof','Kloster Barocksaal',25), ('Sonnwendhof','Alpenclub',20),
    ('Hotel Hahnenblick','Kursaal',20), ('Hotel Hahnenblick','Kirchgemeindehaus',20), ('Hotel Hahnenblick','Musiksaal',15), ('Hotel Hahnenblick','Pilatesraum',15), ('Hotel Hahnenblick','Sonnwendhof',30), ('Hotel Hahnenblick','Hotel Hahnenblick',0), ('Hotel Hahnenblick','Carol',25), ('Hotel Hahnenblick','Elisabeth Brun, Mühlematt 33',30), ('Hotel Hahnenblick','Garderobe',25), ('Hotel Hahnenblick','Schweizerhof',25), ('Hotel Hahnenblick','Kloster Barocksaal',20), ('Hotel Hahnenblick','Alpenclub',15),
    ('Carol','Kursaal',10), ('Carol','Kirchgemeindehaus',15), ('Carol','Musiksaal',20), ('Carol','Pilatesraum',20), ('Carol','Sonnwendhof',15), ('Carol','Hotel Hahnenblick',25), ('Carol','Carol',0), ('Carol','Elisabeth Brun, Mühlematt 33',20), ('Carol','Garderobe',15), ('Carol','Schweizerhof',15), ('Carol','Kloster Barocksaal',25), ('Carol','Alpenclub',15),
    ('Elisabeth Brun, Mühlematt 33','Kursaal',30), ('Elisabeth Brun, Mühlematt 33','Kirchgemeindehaus',30), ('Elisabeth Brun, Mühlematt 33','Musiksaal',20), ('Elisabeth Brun, Mühlematt 33','Pilatesraum',20), ('Elisabeth Brun, Mühlematt 33','Sonnwendhof',30), ('Elisabeth Brun, Mühlematt 33','Hotel Hahnenblick',30), ('Elisabeth Brun, Mühlematt 33','Carol',20), ('Elisabeth Brun, Mühlematt 33','Elisabeth Brun, Mühlematt 33',0), ('Elisabeth Brun, Mühlematt 33','Garderobe',25), ('Elisabeth Brun, Mühlematt 33','Schweizerhof',25), ('Elisabeth Brun, Mühlematt 33','Kloster Barocksaal',20), ('Elisabeth Brun, Mühlematt 33','Alpenclub',20),
    ('Garderobe','Kursaal',5), ('Garderobe','Kirchgemeindehaus',15), ('Garderobe','Musiksaal',20), ('Garderobe','Pilatesraum',15), ('Garderobe','Sonnwendhof',15), ('Garderobe','Hotel Hahnenblick',25), ('Garderobe','Carol',15), ('Garderobe','Elisabeth Brun, Mühlematt 33',25), ('Garderobe','Garderobe',0), ('Garderobe','Schweizerhof',10), ('Garderobe','Kloster Barocksaal',20), ('Garderobe','Alpenclub',15),
    ('Schweizerhof','Kursaal',5), ('Schweizerhof','Kirchgemeindehaus',5), ('Schweizerhof','Musiksaal',20), ('Schweizerhof','Pilatesraum',20), ('Schweizerhof','Sonnwendhof',10), ('Schweizerhof','Hotel Hahnenblick',25), ('Schweizerhof','Carol',15), ('Schweizerhof','Elisabeth Brun, Mühlematt 33',25), ('Schweizerhof','Garderobe',10), ('Schweizerhof','Schweizerhof',0), ('Schweizerhof','Kloster Barocksaal',25), ('Schweizerhof','Alpenclub',10),
    ('Kloster Barocksaal','Kursaal',20), ('Kloster Barocksaal','Kirchgemeindehaus',25), ('Kloster Barocksaal','Musiksaal',10), ('Kloster Barocksaal','Pilatesraum',15), ('Kloster Barocksaal','Sonnwendhof',25), ('Kloster Barocksaal','Hotel Hahnenblick',20), ('Kloster Barocksaal','Carol',25), ('Kloster Barocksaal','Elisabeth Brun, Mühlematt 33',20), ('Kloster Barocksaal','Garderobe',20), ('Kloster Barocksaal','Schweizerhof',25), ('Kloster Barocksaal','Kloster Barocksaal',0), ('Kloster Barocksaal','Alpenclub',15),
    ('Alpenclub','Kursaal',15), ('Alpenclub','Kirchgemeindehaus',15), ('Alpenclub','Musiksaal',15), ('Alpenclub','Pilatesraum',10), ('Alpenclub','Sonnwendhof',20), ('Alpenclub','Hotel Hahnenblick',15), ('Alpenclub','Carol',15), ('Alpenclub','Elisabeth Brun, Mühlematt 33',20), ('Alpenclub','Garderobe',15), ('Alpenclub','Schweizerhof',10), ('Alpenclub','Kloster Barocksaal',15), ('Alpenclub','Alpenclub',0)
)
INSERT INTO raum_puffer (von_raum_id, bis_raum_id, puffer_minuten)
SELECT von.id, bis.id, m.minuten
FROM matrix m
JOIN raeume von ON von.name = m.von_name AND von.saison_id = (SELECT id FROM saisons WHERE jahr = 2026)
JOIN raeume bis ON bis.name = m.bis_name AND bis.saison_id = (SELECT id FROM saisons WHERE jahr = 2026)
ON CONFLICT (von_raum_id, bis_raum_id) DO UPDATE SET puffer_minuten = EXCLUDED.puffer_minuten;

COMMIT;
