#!/bin/bash
# PE PostgreSQL init: create stored procedures before .NET app starts.
# Parses ConnectionStrings__PayrollDatabaseConnection for psql credentials.

set -e

# Parse .NET connection string: Host=HOST;Port=PORT;Database=DB;Username=USER;Password=PASS
CONN_STR="${ConnectionStrings__PayrollDatabaseConnection:-}"
if [ -z "$CONN_STR" ]; then
  echo "PE startup: no ConnectionStrings__PayrollDatabaseConnection set, skipping stored procedures"
  exec dotnet PayrollEngine.Backend.Server.dll
fi

# Extract values from semicolon-delimited connection string (trim whitespace)
extract() {
  echo "$CONN_STR" | tr ';' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -i "^$1=" | cut -d= -f2- | head -1
}

PGHOST="$(extract Host)"
PGPORT="$(extract Port)"
PGDATABASE="$(extract Database)"
PGUSER="$(extract Username)"
PGPASSWORD="$(extract Password)"

PGHOST="${PGHOST:-payroll-postgres}"
PGPORT="${PGPORT:-5432}"
PGUSER="${PGUSER:-payroll}"
PGPASSWORD="${PGPASSWORD:-PayrollStrongPass789}"
PGDATABASE="${PGDATABASE:-PayrollEngine}"

export PGPASSWORD

echo "PE startup: ensuring stored procedures exist on ${PGHOST}:${PGPORT}/${PGDATABASE}..."

LOADED=0
FAILED=0
for f in /app/stored-procedures/*.pg.sql; do
  if [ -f "$f" ]; then
    if psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" -v ON_ERROR_STOP=1 -f "$f" > /dev/null 2>&1; then
      LOADED=$((LOADED + 1))
    else
      echo "  WARNING: failed to load $(basename $f) — retrying with ON_ERROR_STOP=0..."
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
exec dotnet PayrollEngine.Backend.Server.dll
