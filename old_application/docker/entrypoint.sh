#!/bin/bash
set -e

# Ensure writable directories exist.
# chown is best-effort — it may fail on bind-mounted volumes where the host
# controls ownership, so we silence failures and fall back to chmod o+w.
for dir in /var/www/html/cache \
           /var/www/html/uploads \
           /var/www/html/uploads/logos \
           /var/www/html/uploads/sponsors; do
    mkdir -p "$dir"
    chown www-data:www-data "$dir" 2>/dev/null || chmod o+w "$dir"
done

exec "$@"
