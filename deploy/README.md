# Deployment auf dem Infomaniak VPS

Diese Dateien wurden in einer nächtlichen Sitzung **vorbereitet**, aber
**nicht angewendet** — eine Cloud-Sandbox-Sitzung hat keinen Zugriff auf
den VPS (kein allgemeiner Internetzugang, siehe REFERENCE.md Abschnitt 9).
Rafi (oder eine Sitzung mit verlinktem Computer) muss die folgenden
Schritte einmalig manuell ausführen.

VPS-Zugangsdaten (siehe auch REFERENCE.md Abschnitt 9):
IP `83.228.213.202`, SSH-User `ubuntu`, Ubuntu 26.04 LTS.

## 1. Dieses Repo auf den VPS bringen

```
git clone <repo-url> zwt-probeplan-app
# oder, falls GitHub-Push noch blockiert ist (siehe PROGRESS.md):
# das per SendUserFile zugeschickte ZIP entpacken
```

## 2. Docker installieren (falls noch nicht vorhanden)

```
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker ubuntu
# neu einloggen, damit die Gruppenmitgliedschaft wirkt
```

## 3. Automatische Sicherheitsupdates einrichten

```
sudo bash deploy/bootstrap-unattended-upgrades.sh
```

## 4. Umgebungsvariablen setzen

```
cd deploy
cp .env.example .env
nano .env   # POSTGRES_PASSWORD auf ein echtes, sicheres Passwort setzen
```

## 5. Domain (falls schon entschieden) in die Caddyfile eintragen

Die Domain-Frage ist laut `PROGRESS.md` (Phase 0) noch offen. Falls
inzwischen entschieden: in `deploy/Caddyfile` den auskommentierten
Produktiv-Block aktivieren und die `:80`-Übergangsvariante entfernen.
Ohne Domain funktioniert die Übergangsvariante über die nackte IP
(ohne HTTPS) zum Testen.

## 6. Stack starten

```
cd deploy
docker compose up -d --build
docker compose ps
curl http://localhost/health
```

Erwartete Antwort: `{"status":"ok","service":"zwt-probeplan-server"}`.

## 7. Datenbankschema anwenden

```
docker compose exec db psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
  < ../db/schema.sql
```

(Alternativ: `psql "$DATABASE_URL" -f ../db/schema.sql` von ausserhalb
des Containers, falls Postgres-Port nach aussen freigegeben ist — nicht
empfohlen für den Produktivbetrieb.)

## 8. Firewall

Nur Port 22 (SSH), 80 und 443 sollten von aussen erreichbar sein:

```
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

## Noch offen (nicht Teil dieser Vorbereitung)

- **Backup nach Swiss Backup**: laut `PROGRESS.md` (Phase 0) ist Swiss
  Backup noch nicht bestellt — ein Backup-Cronjob macht erst Sinn, sobald
  Zugangsdaten/Ziel feststehen. Nächster Schritt für Phase 2, sobald das
  erledigt ist.
- **Domain**: siehe Schritt 5 oben.

## Bestätigung an die nächste (nächtliche) Sitzung

Sobald die Schritte oben ausgeführt sind und `curl http://<ip-oder-domain>/health`
funktioniert, bitte in `PROGRESS.md` unter Phase 2 vermerken (oder Rafi
sagt es einer Sitzung mit verlinktem Computer, die es einträgt) — erst
dann gilt Phase 2 als abgeschlossen.
