#!/bin/sh
set -e

APP_DIR=/var/www/html

# If artisan not found → Laravel not installed
if [ ! -f "$APP_DIR/artisan" ]; then
    echo "Laravel not found. Installing latest version into $APP_DIR..."
    composer create-project laravel/laravel $APP_DIR
    echo "Laravel installed."
else
    echo "Laravel already present. Skipping installation."
fi

cd $APP_DIR

# Ensure .env exists
if [ ! -f "$APP_DIR/.env" ]; then
    echo ".env not found, copying from .env.example"
    cp .env.example .env
fi

# Generate app key if not set
if ! grep -q "APP_KEY=base64:" .env; then
    php artisan key:generate
fi

# Wait for MySQL before migrations
echo "Waiting for MySQL..."
until mysqladmin ping -h"$DB_HOST" -u"$DB_USERNAME" -p"$DB_PASSWORD" --silent; do
    sleep 2
done
echo "MySQL is up!"

# Run migrations
echo "Running migrations..."
php artisan migrate --force || true

# Start Apache + PHP-FPM
exec /usr/bin/supervisord -c /etc/supervisord.conf
