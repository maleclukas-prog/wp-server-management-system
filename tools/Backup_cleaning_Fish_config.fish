# Backup
cp ~/.config/fish/config.fish ~/.config/fish/config.fish.backup.(date +%Y%m%d)

# Wyczyść Fish config
sed -i '/# WORDPRESS MANAGEMENT SYSTEM/d' ~/.config/fish/config.fish
sed -i '/# WSMS PRO/d' ~/.config/fish/config.fish
sed -i '/set -gx SCRIPTS_DIR/d' ~/.config/fish/config.fish
sed -i '/^alias wp-/d' ~/.config/fish/config.fish
sed -i '/^alias backup-/d' ~/.config/fish/config.fish
sed -i '/^alias mysql-backup/d' ~/.config/fish/config.fish
sed -i '/^alias nas-sync/d' ~/.config/fish/config.fish
sed -i '/^alias clamav-/d' ~/.config/fish/config.fish
sed -i '/^function wp-status/,/^end/d' ~/.config/fish/config.fish
sed -i '/^function wp-update-safe/,/^end/d' ~/.config/fish/config.fish

echo "✅ Fish config cleaned"
