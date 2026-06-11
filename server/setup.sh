#!/bin/bash
# SchoolSafe — Setup VPS Ubuntu 22.04/24.04
# Usage: bash setup.sh yourdomain.com your@email.com
# Ex:    bash setup.sh schoolsafe.example.com admin@example.com
set -euo pipefail

DOMAIN="${1:?Usage: $0 domain.com email@example.com}"
EMAIL="${2:?Usage: $0 domain.com email@example.com}"
PB_VERSION="0.22.4"
PB_DIR="/opt/pocketbase"
PB_DATA="/var/lib/pocketbase"
PB_USER="pocketbase"

echo "=== SchoolSafe VPS Setup ==="
echo "Domain : $DOMAIN"
echo "Email  : $EMAIL"
echo ""

# ── 1. Mise à jour système ─────────────────────────────────────────────────
apt-get update -qq && apt-get upgrade -y -qq
apt-get install -y -qq \
  curl wget unzip nginx certbot python3-certbot-nginx \
  ufw fail2ban rclone sqlite3 cron

# ── 2. Firewall ────────────────────────────────────────────────────────────
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 'Nginx Full'
ufw --force enable
echo "Firewall configuré ✓"

# ── 3. Fail2ban ────────────────────────────────────────────────────────────
systemctl enable fail2ban --now
echo "Fail2ban actif ✓"

# ── 4. Utilisateur PocketBase (non-root) ───────────────────────────────────
if ! id "$PB_USER" &>/dev/null; then
  useradd --system --no-create-home --shell /usr/sbin/nologin "$PB_USER"
fi

# ── 5. Téléchargement PocketBase ───────────────────────────────────────────
mkdir -p "$PB_DIR" "$PB_DATA"
ARCH=$(uname -m); [ "$ARCH" = "x86_64" ] && ARCH="amd64" || ARCH="arm64"
PB_URL="https://github.com/pocketbase/pocketbase/releases/download/v${PB_VERSION}/pocketbase_${PB_VERSION}_linux_${ARCH}.zip"
echo "Téléchargement PocketBase v${PB_VERSION} (${ARCH})..."
wget -q "$PB_URL" -O /tmp/pb.zip
unzip -q -o /tmp/pb.zip -d "$PB_DIR"
rm /tmp/pb.zip
chmod +x "$PB_DIR/pocketbase"
chown -R "$PB_USER:$PB_USER" "$PB_DIR" "$PB_DATA"
echo "PocketBase installé ✓"

# ── 6. Service systemd ─────────────────────────────────────────────────────
cp "$(dirname "$0")/pocketbase.service" /etc/systemd/system/pocketbase.service
sed -i "s|__PB_DIR__|$PB_DIR|g; s|__PB_DATA__|$PB_DATA|g; s|__PB_USER__|$PB_USER|g" \
  /etc/systemd/system/pocketbase.service
systemctl daemon-reload
systemctl enable pocketbase
systemctl start pocketbase
sleep 2
systemctl is-active pocketbase && echo "PocketBase service actif ✓" || echo "⚠ PocketBase service check failed"

# ── 7. Nginx + SSL ─────────────────────────────────────────────────────────
cp "$(dirname "$0")/nginx.conf" /etc/nginx/sites-available/schoolsafe
sed -i "s|__DOMAIN__|$DOMAIN|g" /etc/nginx/sites-available/schoolsafe
ln -sf /etc/nginx/sites-available/schoolsafe /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx
echo "Nginx configuré ✓"

# Certificat SSL Let's Encrypt
certbot --nginx -d "$DOMAIN" --email "$EMAIL" --agree-tos --non-interactive --redirect
nginx -t && systemctl reload nginx
echo "SSL Let's Encrypt configuré ✓"

# Renouvellement automatique
echo "0 3 * * * root certbot renew --quiet --post-hook 'systemctl reload nginx'" \
  > /etc/cron.d/certbot-renew

# ── 8. Backup R2 ──────────────────────────────────────────────────────────
cp "$(dirname "$0")/backup-r2.sh" /usr/local/bin/schoolsafe-backup
chmod +x /usr/local/bin/schoolsafe-backup
sed -i "s|__PB_DATA__|$PB_DATA|g" /usr/local/bin/schoolsafe-backup

# Cron backup : tous les jours à 02:00
echo "0 2 * * * root /usr/local/bin/schoolsafe-backup >> /var/log/schoolsafe-backup.log 2>&1" \
  > /etc/cron.d/schoolsafe-backup
echo "Backup cron configuré ✓ (chaque jour à 02:00)"

# ── 9. Durcissement SSH ───────────────────────────────────────────────────
sed -i 's/^#*PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl reload ssh
echo "SSH durci (clé uniquement) ✓"

# ── Résumé ─────────────────────────────────────────────────────────────────
echo ""
echo "=== SETUP TERMINÉ ==="
echo "URL Admin PocketBase : https://$DOMAIN/_/"
echo "URL API              : https://$DOMAIN/api/"
echo "Données              : $PB_DATA"
echo ""
echo "ÉTAPES SUIVANTES :"
echo "  1. Ouvrir https://$DOMAIN/_/ et créer le compte superadmin"
echo "  2. Configurer rclone R2 : rclone config"
echo "  3. Vérifier le backup : /usr/local/bin/schoolsafe-backup"
echo ""
echo "Pour voir les logs PocketBase : journalctl -u pocketbase -f"
