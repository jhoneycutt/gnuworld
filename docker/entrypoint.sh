#!/bin/bash
set -euo pipefail

CONF_DIR=/app/conf
BIN_DIR=/app/bin

PGHOST=localhost
PGPORT=5432
PGUSER=postgres

echo "Waiting for PostgreSQL..."
until pg_isready -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -q 2>/dev/null; do
    sleep 2
done
echo "PostgreSQL is ready."

init_db() {
    local dbname="$1"
    local sqldir="$2"

    if psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" \
            -lqt 2>/dev/null | cut -d'|' -f1 | grep -qw "$dbname"; then
        echo "Database '${dbname}' already exists, skipping init."
    else
        echo "Creating and initializing database '${dbname}'..."
        psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d postgres \
             -c "CREATE DATABASE \"${dbname}\" ENCODING 'SQL_ASCII' TEMPLATE template0;" >/dev/null
        for f in "${sqldir}"/*.sql; do
            echo "  applying $(basename "$f")..."
            psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$dbname" -f "$f" >/dev/null
        done
        echo "  done."
    fi
}

init_db cservice /app/sql/cservice
init_db ccontrol /app/sql/ccontrol

cp "${CONF_DIR}"/*.conf "${BIN_DIR}/"

echo "Starting gnuworld..."
exec "${BIN_DIR}/gnuworld" -c -f /app/conf/GNUWorld.conf
