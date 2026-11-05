#!/bin/bash
# NetCable native install for DietPi on Raspberry Pi 1 (ARMv6).
# Run ON the DietPi as the dietpi user:  bash ~/netcable/install.sh
# Code + frontend bundle must already be in /home/dietpi/netcable
# (placed there by the deploy step). This script is idempotent.
set -e
APP=/home/dietpi/netcable

echo "==> [1/6] APT packages (nginx, venv, build deps for bcrypt)..."
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  nginx python3-venv python3-dev libffi-dev curl

echo "==> [2/6] Python venv + backend deps (slow on Pi 1, be patient)..."
if [ ! -x "$APP/venv/bin/python" ]; then
  python3 -m venv "$APP/venv"
fi
"$APP/venv/bin/pip" install --upgrade pip
"$APP/venv/bin/pip" install -r "$APP/install/requirements-dietpi.txt"

echo "==> [3/6] Data dir + credentials..."
mkdir -p "$APP/backend/data"
if [ ! -f "$APP/.env" ]; then
  PASS=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 16)
  printf 'ADMIN_USER=admin\nADMIN_PASSWORD=%s\n' "$PASS" > "$APP/.env"
  chmod 600 "$APP/.env"
  echo "    generated admin password (saved in $APP/.env)"
fi

echo "==> [4/6] systemd backend service..."
sudo cp "$APP/install/netcable-backend.service" /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now netcable-backend

echo "==> [5/6] nginx frontend on :3080..."
sudo cp "$APP/install/nginx-netcable.conf" /etc/nginx/sites-available/netcable
sudo ln -sf /etc/nginx/sites-available/netcable /etc/nginx/sites-enabled/netcable
sudo nginx -t
sudo systemctl enable --now nginx
sudo systemctl reload nginx

echo "==> [6/6] Status..."
sleep 3
curl -sf http://127.0.0.1:8000/api/health && echo
sudo systemctl is-active netcable-backend nginx --quiet && echo "OK: services active"
echo "Done. Open http://$(hostname -I | awk '{print $1}'):3080"
