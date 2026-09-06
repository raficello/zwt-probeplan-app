-- ZwT Probeplan — Konzert-/Werkliste-Daten Saison 2026
-- Automatisch aus dem von Rafi hochgeladenen Excel-Export des Google
-- Sheets "ZwT 2026 - Probeplan" (Tab "config") generiert, 06.09.2026.
-- Anwenden NACH db/schema.sql UND db/migration-werke.sql:
--   docker compose exec -T db sh -c 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"' < ../db/seed-werke-2026.sql

BEGIN;

-- Musiker:innen (Kürzel + echter Name aus dem Sheet)
INSERT INTO musiker (kuerzel, name) VALUES ('AA', 'Alessandro D''Amico') ON CONFLICT (kuerzel) DO UPDATE SET name = EXCLUDED.name;
INSERT INTO musiker (kuerzel, name) VALUES ('AL', 'Alexander Lonquich') ON CONFLICT (kuerzel) DO UPDATE SET name = EXCLUDED.name;
INSERT INTO musiker (kuerzel, name) VALUES ('CF', 'Carlos Ferreira') ON CONFLICT (kuerzel) DO UPDATE SET name = EXCLUDED.name;
INSERT INTO musiker (kuerzel, name) VALUES ('DU', 'Dmytro Udovychenko') ON CONFLICT (kuerzel) DO UPDATE SET name = EXCLUDED.name;
INSERT INTO musiker (kuerzel, name) VALUES ('EM', 'Edouard Mätzener') ON CONFLICT (kuerzel) DO UPDATE SET name = EXCLUDED.name;
INSERT INTO musiker (kuerzel, name) VALUES ('ER', 'Emilie Richter') ON CONFLICT (kuerzel) DO UPDATE SET name = EXCLUDED.name;
INSERT INTO musiker (kuerzel, name) VALUES ('JK', 'Johannes Krebs') ON CONFLICT (kuerzel) DO UPDATE SET name = EXCLUDED.name;
INSERT INTO musiker (kuerzel, name) VALUES ('MEW', 'Mary Ellen Woodside') ON CONFLICT (kuerzel) DO UPDATE SET name = EXCLUDED.name;
INSERT INTO musiker (kuerzel, name) VALUES ('PFB', 'Pau Fernandéz Benlloch') ON CONFLICT (kuerzel) DO UPDATE SET name = EXCLUDED.name;
INSERT INTO musiker (kuerzel, name) VALUES ('RR', 'Rafael Rosenfeld') ON CONFLICT (kuerzel) DO UPDATE SET name = EXCLUDED.name;
INSERT INTO musiker (kuerzel, name) VALUES ('SP', 'Shanti Perpellini') ON CONFLICT (kuerzel) DO UPDATE SET name = EXCLUDED.name;
INSERT INTO musiker (kuerzel, name) VALUES ('TH', 'Tak Him') ON CONFLICT (kuerzel) DO UPDATE SET name = EXCLUDED.name;
INSERT INTO musiker (kuerzel, name) VALUES ('VL', 'Victor Yuanhan Lu') ON CONFLICT (kuerzel) DO UPDATE SET name = EXCLUDED.name;
INSERT INTO musiker (kuerzel, name) VALUES ('YL', 'Yura Lee') ON CONFLICT (kuerzel) DO UPDATE SET name = EXCLUDED.name;
INSERT INTO musiker (kuerzel, name) VALUES ('MAB', 'Miho Attila és barátai') ON CONFLICT (kuerzel) DO UPDATE SET name = EXCLUDED.name;
INSERT INTO musiker (kuerzel, name) VALUES ('MEh', 'Michel Ehrenbaum') ON CONFLICT (kuerzel) DO UPDATE SET name = EXCLUDED.name;
INSERT INTO musiker (kuerzel, name) VALUES ('LP', 'Leandro Pezzoli') ON CONFLICT (kuerzel) DO UPDATE SET name = EXCLUDED.name;

-- Feste Ablaufpunkte (Werk-Vorlagen) mit Standard-Teilnehmern
INSERT INTO werk_vorlagen (nummer, name, typ, dauer_minuten) VALUES (1, 'Saaleinlass', NULL, NULL) ON CONFLICT (nummer) DO UPDATE SET name = EXCLUDED.name, typ = EXCLUDED.typ, dauer_minuten = EXCLUDED.dauer_minuten;
INSERT INTO werk_vorlagen (nummer, name, typ, dauer_minuten) VALUES (2, 'Flügelstimmung', NULL, NULL) ON CONFLICT (nummer) DO UPDATE SET name = EXCLUDED.name, typ = EXCLUDED.typ, dauer_minuten = EXCLUDED.dauer_minuten;
INSERT INTO werk_vorlage_musiker (werk_vorlage_id, musiker_id) SELECT wv.id, m.id FROM werk_vorlagen wv, musiker m WHERE wv.nummer = 2 AND m.kuerzel = ANY(ARRAY['MEh']) ON CONFLICT DO NOTHING;
INSERT INTO werk_vorlagen (nummer, name, typ, dauer_minuten) VALUES (3, 'Dîner', NULL, NULL) ON CONFLICT (nummer) DO UPDATE SET name = EXCLUDED.name, typ = EXCLUDED.typ, dauer_minuten = EXCLUDED.dauer_minuten;
INSERT INTO werk_vorlage_musiker (werk_vorlage_id, musiker_id) SELECT wv.id, m.id FROM werk_vorlagen wv, musiker m WHERE wv.nummer = 3 AND m.kuerzel = ANY(ARRAY['AL','PFB','VL','DU','YL','JK','ER','CF','MEh']) ON CONFLICT DO NOTHING;
INSERT INTO werk_vorlagen (nummer, name, typ, dauer_minuten) VALUES (4, 'Musikerführung im Kloster', NULL, NULL) ON CONFLICT (nummer) DO UPDATE SET name = EXCLUDED.name, typ = EXCLUDED.typ, dauer_minuten = EXCLUDED.dauer_minuten;
INSERT INTO werk_vorlagen (nummer, name, typ, dauer_minuten) VALUES (5, 'Musikeressen', NULL, NULL) ON CONFLICT (nummer) DO UPDATE SET name = EXCLUDED.name, typ = EXCLUDED.typ, dauer_minuten = EXCLUDED.dauer_minuten;
INSERT INTO werk_vorlage_musiker (werk_vorlage_id, musiker_id) SELECT wv.id, m.id FROM werk_vorlagen wv, musiker m WHERE wv.nummer = 5 AND m.kuerzel = ANY(ARRAY['MEW','EM','AA','RR','AL','PFB','VL','DU','YL','JK','ER','CF']) ON CONFLICT DO NOTHING;
INSERT INTO werk_vorlagen (nummer, name, typ, dauer_minuten) VALUES (6, 'Gottesdienst', NULL, NULL) ON CONFLICT (nummer) DO UPDATE SET name = EXCLUDED.name, typ = EXCLUDED.typ, dauer_minuten = EXCLUDED.dauer_minuten;
INSERT INTO werk_vorlage_musiker (werk_vorlage_id, musiker_id) SELECT wv.id, m.id FROM werk_vorlagen wv, musiker m WHERE wv.nummer = 6 AND m.kuerzel = ANY(ARRAY['MEW','ER']) ON CONFLICT DO NOTHING;
INSERT INTO werk_vorlagen (nummer, name, typ, dauer_minuten) VALUES (7, 'Rede', NULL, NULL) ON CONFLICT (nummer) DO UPDATE SET name = EXCLUDED.name, typ = EXCLUDED.typ, dauer_minuten = EXCLUDED.dauer_minuten;
INSERT INTO werk_vorlage_musiker (werk_vorlage_id, musiker_id) SELECT wv.id, m.id FROM werk_vorlagen wv, musiker m WHERE wv.nummer = 7 AND m.kuerzel = ANY(ARRAY['RR']) ON CONFLICT DO NOTHING;
INSERT INTO werk_vorlagen (nummer, name, typ, dauer_minuten) VALUES (8, 'Apero Freundeskonzert', NULL, NULL) ON CONFLICT (nummer) DO UPDATE SET name = EXCLUDED.name, typ = EXCLUDED.typ, dauer_minuten = EXCLUDED.dauer_minuten;
INSERT INTO werk_vorlage_musiker (werk_vorlage_id, musiker_id) SELECT wv.id, m.id FROM werk_vorlagen wv, musiker m WHERE wv.nummer = 8 AND m.kuerzel = ANY(ARRAY['MEW','EM','AA','RR','VL','ER']) ON CONFLICT DO NOTHING;
INSERT INTO werk_vorlagen (nummer, name, typ, dauer_minuten) VALUES (9, 'Abschlussrede und Bedankungen', NULL, NULL) ON CONFLICT (nummer) DO UPDATE SET name = EXCLUDED.name, typ = EXCLUDED.typ, dauer_minuten = EXCLUDED.dauer_minuten;
INSERT INTO werk_vorlage_musiker (werk_vorlage_id, musiker_id) SELECT wv.id, m.id FROM werk_vorlagen wv, musiker m WHERE wv.nummer = 9 AND m.kuerzel = ANY(ARRAY['MEW','EM','AA','RR','AL','PFB','VL','DU','YL','JK','ER','CF','MEh']) ON CONFLICT DO NOTHING;
INSERT INTO werk_vorlagen (nummer, name, typ, dauer_minuten) VALUES (10, 'Schlussapero', NULL, NULL) ON CONFLICT (nummer) DO UPDATE SET name = EXCLUDED.name, typ = EXCLUDED.typ, dauer_minuten = EXCLUDED.dauer_minuten;
INSERT INTO werk_vorlagen (nummer, name, typ, dauer_minuten) VALUES (11, 'Anlieferung/Stimmung Flügel', NULL, NULL) ON CONFLICT (nummer) DO UPDATE SET name = EXCLUDED.name, typ = EXCLUDED.typ, dauer_minuten = EXCLUDED.dauer_minuten;
INSERT INTO werk_vorlage_musiker (werk_vorlage_id, musiker_id) SELECT wv.id, m.id FROM werk_vorlagen wv, musiker m WHERE wv.nummer = 11 AND m.kuerzel = ANY(ARRAY['MEh']) ON CONFLICT DO NOTHING;
INSERT INTO werk_vorlagen (nummer, name, typ, dauer_minuten) VALUES (14, 'Aufbau Technik, Licht', NULL, NULL) ON CONFLICT (nummer) DO UPDATE SET name = EXCLUDED.name, typ = EXCLUDED.typ, dauer_minuten = EXCLUDED.dauer_minuten;
INSERT INTO werk_vorlage_musiker (werk_vorlage_id, musiker_id) SELECT wv.id, m.id FROM werk_vorlagen wv, musiker m WHERE wv.nummer = 14 AND m.kuerzel = ANY(ARRAY['SP']) ON CONFLICT DO NOTHING;
INSERT INTO werk_vorlagen (nummer, name, typ, dauer_minuten) VALUES (15, 'Soundcheck Mikrofon', NULL, NULL) ON CONFLICT (nummer) DO UPDATE SET name = EXCLUDED.name, typ = EXCLUDED.typ, dauer_minuten = EXCLUDED.dauer_minuten;
INSERT INTO werk_vorlagen (nummer, name, typ, dauer_minuten) VALUES (16, 'Aufbau Apero', NULL, NULL) ON CONFLICT (nummer) DO UPDATE SET name = EXCLUDED.name, typ = EXCLUDED.typ, dauer_minuten = EXCLUDED.dauer_minuten;
INSERT INTO werk_vorlagen (nummer, name, typ, dauer_minuten) VALUES (17, 'Freundeskonzert Rede', NULL, NULL) ON CONFLICT (nummer) DO UPDATE SET name = EXCLUDED.name, typ = EXCLUDED.typ, dauer_minuten = EXCLUDED.dauer_minuten;
INSERT INTO werk_vorlagen (nummer, name, typ, dauer_minuten) VALUES (18, 'Umbau Saal', NULL, NULL) ON CONFLICT (nummer) DO UPDATE SET name = EXCLUDED.name, typ = EXCLUDED.typ, dauer_minuten = EXCLUDED.dauer_minuten;
INSERT INTO werk_vorlagen (nummer, name, typ, dauer_minuten) VALUES (19, 'Practising AL', NULL, NULL) ON CONFLICT (nummer) DO UPDATE SET name = EXCLUDED.name, typ = EXCLUDED.typ, dauer_minuten = EXCLUDED.dauer_minuten;
INSERT INTO werk_vorlage_musiker (werk_vorlage_id, musiker_id) SELECT wv.id, m.id FROM werk_vorlagen wv, musiker m WHERE wv.nummer = 19 AND m.kuerzel = ANY(ARRAY['AL']) ON CONFLICT DO NOTHING;
INSERT INTO werk_vorlagen (nummer, name, typ, dauer_minuten) VALUES (20, 'Practising PFB', NULL, NULL) ON CONFLICT (nummer) DO UPDATE SET name = EXCLUDED.name, typ = EXCLUDED.typ, dauer_minuten = EXCLUDED.dauer_minuten;
INSERT INTO werk_vorlage_musiker (werk_vorlage_id, musiker_id) SELECT wv.id, m.id FROM werk_vorlagen wv, musiker m WHERE wv.nummer = 20 AND m.kuerzel = ANY(ARRAY['PFB']) ON CONFLICT DO NOTHING;
INSERT INTO werk_vorlagen (nummer, name, typ, dauer_minuten) VALUES (21, 'Practising VL', NULL, NULL) ON CONFLICT (nummer) DO UPDATE SET name = EXCLUDED.name, typ = EXCLUDED.typ, dauer_minuten = EXCLUDED.dauer_minuten;
INSERT INTO werk_vorlage_musiker (werk_vorlage_id, musiker_id) SELECT wv.id, m.id FROM werk_vorlagen wv, musiker m WHERE wv.nummer = 21 AND m.kuerzel = ANY(ARRAY['VL']) ON CONFLICT DO NOTHING;
INSERT INTO werk_vorlagen (nummer, name, typ, dauer_minuten) VALUES (22, 'Apero bei Birgit Miller', NULL, NULL) ON CONFLICT (nummer) DO UPDATE SET name = EXCLUDED.name, typ = EXCLUDED.typ, dauer_minuten = EXCLUDED.dauer_minuten;
INSERT INTO werk_vorlagen (nummer, name, typ, dauer_minuten) VALUES (23, 'Einführung Holliger', NULL, NULL) ON CONFLICT (nummer) DO UPDATE SET name = EXCLUDED.name, typ = EXCLUDED.typ, dauer_minuten = EXCLUDED.dauer_minuten;
INSERT INTO werk_vorlage_musiker (werk_vorlage_id, musiker_id) SELECT wv.id, m.id FROM werk_vorlagen wv, musiker m WHERE wv.nummer = 23 AND m.kuerzel = ANY(ARRAY['RR','PFB']) ON CONFLICT DO NOTHING;

-- Konzerte + ihre Werke
INSERT INTO konzerte (nummer, name, dauer_minuten) VALUES (0, '0| Freundeskonzert Do 19.00 Kgh', 43.0) ON CONFLICT (nummer) DO UPDATE SET name = EXCLUDED.name, dauer_minuten = EXCLUDED.dauer_minuten;
INSERT INTO werke (konzert_id, nummer, name, dauer_minuten) SELECT id, 1, 'Schumann 3 Fantasiestücke op. 11', 12.0 FROM konzerte WHERE nummer = 0 ON CONFLICT (nummer) DO UPDATE SET name = EXCLUDED.name, dauer_minuten = EXCLUDED.dauer_minuten, konzert_id = EXCLUDED.konzert_id;
INSERT INTO werk_musiker (werk_id, musiker_id) SELECT w.id, m.id FROM werke w, musiker m WHERE w.nummer = 1 AND m.kuerzel = ANY(ARRAY['VL']) ON CONFLICT DO NOTHING;
INSERT INTO werke (konzert_id, nummer, name, dauer_minuten) SELECT id, 2, 'Ligeti Solo', 9.0 FROM konzerte WHERE nummer = 0 ON CONFLICT (nummer) DO UPDATE SET name = EXCLUDED.name, dauer_minuten = EXCLUDED.dauer_minuten, konzert_id = EXCLUDED.konzert_id;
INSERT INTO werk_musiker (werk_id, musiker_id) SELECT w.id, m.id FROM werke w, musiker m WHERE w.nummer = 2 AND m.kuerzel = ANY(ARRAY['ER']) ON CONFLICT DO NOTHING;
INSERT INTO werke (konzert_id, nummer, name, dauer_minuten) SELECT id, 3, 'Beethoven op. 135', 24.0 FROM konzerte WHERE nummer = 0 ON CONFLICT (nummer) DO UPDATE SET name = EXCLUDED.name, dauer_minuten = EXCLUDED.dauer_minuten, konzert_id = EXCLUDED.konzert_id;
INSERT INTO werk_musiker (werk_id, musiker_id) SELECT w.id, m.id FROM werke w, musiker m WHERE w.nummer = 3 AND m.kuerzel = ANY(ARRAY['MEW','EM','AA','RR']) ON CONFLICT DO NOTHING;
INSERT INTO konzerte (nummer, name, dauer_minuten) VALUES (100, '1| Eröffnungskonzert «Zeichen» Fr 17.30', 51) ON CONFLICT (nummer) DO UPDATE SET name = EXCLUDED.name, dauer_minuten = EXCLUDED.dauer_minuten;
INSERT INTO werke (konzert_id, nummer, name, dauer_minuten) SELECT id, 101, 'Beethoven op. 135', 24.0 FROM konzerte WHERE nummer = 100 ON CONFLICT (nummer) DO UPDATE SET name = EXCLUDED.name, dauer_minuten = EXCLUDED.dauer_minuten, konzert_id = EXCLUDED.konzert_id;
INSERT INTO werk_musiker (werk_id, musiker_id) SELECT w.id, m.id FROM werke w, musiker m WHERE w.nummer = 101 AND m.kuerzel = ANY(ARRAY['MEW','EM','AA','RR']) ON CONFLICT DO NOTHING;
INSERT INTO werke (konzert_id, nummer, name, dauer_minuten) SELECT id, 102, 'Schumann Piano Quartet', 27.0 FROM konzerte WHERE nummer = 100 ON CONFLICT (nummer) DO UPDATE SET name = EXCLUDED.name, dauer_minuten = EXCLUDED.dauer_minuten, konzert_id = EXCLUDED.konzert_id;
INSERT INTO werk_musiker (werk_id, musiker_id) SELECT w.id, m.id FROM werke w, musiker m WHERE w.nummer = 102 AND m.kuerzel = ANY(ARRAY['AL','DU','YL','JK']) ON CONFLICT DO NOTHING;
INSERT INTO konzerte (nummer, name, dauer_minuten) VALUES (200, '2| Abendkonzert «Spiele» Fr 19.30', 58) ON CONFLICT (nummer) DO UPDATE SET name = EXCLUDED.name, dauer_minuten = EXCLUDED.dauer_minuten;
INSERT INTO werke (konzert_id, nummer, name, dauer_minuten) SELECT id, 201, 'Kurtag from Jatekok', 20.0 FROM konzerte WHERE nummer = 200 ON CONFLICT (nummer) DO UPDATE SET name = EXCLUDED.name, dauer_minuten = EXCLUDED.dauer_minuten, konzert_id = EXCLUDED.konzert_id;
INSERT INTO werk_musiker (werk_id, musiker_id) SELECT w.id, m.id FROM werke w, musiker m WHERE w.nummer = 201 AND m.kuerzel = ANY(ARRAY['PFB','VL']) ON CONFLICT DO NOTHING;
INSERT INTO werke (konzert_id, nummer, name, dauer_minuten) SELECT id, 202, 'Mozart Kegelstatt', 20.0 FROM konzerte WHERE nummer = 200 ON CONFLICT (nummer) DO UPDATE SET name = EXCLUDED.name, dauer_minuten = EXCLUDED.dauer_minuten, konzert_id = EXCLUDED.konzert_id;
INSERT INTO werk_musiker (werk_id, musiker_id) SELECT w.id, m.id FROM werke w, musiker m WHERE w.nummer = 202 AND m.kuerzel = ANY(ARRAY['PFB','YL','CF']) ON CONFLICT DO NOTHING;
INSERT INTO werke (konzert_id, nummer, name, dauer_minuten) SELECT id, 203, 'Schumann Kinderszenen', 18.0 FROM konzerte WHERE nummer = 200 ON CONFLICT (nummer) DO UPDATE SET name = EXCLUDED.name, dauer_minuten = EXCLUDED.dauer_minuten, konzert_id = EXCLUDED.konzert_id;
INSERT INTO werk_musiker (werk_id, musiker_id) SELECT w.id, m.id FROM werke w, musiker m WHERE w.nummer = 203 AND m.kuerzel = ANY(ARRAY['AL']) ON CONFLICT DO NOTHING;
INSERT INTO konzerte (nummer, name, dauer_minuten) VALUES (300, '3| «Late Night» Fr 22.15', 60) ON CONFLICT (nummer) DO UPDATE SET name = EXCLUDED.name, dauer_minuten = EXCLUDED.dauer_minuten;
INSERT INTO werke (konzert_id, nummer, name, dauer_minuten) SELECT id, 301, 'Attila Mihó és barátai', 60.0 FROM konzerte WHERE nummer = 300 ON CONFLICT (nummer) DO UPDATE SET name = EXCLUDED.name, dauer_minuten = EXCLUDED.dauer_minuten, konzert_id = EXCLUDED.konzert_id;
INSERT INTO konzerte (nummer, name, dauer_minuten) VALUES (400, '4| Matinee Kloster «Dialoge» Sa 10.45', 57) ON CONFLICT (nummer) DO UPDATE SET name = EXCLUDED.name, dauer_minuten = EXCLUDED.dauer_minuten;
INSERT INTO werke (konzert_id, nummer, name, dauer_minuten) SELECT id, 401, 'Mozart Duo B-Dur', 20.0 FROM konzerte WHERE nummer = 400 ON CONFLICT (nummer) DO UPDATE SET name = EXCLUDED.name, dauer_minuten = EXCLUDED.dauer_minuten, konzert_id = EXCLUDED.konzert_id;
INSERT INTO werk_musiker (werk_id, musiker_id) SELECT w.id, m.id FROM werke w, musiker m WHERE w.nummer = 401 AND m.kuerzel = ANY(ARRAY['DU','YL']) ON CONFLICT DO NOTHING;
INSERT INTO werke (konzert_id, nummer, name, dauer_minuten) SELECT id, 402, 'Ligeti Solosonate', 9.0 FROM konzerte WHERE nummer = 400 ON CONFLICT (nummer) DO UPDATE SET name = EXCLUDED.name, dauer_minuten = EXCLUDED.dauer_minuten, konzert_id = EXCLUDED.konzert_id;
INSERT INTO werk_musiker (werk_id, musiker_id) SELECT w.id, m.id FROM werke w, musiker m WHERE w.nummer = 402 AND m.kuerzel = ANY(ARRAY['ER']) ON CONFLICT DO NOTHING;
INSERT INTO werke (konzert_id, nummer, name, dauer_minuten) SELECT id, 403, 'Mozart StrQuintet D-Dur', 28.0 FROM konzerte WHERE nummer = 400 ON CONFLICT (nummer) DO UPDATE SET name = EXCLUDED.name, dauer_minuten = EXCLUDED.dauer_minuten, konzert_id = EXCLUDED.konzert_id;
INSERT INTO werk_musiker (werk_id, musiker_id) SELECT w.id, m.id FROM werke w, musiker m WHERE w.nummer = 403 AND m.kuerzel = ANY(ARRAY['MEW','AA','DU','YL','ER']) ON CONFLICT DO NOTHING;
INSERT INTO konzerte (nummer, name, dauer_minuten) VALUES (500, '5| «The Broken Column» Sat 15.15', 60) ON CONFLICT (nummer) DO UPDATE SET name = EXCLUDED.name, dauer_minuten = EXCLUDED.dauer_minuten;
INSERT INTO werke (konzert_id, nummer, name, dauer_minuten) SELECT id, 501, 'Webern op.11', 3.0 FROM konzerte WHERE nummer = 500 ON CONFLICT (nummer) DO UPDATE SET name = EXCLUDED.name, dauer_minuten = EXCLUDED.dauer_minuten, konzert_id = EXCLUDED.konzert_id;
INSERT INTO werk_musiker (werk_id, musiker_id) SELECT w.id, m.id FROM werke w, musiker m WHERE w.nummer = 501 AND m.kuerzel = ANY(ARRAY['PFB','JK']) ON CONFLICT DO NOTHING;
INSERT INTO werke (konzert_id, nummer, name, dauer_minuten) SELECT id, 502, 'Kurtag from SGM', 12.0 FROM konzerte WHERE nummer = 500 ON CONFLICT (nummer) DO UPDATE SET name = EXCLUDED.name, dauer_minuten = EXCLUDED.dauer_minuten, konzert_id = EXCLUDED.konzert_id;
INSERT INTO werk_musiker (werk_id, musiker_id) SELECT w.id, m.id FROM werke w, musiker m WHERE w.nummer = 502 AND m.kuerzel = ANY(ARRAY['AA','YL','ER']) ON CONFLICT DO NOTHING;
-- ÜBERSPRUNGEN (nicht-numerischer Code, siehe PROGRESS.md "Offene Fragen"): 502a Kurtag from SGM Va/VC
INSERT INTO werke (konzert_id, nummer, name, dauer_minuten) SELECT id, 503, 'Hefti «The Broken Column»', 15.0 FROM konzerte WHERE nummer = 500 ON CONFLICT (nummer) DO UPDATE SET name = EXCLUDED.name, dauer_minuten = EXCLUDED.dauer_minuten, konzert_id = EXCLUDED.konzert_id;
INSERT INTO werk_musiker (werk_id, musiker_id) SELECT w.id, m.id FROM werke w, musiker m WHERE w.nummer = 503 AND m.kuerzel = ANY(ARRAY['MEW','EM','AA','RR']) ON CONFLICT DO NOTHING;
INSERT INTO werke (konzert_id, nummer, name, dauer_minuten) SELECT id, 504, 'Clara Schumann Klaviertrio', 30.0 FROM konzerte WHERE nummer = 500 ON CONFLICT (nummer) DO UPDATE SET name = EXCLUDED.name, dauer_minuten = EXCLUDED.dauer_minuten, konzert_id = EXCLUDED.konzert_id;
INSERT INTO werk_musiker (werk_id, musiker_id) SELECT w.id, m.id FROM werke w, musiker m WHERE w.nummer = 504 AND m.kuerzel = ANY(ARRAY['VL','DU','ER']) ON CONFLICT DO NOTHING;
INSERT INTO konzerte (nummer, name, dauer_minuten) VALUES (600, '6|«Hommage à Robert Schumann» Sat 17.15', 57) ON CONFLICT (nummer) DO UPDATE SET name = EXCLUDED.name, dauer_minuten = EXCLUDED.dauer_minuten;
INSERT INTO werke (konzert_id, nummer, name, dauer_minuten) SELECT id, 601, 'Schumann Nachtstücke Op 23', 16.0 FROM konzerte WHERE nummer = 600 ON CONFLICT (nummer) DO UPDATE SET name = EXCLUDED.name, dauer_minuten = EXCLUDED.dauer_minuten, konzert_id = EXCLUDED.konzert_id;
INSERT INTO werk_musiker (werk_id, musiker_id) SELECT w.id, m.id FROM werke w, musiker m WHERE w.nummer = 601 AND m.kuerzel = ANY(ARRAY['PFB']) ON CONFLICT DO NOTHING;
INSERT INTO werke (konzert_id, nummer, name, dauer_minuten) SELECT id, 602, 'Schumann Märchenerzählungen', 15.0 FROM konzerte WHERE nummer = 600 ON CONFLICT (nummer) DO UPDATE SET name = EXCLUDED.name, dauer_minuten = EXCLUDED.dauer_minuten, konzert_id = EXCLUDED.konzert_id;
INSERT INTO werk_musiker (werk_id, musiker_id) SELECT w.id, m.id FROM werke w, musiker m WHERE w.nummer = 602 AND m.kuerzel = ANY(ARRAY['AL','YL','CF']) ON CONFLICT DO NOTHING;
INSERT INTO werke (konzert_id, nummer, name, dauer_minuten) SELECT id, 603, 'Kurtág Hommage à R. Sch.', 10.0 FROM konzerte WHERE nummer = 600 ON CONFLICT (nummer) DO UPDATE SET name = EXCLUDED.name, dauer_minuten = EXCLUDED.dauer_minuten, konzert_id = EXCLUDED.konzert_id;
INSERT INTO werk_musiker (werk_id, musiker_id) SELECT w.id, m.id FROM werke w, musiker m WHERE w.nummer = 603 AND m.kuerzel = ANY(ARRAY['AA','PFB','CF']) ON CONFLICT DO NOTHING;
INSERT INTO werke (konzert_id, nummer, name, dauer_minuten) SELECT id, 604, 'Brahms Variationen 4-Händig', 16.0 FROM konzerte WHERE nummer = 600 ON CONFLICT (nummer) DO UPDATE SET name = EXCLUDED.name, dauer_minuten = EXCLUDED.dauer_minuten, konzert_id = EXCLUDED.konzert_id;
INSERT INTO werk_musiker (werk_id, musiker_id) SELECT w.id, m.id FROM werke w, musiker m WHERE w.nummer = 604 AND m.kuerzel = ANY(ARRAY['AL','VL']) ON CONFLICT DO NOTHING;
INSERT INTO konzerte (nummer, name, dauer_minuten) VALUES (700, '7| Abendkonzert «Aus tiefer Not» Sat 19.15', 71) ON CONFLICT (nummer) DO UPDATE SET name = EXCLUDED.name, dauer_minuten = EXCLUDED.dauer_minuten;
INSERT INTO werke (konzert_id, nummer, name, dauer_minuten) SELECT id, 701, 'Bach/Kurtag "Aus tiefer Not schrei...."', 4.0 FROM konzerte WHERE nummer = 700 ON CONFLICT (nummer) DO UPDATE SET name = EXCLUDED.name, dauer_minuten = EXCLUDED.dauer_minuten, konzert_id = EXCLUDED.konzert_id;
INSERT INTO werk_musiker (werk_id, musiker_id) SELECT w.id, m.id FROM werke w, musiker m WHERE w.nummer = 701 AND m.kuerzel = ANY(ARRAY['PFB','VL']) ON CONFLICT DO NOTHING;
INSERT INTO werke (konzert_id, nummer, name, dauer_minuten) SELECT id, 702, 'Bartok Solosonate Vl', 27.0 FROM konzerte WHERE nummer = 700 ON CONFLICT (nummer) DO UPDATE SET name = EXCLUDED.name, dauer_minuten = EXCLUDED.dauer_minuten, konzert_id = EXCLUDED.konzert_id;
INSERT INTO werk_musiker (werk_id, musiker_id) SELECT w.id, m.id FROM werke w, musiker m WHERE w.nummer = 702 AND m.kuerzel = ANY(ARRAY['DU']) ON CONFLICT DO NOTHING;
INSERT INTO werke (konzert_id, nummer, name, dauer_minuten) SELECT id, 703, 'Schubert T&M', 40.0 FROM konzerte WHERE nummer = 700 ON CONFLICT (nummer) DO UPDATE SET name = EXCLUDED.name, dauer_minuten = EXCLUDED.dauer_minuten, konzert_id = EXCLUDED.konzert_id;
INSERT INTO werk_musiker (werk_id, musiker_id) SELECT w.id, m.id FROM werke w, musiker m WHERE w.nummer = 703 AND m.kuerzel = ANY(ARRAY['MEW','EM','AA','RR']) ON CONFLICT DO NOTHING;
INSERT INTO konzerte (nummer, name, dauer_minuten) VALUES (800, '8| Matinee «zu Asche» Sun 11.15', 82) ON CONFLICT (nummer) DO UPDATE SET name = EXCLUDED.name, dauer_minuten = EXCLUDED.dauer_minuten;
INSERT INTO werke (konzert_id, nummer, name, dauer_minuten) SELECT id, 801, 'Schumann 3 Romanzen op. 94', 12.0 FROM konzerte WHERE nummer = 800 ON CONFLICT (nummer) DO UPDATE SET name = EXCLUDED.name, dauer_minuten = EXCLUDED.dauer_minuten, konzert_id = EXCLUDED.konzert_id;
INSERT INTO werk_musiker (werk_id, musiker_id) SELECT w.id, m.id FROM werke w, musiker m WHERE w.nummer = 801 AND m.kuerzel = ANY(ARRAY['VL','CF']) ON CONFLICT DO NOTHING;
INSERT INTO werke (konzert_id, nummer, name, dauer_minuten) SELECT id, 802, 'Kurtág Officium breve', 13.0 FROM konzerte WHERE nummer = 800 ON CONFLICT (nummer) DO UPDATE SET name = EXCLUDED.name, dauer_minuten = EXCLUDED.dauer_minuten, konzert_id = EXCLUDED.konzert_id;
INSERT INTO werk_musiker (werk_id, musiker_id) SELECT w.id, m.id FROM werke w, musiker m WHERE w.nummer = 802 AND m.kuerzel = ANY(ARRAY['MEW','EM','AA','RR']) ON CONFLICT DO NOTHING;
INSERT INTO werke (konzert_id, nummer, name, dauer_minuten) SELECT id, 803, 'Schumann Adagio aus VlKonz', 6.0 FROM konzerte WHERE nummer = 800 ON CONFLICT (nummer) DO UPDATE SET name = EXCLUDED.name, dauer_minuten = EXCLUDED.dauer_minuten, konzert_id = EXCLUDED.konzert_id;
INSERT INTO werk_musiker (werk_id, musiker_id) SELECT w.id, m.id FROM werke w, musiker m WHERE w.nummer = 803 AND m.kuerzel = ANY(ARRAY['VL','DU','ER']) ON CONFLICT DO NOTHING;
INSERT INTO werke (konzert_id, nummer, name, dauer_minuten) SELECT id, 804, 'Holliger Romancendres', 22.0 FROM konzerte WHERE nummer = 800 ON CONFLICT (nummer) DO UPDATE SET name = EXCLUDED.name, dauer_minuten = EXCLUDED.dauer_minuten, konzert_id = EXCLUDED.konzert_id;
INSERT INTO werk_musiker (werk_id, musiker_id) SELECT w.id, m.id FROM werke w, musiker m WHERE w.nummer = 804 AND m.kuerzel = ANY(ARRAY['RR','PFB']) ON CONFLICT DO NOTHING;
INSERT INTO werke (konzert_id, nummer, name, dauer_minuten) SELECT id, 805, 'Schumann Klaviertrio g-moll', 29.0 FROM konzerte WHERE nummer = 800 ON CONFLICT (nummer) DO UPDATE SET name = EXCLUDED.name, dauer_minuten = EXCLUDED.dauer_minuten, konzert_id = EXCLUDED.konzert_id;
INSERT INTO werk_musiker (werk_id, musiker_id) SELECT w.id, m.id FROM werke w, musiker m WHERE w.nummer = 805 AND m.kuerzel = ANY(ARRAY['PFB','DU','JK']) ON CONFLICT DO NOTHING;
INSERT INTO konzerte (nummer, name, dauer_minuten) VALUES (900, '9| «All’ongherese» Sun 16.00', 55.5) ON CONFLICT (nummer) DO UPDATE SET name = EXCLUDED.name, dauer_minuten = EXCLUDED.dauer_minuten;
INSERT INTO werke (konzert_id, nummer, name, dauer_minuten) SELECT id, 901, 'Haydn Klaviertrio G-Dur Nr. 39', 14.0 FROM konzerte WHERE nummer = 900 ON CONFLICT (nummer) DO UPDATE SET name = EXCLUDED.name, dauer_minuten = EXCLUDED.dauer_minuten, konzert_id = EXCLUDED.konzert_id;
INSERT INTO werk_musiker (werk_id, musiker_id) SELECT w.id, m.id FROM werke w, musiker m WHERE w.nummer = 901 AND m.kuerzel = ANY(ARRAY['AL','DU','JK']) ON CONFLICT DO NOTHING;
INSERT INTO werke (konzert_id, nummer, name, dauer_minuten) SELECT id, 902, 'Kurtag In Nomine Va solo', 4.5 FROM konzerte WHERE nummer = 900 ON CONFLICT (nummer) DO UPDATE SET name = EXCLUDED.name, dauer_minuten = EXCLUDED.dauer_minuten, konzert_id = EXCLUDED.konzert_id;
INSERT INTO werk_musiker (werk_id, musiker_id) SELECT w.id, m.id FROM werke w, musiker m WHERE w.nummer = 902 AND m.kuerzel = ANY(ARRAY['YL']) ON CONFLICT DO NOTHING;
INSERT INTO werke (konzert_id, nummer, name, dauer_minuten) SELECT id, 903, 'Veress Introduzione e Coda', 10.0 FROM konzerte WHERE nummer = 900 ON CONFLICT (nummer) DO UPDATE SET name = EXCLUDED.name, dauer_minuten = EXCLUDED.dauer_minuten, konzert_id = EXCLUDED.konzert_id;
INSERT INTO werk_musiker (werk_id, musiker_id) SELECT w.id, m.id FROM werke w, musiker m WHERE w.nummer = 903 AND m.kuerzel = ANY(ARRAY['EM','JK','CF']) ON CONFLICT DO NOTHING;
INSERT INTO werke (konzert_id, nummer, name, dauer_minuten) SELECT id, 904, 'Kodaly Duo', 27.0 FROM konzerte WHERE nummer = 900 ON CONFLICT (nummer) DO UPDATE SET name = EXCLUDED.name, dauer_minuten = EXCLUDED.dauer_minuten, konzert_id = EXCLUDED.konzert_id;
INSERT INTO werk_musiker (werk_id, musiker_id) SELECT w.id, m.id FROM werke w, musiker m WHERE w.nummer = 904 AND m.kuerzel = ANY(ARRAY['RR','YL']) ON CONFLICT DO NOTHING;
INSERT INTO konzerte (nummer, name, dauer_minuten) VALUES (1000, '10| Abschlusskonzert Sun 18.30', 77) ON CONFLICT (nummer) DO UPDATE SET name = EXCLUDED.name, dauer_minuten = EXCLUDED.dauer_minuten;
INSERT INTO werke (konzert_id, nummer, name, dauer_minuten) SELECT id, 1001, 'Bach "Gottes Zeit"', 3.0 FROM konzerte WHERE nummer = 1000 ON CONFLICT (nummer) DO UPDATE SET name = EXCLUDED.name, dauer_minuten = EXCLUDED.dauer_minuten, konzert_id = EXCLUDED.konzert_id;
INSERT INTO werk_musiker (werk_id, musiker_id) SELECT w.id, m.id FROM werke w, musiker m WHERE w.nummer = 1001 AND m.kuerzel = ANY(ARRAY['PFB','VL']) ON CONFLICT DO NOTHING;
INSERT INTO werke (konzert_id, nummer, name, dauer_minuten) SELECT id, 1002, 'Schumann F-Dur Klaviertrio op. 80', 30.0 FROM konzerte WHERE nummer = 1000 ON CONFLICT (nummer) DO UPDATE SET name = EXCLUDED.name, dauer_minuten = EXCLUDED.dauer_minuten, konzert_id = EXCLUDED.konzert_id;
INSERT INTO werk_musiker (werk_id, musiker_id) SELECT w.id, m.id FROM werke w, musiker m WHERE w.nummer = 1002 AND m.kuerzel = ANY(ARRAY['RR','AL','DU']) ON CONFLICT DO NOTHING;
INSERT INTO werke (konzert_id, nummer, name, dauer_minuten) SELECT id, 1003, 'Brahms Sextett G-Dur', 40.0 FROM konzerte WHERE nummer = 1000 ON CONFLICT (nummer) DO UPDATE SET name = EXCLUDED.name, dauer_minuten = EXCLUDED.dauer_minuten, konzert_id = EXCLUDED.konzert_id;
INSERT INTO werk_musiker (werk_id, musiker_id) SELECT w.id, m.id FROM werke w, musiker m WHERE w.nummer = 1003 AND m.kuerzel = ANY(ARRAY['MEW','EM','AA','RR','YL','JK']) ON CONFLICT DO NOTHING;
INSERT INTO werke (konzert_id, nummer, name, dauer_minuten) SELECT id, 1004, 'Zugabe Schubert Ungarische Melodie', 4.0 FROM konzerte WHERE nummer = 1000 ON CONFLICT (nummer) DO UPDATE SET name = EXCLUDED.name, dauer_minuten = EXCLUDED.dauer_minuten, konzert_id = EXCLUDED.konzert_id;
INSERT INTO werk_musiker (werk_id, musiker_id) SELECT w.id, m.id FROM werke w, musiker m WHERE w.nummer = 1004 AND m.kuerzel = ANY(ARRAY['MEW','EM','AA','RR','YL','JK']) ON CONFLICT DO NOTHING;

COMMIT;
