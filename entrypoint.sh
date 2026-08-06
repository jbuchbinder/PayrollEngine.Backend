#!/bin/bash
# PE PostgreSQL init: create stored procedures if they don't exist
# Runs before the .NET application starts.

PGHOST="${PGHOST:-payroll-postgres}"
PGPORT="${PGPORT:-5432}"
PGUSER="${PGUSER:-payroll}"
PGPASSWORD="${PGPASSWORD:-PayrollStrongPass789}"
PGDATABASE="${PGDATABASE:-PayrollEngine}"

export PGPASSWORD

echo "PE startup: ensuring stored procedures exist..."

for f in /app/stored-procedures/*.pg.sql; do
  if [ -f "$f" ]; then
    psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" -f "$f" -q 2>/dev/null || true
  fi
done

echo "PE startup: done. Starting application..."
exec dotnet PayrollEngine.Backend.Server.dll
