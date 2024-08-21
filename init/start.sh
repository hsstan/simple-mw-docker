#!/bin/sh

# handle htpassword
handle-htpassword-opt.sh
# starting memory caching & fastcgi process manager
service memcached start && \
service php8.2-fpm start && \
# initialization script
mediawiki-init.sh && \
service cron start

echo "Starting…"
exec "$@"
