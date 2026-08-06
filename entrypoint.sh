#!/bin/bash
# PE PostgreSQL init: create stored procedures if they don't exist
# Runs before the .NET application starts.
# Uses the same connection settings as the app (ConnectionStrings__PayrollDatabaseConnection)

set -e

PGHOST="${PGHOST:-payroll-postgres}"
PGPORT="${PGPORT:-5432}"
PGUSER="${PGUSER:-payroll}"
PGPASSWORD="${PGPASSWORD:-PayrollStrongPass789}"
PGDATABASE="${PGDATABASE:-PayrollEngine}"

# Build connection string and export PGPASSWORD
export PGPASSWORD

echo "PE startup: ensuring stored procedures exist on ${PGHOST}:${PGPORT}/${PGDATABASE}..."

LOADED=0
FAILED=0
for f in /app/stored-procedures/*.pg.sql; do
  if [ -f "$f" ]; then
    if psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" -v ON_ERROR_STOP=1 -f "$f" > /dev/null 2>&1; then
      LOADED=$((LOADED + 1))
    else
      echo "  WARNING: failed to load $(basename $f) — retrying..."
      if psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" -v ON_ERROR_STOP=0 -f "$f" > /dev/null 2>&1; then
        LOADED=$((LOADED + 1))
      else
        FAILED=$((FAILED + 1))
        echo "  ERROR: $(basename $f) failed after retry"
      fi
    fi
  fi
done

echo "PE startup: $LOADED stored procedures loaded, $FAILED failed"
echo "PE startup: starting application..."
exec dotnet PayrollEngine.Backend.Server.dll
