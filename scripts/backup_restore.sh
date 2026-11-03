#!/usr/bin/env bash
# ==============================================================================
# ALDEEB MALL: PER-BRANCH DATABASE BACKUP & RESTORE UTILITY
# ==============================================================================
# Usage:
#   ./scripts/backup_restore.sh backup [branch_code]
#   ./scripts/backup_restore.sh restore [dump_file] [target_branch_code]
# ==============================================================================

set -euo pipefail

DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_USER="${POSTGRES_USER:-aldeeb_admin}"
DB_NAME="${POSTGRES_DB:-aldeeb_mall_prod}"
BACKUP_DIR="${BACKUP_DIR:-./backups}"

mkdir -p "${BACKUP_DIR}"

ACTION="${1:-help}"

case "${ACTION}" in
  backup)
    BRANCH_CODE="${2:-all}"
    TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
    
    if [ "${BRANCH_CODE}" = "all" ]; then
      TARGET_FILE="${BACKUP_DIR}/aldeeb_mall_full_${TIMESTAMP}.dump"
      echo "📦 Backing up entire database [${DB_NAME}] to ${TARGET_FILE}..."
      PGPASSWORD="${POSTGRES_PASSWORD:-}" pg_dump -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -F c -b -v -f "${TARGET_FILE}" "${DB_NAME}"
    else
      SCHEMA_NAME="branch_${BRANCH_CODE}"
      TARGET_FILE="${BACKUP_DIR}/branch_${BRANCH_CODE}_${TIMESTAMP}.dump"
      echo "🏬 Backing up isolated branch schema [${SCHEMA_NAME}] to ${TARGET_FILE}..."
      PGPASSWORD="${POSTGRES_PASSWORD:-}" pg_dump -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -n "${SCHEMA_NAME}" -F c -b -v -f "${TARGET_FILE}" "${DB_NAME}"
    fi
    echo "✅ Backup completed successfully: ${TARGET_FILE}"
    ;;

  restore)
    DUMP_FILE="${2:-}"
    if [ -z "${DUMP_FILE}" ] || [ ! -f "${DUMP_FILE}" ]; then
      echo "❌ Error: Please provide a valid dump file path."
      exit 1
    fi
    echo "⚠️ RESTORING FROM ${DUMP_FILE} TO [${DB_NAME}]..."
    PGPASSWORD="${POSTGRES_PASSWORD:-}" pg_restore -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" --clean --if-exists -v "${DUMP_FILE}"
    echo "✅ Restore completed successfully."
    ;;

  *)
    echo "Usage:"
    echo "  $0 backup [branch_code | all]"
    echo "  $0 restore <path_to_dump_file>"
    exit 1
    ;;
esac
