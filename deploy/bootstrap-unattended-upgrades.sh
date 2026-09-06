#!/usr/bin/env bash
# ZwT Probeplan — richtet unattended-upgrades auf dem Ubuntu-VPS ein
# (automatische Sicherheitsupdates, kein Zutun nötig).
#
# Ausführen auf dem VPS (als root oder mit sudo):
#   sudo bash bootstrap-unattended-upgrades.sh
#
# Idempotent: mehrfaches Ausführen ist unschädlich.

set -euo pipefail

apt-get update
apt-get install -y unattended-upgrades apt-listchanges

dpkg-reconfigure -f noninteractive unattended-upgrades

cat > /etc/apt/apt.conf.d/20auto-upgrades <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF

systemctl enable --now unattended-upgrades

echo "unattended-upgrades eingerichtet. Status prüfen mit:"
echo "  systemctl status unattended-upgrades"
echo "  cat /var/log/unattended-upgrades/unattended-upgrades.log"
