#!/usr/bin/env bash
# ==============================================================================
# ALDEEB MALL: IDEMPOTENT MONOTONIC MIGRATION RUNNER
# ==============================================================================
# Applies all numbered SQL migrations in sequential order against the target database.
# Safe for fresh environments and existing production databases.
# ==============================================================================

set -euo pipefail

DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_USER="${POSTGRES_USER:-ahmad_alzoubi}"
DB_NAME="${POSTGRES_DB:-aldeeb_mall_prod}"
MIGRATIONS_DIR="${MIGRATIONS_DIR:-./supabase/migrations}"

export PGPASSWORD="${POSTGRES_PASSWORD:-}"

echo "🔄 [Aldeeb Mall Migrations] Connecting to ${DB_HOST}:${DB_PORT}/${DB_NAME} as ${DB_USER}..."

# 1. Initialize migration ledger table
psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -v ON_ERROR_STOP=1 -q <<EOF
CREATE TABLE IF NOT EXISTS public._schema_migrations (
    filename VARCHAR(255) PRIMARY KEY,
    applied_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);
EOF

# 2. Iterate through sorted migration files
APPLIED_COUNT=0
SKIPPED_COUNT=0

for migration_file in $(ls "${MIGRATIONS_DIR}"/*.sql | sort); do
    base_name="$(basename "${migration_file}")"
    
    # Check if already applied
    ALREADY_RUN=$(psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -t -A -c \
        "SELECT COUNT(*) FROM public._schema_migrations WHERE filename = '${base_name}';")
    
    if [ "${ALREADY_RUN}" -gt 0 ]; then
        echo "  ⏩ [SKIP] ${base_name} (already applied)"
        SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
    else
        echo "  🚀 [APPLY] ${base_name}..."
        psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -v ON_ERROR_STOP=1 -f "${migration_file}" > /dev/null
        psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -q -c \
            "INSERT INTO public._schema_migrations (filename) VALUES ('${base_name}') ON CONFLICT (filename) DO NOTHING;"
        echo "  ✅ [SUCCESS] ${base_name}"
        APPLIED_COUNT=$((APPLIED_COUNT + 1))
    fi
done

echo "🎉 [Aldeeb Mall Migrations Complete] Applied: ${APPLIED_COUNT}, Skipped: ${SKIPPED_COUNT}"
