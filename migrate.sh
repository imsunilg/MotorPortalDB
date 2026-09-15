#!/usr/bin/env bash
# Runs 00 -> 06 in order against a local/target Postgres instance.
# Configure via env vars: PGHOST, PGPORT, PGUSER, PGPASSWORD, PSQL (path to psql if not on PATH).
set -euo pipefail

PGHOST="${PGHOST:-localhost}"
PGPORT="${PGPORT:-5432}"
PGUSER="${PGUSER:-postgres}"
PGPASSWORD="${PGPASSWORD:-postgres}"
PSQL="${PSQL:-psql}"
export PGPASSWORD

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> 00_create_database.sql (against 'postgres' db)"
"$PSQL" -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d postgres -v ON_ERROR_STOP=1 -f "$SCRIPT_DIR/scripts/00_create_database.sql"

echo "==> 01_create_schema.sql"
"$PSQL" -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d motorportal -v ON_ERROR_STOP=1 -f "$SCRIPT_DIR/scripts/01_create_schema.sql"

echo "==> 02_tables/*.sql"
for f in "$SCRIPT_DIR"/scripts/02_tables/*.sql; do
    echo "    $f"
    "$PSQL" -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d motorportal -v ON_ERROR_STOP=1 -f "$f"
done

echo "==> 03_constraints_indexes.sql"
"$PSQL" -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d motorportal -v ON_ERROR_STOP=1 -f "$SCRIPT_DIR/scripts/03_constraints_indexes.sql"

echo "==> 04_functions/*.sql"
for f in "$SCRIPT_DIR"/scripts/04_functions/*.sql; do
    echo "    $f"
    "$PSQL" -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d motorportal -v ON_ERROR_STOP=1 -f "$f"
done

echo "==> 05_views/*.sql"
for f in "$SCRIPT_DIR"/scripts/05_views/*.sql; do
    echo "    $f"
    "$PSQL" -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d motorportal -v ON_ERROR_STOP=1 -f "$f"
done

echo "==> 06_seed_data.sql"
"$PSQL" -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d motorportal -v ON_ERROR_STOP=1 -f "$SCRIPT_DIR/scripts/06_seed_data.sql"

echo "==> Migration complete."
