'use strict';

// Gemeinsamer Postgres-Connection-Pool, ausgelagert aus index.js
// (07.09.2026), damit auth.js (Login gegen die neue `benutzer`-Tabelle,
// siehe REFERENCE.md "Mehrere Benutzer:innen") ebenfalls Zugriff hat,
// ohne einen require-Zyklus mit index.js einzugehen.
//
// WICHTIG (siehe REFERENCE.md Abschnitt 13): jede neue server/-Datei
// braucht eine eigene Dockerfile-COPY-Zeile — bei dieser Datei bereits
// erledigt.

const { Pool } = require('pg');

const pool = process.env.DATABASE_URL ? new Pool({ connectionString: process.env.DATABASE_URL }) : null;

module.exports = { pool };
