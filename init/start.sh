#!/bin/sh

# handle htpassword
handle-htpassword-opt.sh
# starting memory caching, fastcgi process manager and cron
(service memcached start || memcached) && \
(service php8.2-fpm start || php-8.2-fpm) && \
service cron start && \
# initialization script
mediawiki-init.sh


echo "Starting…"
exec "$@"
