#!/usr/bin/env bash
set -e

echo "[Entrypoint] Waiting for PostgreSQL at ${POSTGRES_HOST}:${POSTGRES_PORT:-5432}..."

while ! nc -z "${POSTGRES_HOST}" "${POSTGRES_PORT:-5432}"; do
  sleep 0.5
done

echo "[Entrypoint] PostgreSQL is online!"

echo "[Entrypoint] Applying database migrations..."
python manage.py migrate --noinput

echo "[Entrypoint] Collecting static assets..."
python manage.py collectstatic --noinput --clear || true

echo "[Entrypoint] Starting application process..."
exec "$@"
