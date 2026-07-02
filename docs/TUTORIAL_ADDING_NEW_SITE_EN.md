# Tutorial: Adding a New WordPress Site to Your Server (Nginx + PHP-FPM per user + MySQL)

This tutorial is written for your current server model:

- Ubuntu
- Nginx (single config file, e.g. `/etc/nginx/sites-enabled/wordpress-sites`)
- PHP 8.4 FPM, separate socket per site/user
- WordPress in `/var/www/DOMAIN_NAME/public_html`
- SQL backups in `/home/ubuntu/Dokumenty/d3thecamels/MsQl`
- WSMS for validation (`wp-cli-validator`, `wp-fleet`)

Goal: add a new ready-to-run site correctly and repeatably, without guessing.

## 1. Starting Variables (fill in once)

Example (replace values):

```
DOMAIN="anitahoppephotography.com"
WWW_DOMAIN="www.anitahoppephotography.com"
SITE_USER="anitahoppephotography"
SITE_ROOT="/var/www/anitahoppephotography.com/public_html"
PHP_VER="8.4"
PHP_POOL="/etc/php/8.4/fpm/pool.d/anitahoppephotography.com.conf"
PHP_SOCK="/run/php/php8.4-fpm-anitahoppephotography.com.sock"
DB_NAME="anitahoppephotography_db"
DB_USER="anitahoppephotography"
DB_PASS="ksj*ue)js-&sns"
SQL_DUMP="/home/ubuntu/Dokumenty/d3thecamels/MsQl/file.sql"
```

## 2. Precheck (before making any changes)

Check if the site directory exists:

```bash
ls -la /var/www/anitahoppephotography.com/public_html
```

Check if WordPress is present:

```bash
ls -la /var/www/anitahoppephotography.com/public_html | head -20
```

Check if the SQL dump exists (if importing an existing database):

```bash
ls -la /home/ubuntu/Dokumenty/d3thecamels/MsQl
```

## 3. System User and Home Directory

If the user does not exist:

```bash
sudo useradd -m -d /home/anitahoppephotography.com -s /usr/sbin/nologin anitahoppephotography.com
```

Prepare WP-CLI cache:

```bash
sudo install -d -m 755 -o anitahoppephotography.com -g anitahoppephotography.com /home/anitahoppephotography.com/.wp-cli/cache
```

## 4. Site File Permissions

```bash
sudo chown -R newdomain:newdomain /var/www/anitahoppephotography.com
sudo find /var/www/anitahoppephotography.com -type d -exec chmod 755 {} \;
sudo find /var/www/anitahoppephotography.com -type f -exec chmod 644 {} \;
sudo chmod 640 /var/www/anitahoppephotography.com/public_html/wp-config.php 2>/dev/null || true
```

## 5. PHP-FPM Pool (dedicated socket)

Create pool file:

```bash
sudo tee /etc/php/8.4/fpm/pool.d/anitahoppephotography.com.conf > /dev/null << 'EOF'
[anitahoppephotography.com]
user = anitahoppephotography.com
group = anitahoppephotography.com
listen = /run/php/php8.4-fpm-anitahoppephotography.com.sock
listen.owner = www-data
listen.group = www-data
listen.mode = 0660

pm = dynamic
pm.max_children = 5
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3

php_admin_value[disable_functions] = exec,passthru,shell_exec,system
php_admin_flag[allow_url_fopen] = off
EOF
```

Validate and reload:

```bash
sudo php-fpm8.4 -t
sudo systemctl reload php8.4-fpm
ls -la /run/php/php8.4-fpm-anitahoppephotography.com.sock
```

## 6. Nginx: Add/Edit Domain Block

**Important:** `fastcgi_pass` is NOT a shell command. It is a line inside the Nginx config file.

In the `server` block for the domain, set:

```nginx
root /var/www/anitahoppephotography.com/public_html;

location ~ \.php$ {
    include snippets/fastcgi-php.conf;
    fastcgi_pass unix:/run/php/php8.4-fpm-anitahoppephotography.com.sock;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    include fastcgi_params;
}
```

After editing:

```bash
sudo nginx -t
sudo systemctl reload nginx
```

## 7. MySQL: Database and User (must run as MySQL root)

Enter MySQL:

```bash
sudo mysql -u root -p
```

Inside `mysql>` run:

```sql
CREATE DATABASE anitahoppephotography_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'anitahoppephotography'@'localhost' IDENTIFIED BY 'SET_STRONG_PASSWORD_HERE';
GRANT ALL PRIVILEGES ON anitahoppephotography_db.* TO 'anitahoppephotography'@'localhost';
FLUSH PRIVILEGES;
exit
```

## 8. SQL Import (safest from shell, not from mysql prompt)

Correct import:

```bash
mysql -u root -p newdomain_db < /home/ubuntu/Dokumenty/d3thecamels/MsQl/file.sql
```

Or with sudo:

```bash
sudo mysql -u root -p newdomain_db < /home/ubuntu/Dokumenty/d3thecamels/MsQl/file.sql
```

Quick table check:

```bash
mysql -u root -p -e "SHOW TABLES FROM newdomain_db;" | head -20
```

## 9. Update wp-config.php

Backup first:

```bash
sudo cp /var/www/newdomain.com/public_html/wp-config.php \
  /var/www/newdomain.com/public_html/wp-config.php.bak.$(date +%Y%m%d-%H%M%S)
```

Then replace DB_* values:

```bash
sudo sed -i "s/define( *'DB_NAME'.*/define( 'DB_NAME', 'newdomain_db' );/" /var/www/newdomain.com/public_html/wp-config.php
sudo sed -i "s/define( *'DB_USER'.*/define( 'DB_USER', 'newdomain' );/" /var/www/newdomain.com/public_html/wp-config.php
sudo sed -i "s/define( *'DB_PASSWORD'.*/define( 'DB_PASSWORD', 'SET_STRONG_PASSWORD_HERE' );/" /var/www/newdomain.com/public_html/wp-config.php
sudo sed -i "s/define( *'DB_HOST'.*/define( 'DB_HOST', 'localhost' );/" /var/www/newdomain.com/public_html/wp-config.php
```

## 10. WP-CLI Site Test

```bash
sudo -u newdomain wp --path=/var/www/newdomain.com/public_html core version
sudo -u newdomain wp --path=/var/www/newdomain.com/public_html option get home
```

If URLs are stale after domain migration:

```bash
sudo -u newdomain wp --path=/var/www/newdomain.com/public_html \
  search-replace "old-domain.com" "newdomain.com" --skip-columns=guid --all-tables
```

## 11. DNS and SSL (last step)

Only when DNS points to this server:

```bash
sudo certbot --nginx -d newdomain.com -d www.newdomain.com
```

## 12. MySQL: Rotate Weak Passwords

If DB passwords are too simple, rotate them immediately after migration.

1. Generate a strong password:

```bash
openssl rand -base64 24
```

2. Change the DB user password (as MySQL root):

```bash
sudo mysql -u root -p
```

In `mysql>`:

```sql
ALTER USER 'newdomain'@'localhost' IDENTIFIED BY 'NEW_VERY_STRONG_PASSWORD';
FLUSH PRIVILEGES;
exit
```

3. Update wp-config.php:

```bash
sudo sed -i "s/define( *'DB_PASSWORD'.*/define( 'DB_PASSWORD', 'NEW_VERY_STRONG_PASSWORD' );/" /var/www/newdomain.com/public_html/wp-config.php
```

4. Secure wp-config.php permissions:

```bash
sudo chmod 640 /var/www/newdomain.com/public_html/wp-config.php
sudo chown newdomain:newdomain /var/www/newdomain.com/public_html/wp-config.php
```

5. Quick test after password change:

```bash
sudo -u newdomain wp --path=/var/www/newdomain.com/public_html db check
sudo -u newdomain wp --path=/var/www/newdomain.com/public_html option get home
```

Bulk rotation example:

```bash
sudo mysql -u root -p << 'EOF'
ALTER USER 'mindreflection'@'localhost' IDENTIFIED BY 'STRONG_PASSWORD_1';
ALTER USER 'superphotocam'@'localhost' IDENTIFIED BY 'STRONG_PASSWORD_2';
ALTER USER 'wedzarnicze'@'localhost' IDENTIFIED BY 'STRONG_PASSWORD_3';
FLUSH PRIVILEGES;
EOF
```

After this, update `DB_PASSWORD` in each site's `wp-config.php`.

## 13. Final Validation

```bash
sudo nginx -t && systemctl is-active nginx
sudo php-fpm8.4 -t && systemctl is-active php8.4-fpm
wp-cli-validator
wp-fleet
```

## 14. WSMS Integration (so it sees the new site)

Make sure the new domain is in `SITES` in `~/scripts/wsms-config.sh`, format:

```
newdomain.com:/var/www/newdomain.com/public_html:newdomain
```

Then:

```bash
source ~/scripts/wsms-config.sh
wp-cli-validator
wp-fleet
```

## Common Errors and Quick Fixes

| Error | Cause | Fix |
|-------|-------|-----|
| `fastcgi_pass: command not found` | Typed in shell instead of Nginx config file | Edit Nginx config, then `nginx -t` and reload |
| `Access denied` on `CREATE DATABASE` / `CREATE USER` | Logged into MySQL as a WP user, not root | `sudo mysql -u root -p` |
| `ERROR 1046 No database selected` during `SOURCE` | `SOURCE` run without `USE db` or wrong import method | Import from shell: `mysql -u root -p DB_NAME < file.sql` |
| `SOURCE ~/...` looks in `/root/...` | `~` resolves differently under sudo in mysql | Always use full path, e.g. `/home/ubuntu/...` |
| Shell command typed inside `mysql>` | Mixed up contexts | Exit mysql with `exit`, run command in shell |
| `Access denied (1044/1227)` on `GRANT` / `FLUSH` | Logged in as WP user, not MySQL admin | Exit and reconnect: `sudo mysql -u root -p` |

## Practical Case: Root Cause and Resolution

**Problem encountered:**
- Logged into MySQL as WP user (e.g. `mindrefl_xiwg1`) → errors on `CREATE DATABASE`, `GRANT`, `FLUSH`
- Import failed because shell commands were pasted into `mysql>`
- `SOURCE ~/...` tried to read from `/root/...` instead of `/home/ubuntu/...`

**Resolution:**
1. Exit mysql with `exit`
2. Log in as MySQL root: `sudo mysql -u root -p`
3. Create databases and users from root account
4. Import SQL using one of two correct methods:
   - From shell: `sudo mysql -u root -p DB_NAME < /home/ubuntu/.../file.sql`
   - Inside mysql: `SOURCE /home/ubuntu/.../file.sql;`
5. Verify tables: `SHOW TABLES FROM db_name;`

Quick path sanity check:

```bash
readlink -f ~/Dokumenty/d3thecamels/MsQl/
# should return: /home/ubuntu/Dokumenty/d3thecamels/MsQl
```

## Quick Checklist

- [ ] Linux user created with `/home/user/.wp-cli/cache`
- [ ] File ownership: `user:user`
- [ ] PHP-FPM pool created and socket exists
- [ ] Nginx block has correct `fastcgi_pass` to new socket
- [ ] DB and DB user created as MySQL root
- [ ] SQL imported into correct database
- [ ] `wp-config.php` has new `DB_*` credentials
- [ ] WP-CLI works as site user
- [ ] Nginx and php-fpm active
- [ ] `SITES` updated, `wp-fleet` and `wp-cli-validator` show green
