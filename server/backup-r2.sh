#!/bin/bash
# SchoolSafe — Backup automatique vers Cloudflare R2
# Prérequis : rclone configuré avec un remote nommé "r2"
# Config rclone : rclone config  →  New remote → S3 → Cloudflare R2
#
# Variables R2 à renseigner dans rclone config :
#   Access Key ID     : depuis Cloudflare Dashboard > R2 > Manage API Tokens
#   Secret Access Key : idem
#   Endpoint          : https://<ACCOUNT_ID>.r2.cloudflarestorage.com
#   Bucket            : schoolsafe-backups (à créer dans le dashboard R2)

set -euo pipefail

PB_DATA="__PB_DATA__"
BUCKET="r2:schoolsafe-backups"
BACKUP_DIR="/tmp/schoolsafe-backup-$$"
DATE=$(date +%Y-%m-%d_%H-%M)
BACKUP_FILE="$BACKUP_DIR/schoolsafe_$DATE.tar.gz.enc"
LOG_TAG="[SchoolSafe Backup]"

# ── Clé de chiffrement ─────────────────────────────────────────────────────
# Stocker dans /etc/schoolsafe/backup.key (chmod 600)
KEY_FILE="/etc/schoolsafe/backup.key"

cleanup() { rm -rf "$BACKUP_DIR"; }
trap cleanup EXIT

echo "$LOG_TAG Début backup $DATE"

# ── Vérifications ──────────────────────────────────────────────────────────
if ! command -v rclone &>/dev/null; then
  echo "$LOG_TAG ERREUR: rclone non installé" >&2; exit 1
fi
if ! rclone listremotes | grep -q "^r2:"; then
  echo "$LOG_TAG ERREUR: remote 'r2' non configuré — exécuter: rclone config" >&2; exit 1
fi

mkdir -p "$BACKUP_DIR"

# ── Snapshot SQLite cohérent ───────────────────────────────────────────────
DB_FILE="$PB_DATA/data.db"
SNAPSHOT="$BACKUP_DIR/data.db.snapshot"
if [ -f "$DB_FILE" ]; then
  sqlite3 "$DB_FILE" ".backup '$SNAPSHOT'"
  echo "$LOG_TAG Snapshot SQLite créé ✓"
else
  echo "$LOG_TAG AVERTISSEMENT: $DB_FILE introuvable"
fi

# ── Archive complète (DB + uploads + migrations) ──────────────────────────
tar czf "$BACKUP_DIR/data.tar.gz" \
  -C "$(dirname "$PB_DATA")" \
  --exclude="$(basename "$PB_DATA")/logs" \
  "$(basename "$PB_DATA")" \
  2>/dev/null || true

# ── Chiffrement AES-256 ───────────────────────────────────────────────────
if [ -f "$KEY_FILE" ]; then
  openssl enc -aes-256-cbc -salt -pbkdf2 -iter 100000 \
    -in "$BACKUP_DIR/data.tar.gz" \
    -out "$BACKUP_FILE" \
    -pass file:"$KEY_FILE"
  echo "$LOG_TAG Archive chiffrée ✓"
else
  # Pas de clé → backup non chiffré (avertissement)
  cp "$BACKUP_DIR/data.tar.gz" "$BACKUP_DIR/schoolsafe_$DATE.tar.gz"
  BACKUP_FILE="$BACKUP_DIR/schoolsafe_$DATE.tar.gz"
  echo "$LOG_TAG AVERTISSEMENT: backup non chiffré (créer $KEY_FILE)"
fi

# ── Upload vers R2 ────────────────────────────────────────────────────────
REMOTE_PATH="$BUCKET/daily/schoolsafe_$DATE$([ -f "$KEY_FILE" ] && echo '.tar.gz.enc' || echo '.tar.gz')"
rclone copy "$BACKUP_FILE" "$BUCKET/daily/" \
  --s3-no-check-bucket \
  --retries 3 \
  --low-level-retries 3
echo "$LOG_TAG Upload R2 terminé ✓ → $BUCKET/daily/"

# ── Rotation : garder 30 jours de backups daily ───────────────────────────
CUTOFF=$(date -d '30 days ago' +%Y-%m-%d 2>/dev/null || date -v-30d +%Y-%m-%d)
rclone delete "$BUCKET/daily/" \
  --min-age 30d \
  --s3-no-check-bucket 2>/dev/null || true

# ── Backup hebdomadaire (le dimanche) ────────────────────────────────────
if [ "$(date +%u)" = "7" ]; then
  rclone copy "$BACKUP_FILE" "$BUCKET/weekly/" --s3-no-check-bucket
  rclone delete "$BUCKET/weekly/" --min-age 90d --s3-no-check-bucket 2>/dev/null || true
  echo "$LOG_TAG Backup hebdomadaire envoyé ✓"
fi

# ── Taille du backup ─────────────────────────────────────────────────────
SIZE=$(du -sh "$BACKUP_FILE" 2>/dev/null | cut -f1)
echo "$LOG_TAG Backup terminé — taille: $SIZE — $(date)"
