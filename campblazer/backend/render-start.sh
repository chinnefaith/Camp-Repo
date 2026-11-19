#!/usr/bin/env bash
# Start command for Render (free plan has no pre-deploy step, so setup runs here).
# Every command below is safe to repeat on each restart.
set -e

python manage.py makemigrations accounts destinations bookings --noinput   # no-op if migrations are committed
python manage.py migrate --noinput
python manage.py seed_destinations   # the 18 approved destinations
python manage.py seed_photos --reset # re-link photos to PHOTO_BASE_URL on every start (free plan wipes uploads anyway)
python manage.py seed_demo           # [DEMO] services + accounts (password = DEMO_PASSWORD env var)

export GUNICORN_BIND="0.0.0.0:${PORT:-8000}"
exec gunicorn -c gunicorn.conf.py config.asgi:application
