#!/bin/sh
# docker-entrypoint.sh — first-boot superuser seeding for PocketBase on Railway.
#
# Behavior:
#   - Idempotent: creates the first superuser ONLY when /pb_data/data.db is absent
#     (i.e. fresh volume). If a superuser already exists, this script leaves it alone
#     so subsequent deploys never overwrite credentials.
#   - Skips seeding entirely if ADMIN_USER or ADMIN_PASSWORD is unset, deferring to
#     the in-app UI at /_/ for the user to create the first admin interactively.
#   - Validates that ADMIN_PASSWORD is at least 5 characters (PocketBase minimum).
#
# After seeding (or skipping), it exec's "$@" (the CMD supplied by the Dockerfile).
set -eu

PB_DATA="${PB_DATA:-/pb_data}"

# Ensure target directory exists (volume may be freshly mounted and empty)
mkdir -p "$PB_DATA"

if [ ! -f "$PB_DATA/data.db" ] && [ -n "${ADMIN_USER:-}" ] && [ -n "${ADMIN_PASSWORD:-}" ]; then
  if [ "${#ADMIN_PASSWORD}" -lt 5 ]; then
    echo "[entrypoint] ERROR: ADMIN_PASSWORD must be at least 5 characters (got ${#ADMIN_PASSWORD})." >&2
    exit 1
  fi
  echo "[entrypoint] Empty data directory detected at $PB_DATA — seeding first superuser: $ADMIN_USER"
  if ! pocketbase superuser create "$ADMIN_USER" "$ADMIN_PASSWORD" --dir="$PB_DATA"; then
    echo "[entrypoint] FATAL: pocketbase superuser create failed. Container will exit." >&2
    exit 1
  fi
  echo "[entrypoint] First superuser seeded successfully."
elif [ -f "$PB_DATA/data.db" ]; then
  if [ -n "${ADMIN_USER:-}" ] || [ -n "${ADMIN_PASSWORD:-}" ]; then
    echo "[entrypoint] Note: existing data.db found — first superuser already provisioned. Skipping ADMIN_USER/ADMIN_PASSWORD seeding to preserve existing credentials."
  fi
fi

exec "$@"
