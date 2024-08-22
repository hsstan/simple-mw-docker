#!/bin/sh

# handle htpassword
handle-htpassword-opt.sh
# starting memory caching, fastcgi process manager and cron
service memcached start || memcached -u memcached
service php8.2-fpm start || php-fpm8.2
service cron start
# initialization script
mediawiki-init.sh

echo "Starting…"
exec "$@"