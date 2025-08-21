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

# Fix ownership and permissions for host-mounted volume
echo "Fixing permissions..."
# Give apache ownership of all app files
chown -R apache:apache $APP_DIR/public $APP_DIR/storage $APP_DIR/resources $APP_DIR/routes $APP_DIR/config $APP_DIR/database $APP_DIR/bootstrap $APP_DIR/bootstrap/cache
chmod -R 755 $APP_DIR $APP_DIR/storage $APP_DIR/bootstrap/cache

# Update .env with correct environment variables
echo "Updating .env with database and Redis settings..."
sed -i "s|DB_CONNECTION=.*|DB_CONNECTION=mysql|" .env
sed -i "s|DB_HOST=.*|DB_HOST=${DB_HOST}|" .env
sed -i "s|DB_PORT=.*|DB_PORT=${DB_PORT}|" .env
sed -i "s|DB_DATABASE=.*|DB_DATABASE=${DB_DATABASE}|" .env
sed -i "s|DB_USERNAME=.*|DB_USERNAME=${DB_USERNAME}|" .env
sed -i "s|DB_PASSWORD=.*|DB_PASSWORD=${DB_PASSWORD}|" .env
sed -i "s|REDIS_HOST=.*|REDIS_HOST=${REDIS_HOST}|" .env
sed -i "s|REDIS_PORT=.*|REDIS_PORT=${REDIS_PORT}|" .env

# Wait for MySQL before migrations
echo "Waiting for MySQL..."
until php -r "
try {
    new PDO('mysql:host=${DB_HOST};dbname=${DB_DATABASE}', '${DB_USERNAME}', '${DB_PASSWORD}');
    exit(0);
} catch (Exception \$e) {
    exit(1);
}" >/dev/null 2>&1; do
    sleep 2
done
echo "MySQL is up!"

# Run migrations
echo "Running migrations..."
php artisan migrate --force || true

# Start Apache + PHP-FPM
exec /usr/bin/supervisord -c /etc/supervisord.conf
