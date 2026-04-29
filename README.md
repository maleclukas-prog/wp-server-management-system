# WSMS PRO - WordPress Server Management System

**Version:** 4.3 | **Status:** Production Ready | **License:** MIT

WSMS PRO automates WordPress fleet operations on Ubuntu with backup, maintenance, security scans, rollback, and centralized logging.

## What's New in v4.3

- Live console output and persistent installer logs in both installers.
- Improved installer error diagnostics with step, line, command, exit code, and log path.
- Live logging bootstrap for generated runtime scripts in `~/scripts`.
- Self-contained alias provisioning inside installers (Bash and Fish).
- Optional Fish handling with explicit warning when Fish is not installed.
- Repository and docs aligned with current installer and uninstaller names.
- Local hosts synchronization command (`wp-hosts-sync`) to map configured sites to `127.0.0.1`.
- Uninstaller `--dry-run` mode for safe preview before removal.

## Quick Start

```bash
git clone https://github.com/maleclukas-prog/wp-server-management-system.git
cd wp-server-management-system

# Configure managed sites and NAS
nano installers/install_wsms.sh

chmod +x installers/install_wsms.sh
./installers/install_wsms.sh
```

Polish installer:

```bash
chmod +x installers/install_wsms_pl.sh
./installers/install_wsms_pl.sh
```

## Runtime Layout

After installation, runtime modules are generated in:

- `~/scripts/`
- `~/logs/wsms/`
- `~/backups-lite/`
- `~/backups-full/`
- `~/backups-rollback/`
- `~/mysql-backups/`

Notable runtime commands:

- `wp-help` - complete command reference
- `wp-hosts-sync` - sync configured domains from `SITES` into `/etc/hosts` (uses sudo)
- `wp-fix-perms` - file permissions and ACL repair

## Inspect Scripts Without Running Installer

To review copy-ready runtime modules as separate files (instead of reading large installer heredocs):

```bash
bash tools/wsms-export-runtime-scripts.sh
```

Preview output is generated to:

- `scripts/runtime-preview/en/`
- `scripts/runtime-preview/pl/`

This preview is generated from installers and is git-ignored to avoid source-of-truth drift.

## Uninstall

```bash
./tools/wsms-uninstall.sh --dry-run
./tools/wsms-uninstall.sh
./tools/wsms-uninstall.sh --force
```

`--dry-run` shows planned cleanup actions without modifying files.

## Documentation

- `docs/DEPLOYMENT_GUIDE.md`
- `docs/FISH_SETUP_GUIDE.md`
- `docs/TECHNICAL_REFERENCE.md`
- `CHANGELOG.md`

## macOS and iCloud Note

When this repository is synchronized via iCloud between macOS devices, Finder metadata files may appear locally.
Repository `.gitignore` already excludes common macOS/iCloud artifacts (for example `.DS_Store`, `._*`, and `*.icloud`) to keep commits clean.
