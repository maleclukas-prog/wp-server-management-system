# WSMS PRO Case Studies

This document contains real operational incidents handled with WSMS PRO.

## Case 01 - Restore after snapshot: photographerwithawalker.com (HTTP 404)

### Context
- Environment: Ubuntu VPS with 6 WordPress sites.
- Trigger: VPS restored from a snapshot created 2 days earlier.
- Symptom: `photographerwithawalker.com` returned HTTP 404 while other sites were healthy.

### Goal
Restore service quickly without manual edits in Nginx config files.

### Timeline and Actions
1. Fleet check

```bash
for site in photographerwithawalker polskieokna mindreflection superphotocam wedzarniczebractwo whiteeaglesmokehouse; do
  curl -I https://$site.com 2>/dev/null | head -1
done
```

Result: only `photographerwithawalker.com` returned HTTP 404.

2. Application-level validation

```bash
wp-cli-validator
```

Result: all sites passed WP-CLI checks, so WordPress/PHP/DB stack was healthy.

3. Permission and ACL repair

```bash
http200-fix
```

Result included:
- `wp-config.php` secured to `640`
- ACL set for admin user
- site permissions reset (`755` dirs, `644` files)

4. Nginx verification and reload

```bash
sudo nginx -T | sed -n '/photographerwithawalker/,+20p'
sudo systemctl reload nginx
```

Result: config was valid; reload completed without errors.

5. Final check

```bash
curl -I https://photographerwithawalker.com
```

Result: `HTTP/1.1 301 Moved Permanently` to `https://www.photographerwithawalker.com/`.

### Outcome
- Service restored in a few minutes.
- Recovery completed with standard WSMS workflow.
- No direct edits to live Nginx site blocks were required.

### Commands Used
- `wp-status`
- `wp-cli-validator`
- `http200-fix`
- `sudo nginx -T`
- `sudo systemctl reload nginx`
