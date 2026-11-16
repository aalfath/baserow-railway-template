#!/bin/bash
# Railway wrapper for the Baserow all-in-one image.
#
# Baserow makes the first person who signs up its instance-wide admin, and sign-up is
# open by default. On a fresh public URL that person could be anyone. So, before
# Baserow's web server listens on $PORT, this script:
#   1. runs the database migrations,
#   2. creates the admin from BASEROW_ADMIN_EMAIL / BASEROW_ADMIN_PASSWORD when the
#      database has no users yet, and turns public sign-up off,
#   3. starts Baserow as the upstream image does.
set -euo pipefail

# Railway's edge terminates TLS and forwards plain HTTP to $PORT.
RAILWAY_PORT="${PORT:-80}"
export BASEROW_CADDY_ADDRESSES="${BASEROW_CADDY_ADDRESSES:-http://:${RAILWAY_PORT}}"
export BASEROW_ENABLE_SECURE_PROXY_SSL_HEADER="${BASEROW_ENABLE_SECURE_PROXY_SSL_HEADER:-yes}"
if [[ -z "${BASEROW_PUBLIC_URL:-}" && -n "${RAILWAY_PUBLIC_DOMAIN:-}" ]]; then
  export BASEROW_PUBLIC_URL="https://${RAILWAY_PUBLIC_DOMAIN}"
fi
# Only Caddy may listen on $PORT. Baserow's Nuxt frontend also reads PORT and would
# fight Caddy for it (EADDRINUSE) instead of using its internal port 3000.
unset PORT

DATA_DIR="${DATA_DIR:-/baserow/data}"
MARKER="$DATA_DIR/.railway-initialised"
HEALTH_PID=""
if [[ ! -f "$MARKER" ]]; then
  # First boot only: the initial migrations take a few minutes, longer than some
  # health-check windows. Answer the health path (and nothing else) meanwhile.
  # Later boots skip this, so a redeploy only goes live once Baserow is up.
  mkdir -p /tmp/railway-health && echo ok > /tmp/railway-health/_health
  python3 -m http.server "$RAILWAY_PORT" --bind :: --directory /tmp/railway-health \
    >/dev/null 2>&1 &
  HEALTH_PID=$!
  echo "[railway] First boot: placeholder health server on port ${RAILWAY_PORT}."
fi

echo "[railway] Running Baserow migrations before the web server starts..."
/baserow.sh backend-cmd manage locked_migrate

echo "[railway] Checking the admin account..."
/baserow.sh backend-cmd python /baserow-railway/seed_admin.py
touch "$MARKER"

if [[ -n "$HEALTH_PID" ]]; then
  kill "$HEALTH_PID" 2>/dev/null || true
  wait "$HEALTH_PID" 2>/dev/null || true
fi

echo "[railway] Starting Baserow on port ${RAILWAY_PORT}..."
exec /baserow.sh start
