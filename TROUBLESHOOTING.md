# WSMS PRO Troubleshooting

Practical playbooks for recurring incidents.

## HTTP 404 after VPS restore (single site affected)

### Typical Symptoms
- One domain returns `HTTP 404`.
- Other managed sites are still healthy.
- WP-CLI can still connect to WordPress for that site.

### Fast Path (5-10 minutes)
1. Confirm scope of outage.

```bash
for site in photographerwithawalker polskieokna mindreflection superphotocam wedzarniczebractwo whiteeaglesmokehouse; do
  curl -I https://$site.com 2>/dev/null | head -1
done
```

2. Validate WordPress stack from CLI.

```bash
wp-cli-validator
```

3. Repair permissions and ACL.

```bash
http200-fix
```

4. Validate Nginx config and reload.

```bash
sudo nginx -t
sudo systemctl reload nginx
```

5. Re-test affected site.

```bash
curl -I https://photographerwithawalker.com
```

Expected: `HTTP 301` or `HTTP 200`.

### Why this works
- Snapshot restore can reintroduce stale file ownership/mode state.
- `http200-fix` and `wp-fix-perms` restore secure defaults used by WSMS.
- Reloading Nginx applies current config state without full restart.

### If issue persists
- Check site block content with `sudo nginx -T`.
- Confirm `root` path exists and points to the expected document root.
- Confirm SSL files referenced in `ssl_certificate` paths exist.
- Re-run `wp-status` and `wp-cli-validator` to compare runtime vs web layer.

### Related Commands
- `wp-status`
- `wp-cli-validator`
- `wp-fix-perms`
- `http200-fix`
- `sudo nginx -T`
