# WSMS PRO - WordPress Server Management System

**Version:** 4.3 | **Status:** Production Ready | **License:** MIT

WSMS PRO automates WordPress fleet operations on Ubuntu with backup, maintenance, security scans, rollback, and centralized logging.

Important notes:

- For full operation of all commands listed by `wp-help`, install antivirus packages used by WSMS security modules (ClamAV).
- This is an author-driven personal server management system and includes operational solutions used in the author's own environment.

Deployment status:

- The system was developed and tested on AWS EC2.
- It is currently running in production on a physical Ubuntu server.
- An AMI image is in progress to simplify deployment for other users.

## Architecture (Important)

WSMS PRO is installer-centric.

- Primary source of truth: `installers/install_wsms.sh` and `installers/install_wsms_pl.sh`
- Runtime scripts in `~/scripts/` are generated during installation
- Repository preview scripts in `scripts/runtime-preview/` are generated from installer deploy blocks

This means you can work on a single extracted script for convenience, but final canonical logic still lives in installer deploy blocks.

## What's New in v4.3

- Live console output and persistent installer logs in both installers.
- Improved installer error diagnostics with step, line, command, exit code, and log path.
- Live logging bootstrap for generated runtime scripts in `~/scripts`.
- Self-contained alias provisioning inside installers (Bash and Fish).
- Optional Fish handling with explicit warning when Fish is not installed.
- Repository and docs aligned with current installer and uninstaller names.
- Local hosts synchronization command (`wp-hosts-sync`) to map configured sites to `127.0.0.1`.
- Uninstaller `--dry-run` mode for safe preview before removal.
- Uninstaller now removes legacy v4.2 shell blocks even when no marker delimiters are present.
- Granular update modes in maintenance engine: `site`, `plugin`, `theme`.
- Emergency retention now also prunes rollback snapshots (keeps latest 2 per site).
- Runtime exporter supports selective extraction with `--only`.
- Added regression test for legacy uninstaller cleanup.

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
- `wp-update-site <site>` - update one site (core + all plugins/themes)
- `wp-update-plugin <site> <plugin>` - update one plugin on one site
- `wp-update-theme <site> <theme>` - update one theme on one site

## Inspect Scripts Without Running Installer

To review copy-ready runtime modules as separate files (instead of reading large installer heredocs):

```bash
bash tools/wsms-export-runtime-scripts.sh
```

To extract only selected modules:

```bash
bash tools/wsms-export-runtime-scripts.sh --only wp-automated-maintenance-engine.sh,wp-smart-retention-manager.sh,wp-help.sh
```

Preview output is generated to:

- `scripts/runtime-preview/en/`
- `scripts/runtime-preview/pl/`

This preview is generated from installers and should be regenerated whenever installer deploy blocks change.

### Should `scripts/runtime-preview` be synchronized in Git?

Short answer: optional, not mandatory.

- For beginner users: no impact (they run installer only).
- For advanced users: they can export locally at any time.
- For maintainers/reviewers: committing refreshed preview files can help code review of single modules.

Recommended policy:

- Keep installers as the only source of truth.
- Treat `scripts/runtime-preview/` as generated review artifacts.
- Synchronize preview files in commits when they improve review clarity (for example larger module refactors or release preparation).
- It is acceptable to skip preview synchronization for small internal edits if CI/tests pass and installers are updated.

## Edit One Script Workflow (EN + PL)

If you want to modify only one module (for example `wp-smart-retention-manager.sh`):

1. Edit both language variants in installers:
	- `installers/install_wsms.sh` (English)
	- `installers/install_wsms_pl.sh` (Polish)
2. Regenerate preview files:

```bash
bash tools/wsms-export-runtime-scripts.sh --only wp-smart-retention-manager.sh
```

3. Review extracted outputs:
	- `scripts/runtime-preview/en/wp-smart-retention-manager.sh`
	- `scripts/runtime-preview/pl/wp-smart-retention-manager.sh`
4. Run tests:

```bash
bash tests/test_suite.sh
```

Tip: use full export (`bash tools/wsms-export-runtime-scripts.sh`) before release to ensure preview folders are fully synchronized.

## Automated Docker Smoke Test

For a repeatable Ubuntu-based installer test with safe WordPress fixtures:

```bash
bash tests/run_docker_smoke_test.sh
```

This builds `tests/docker/Dockerfile`, provisions two fake WordPress roots from `tests/fixtures/wordpress/public_html`, runs `installers/install_wsms.sh`, and verifies generated scripts, aliases, and crontab entries.

Extended runtime behavior smoke test:

```bash
bash tests/run_docker_runtime_smoke_test.sh
```

This validates runtime flows including backup/retention behavior, log persistence, `wp-hosts-sync` marker idempotency in `/etc/hosts`, and `wp-fleet-status-monitor` output containing SSL status (`SSL:`).

Full modules smoke test (all deployed runtime scripts):

```bash
bash tests/run_docker_all_modules_smoke_test.sh
```

If you prefer Docker Compose:

```bash
docker compose -f tests/docker/compose.yaml up --build --abort-on-container-exit
```

The fixture intentionally does not start a real database or full WordPress runtime. It is meant for safe installer and filesystem-oriented smoke tests, not for validating live WP-CLI database operations.

## Regression Tests

Run full repository test suite:

```bash
bash tests/test_suite.sh
```

Run focused uninstaller legacy cleanup regression test:

```bash
bash tests/test_uninstaller_legacy_cleanup.sh
```

This test verifies that old WSMS v4.2 shell blocks without marker delimiters are removed from Fish and Bash configs while non-WSMS lines are preserved.

## Uninstall

```bash
./tools/wsms-uninstall.sh --dry-run
./tools/wsms-uninstall.sh
./tools/wsms-uninstall.sh --force
```

`--dry-run` shows planned cleanup actions without modifying files.

Uninstaller cleanup covers both marker-based WSMS blocks and legacy v4.2-style shell blocks that were written without explicit start/end markers.

## Documentation

- `docs/DEPLOYMENT_GUIDE.md`
- `docs/DOCKER_HELP_PL.md`
- `docs/DOCKER_HELP_EN.md`
- `docs/FISH_SETUP_GUIDE.md`
- `docs/TECHNICAL_REFERENCE.md`
- `DOCKER_HELP.md`
- `CHANGELOG.md`

## macOS and iCloud Note

When this repository is synchronized via iCloud between macOS devices, Finder metadata files may appear locally.
Repository `.gitignore` already excludes common macOS/iCloud artifacts (for example `.DS_Store`, `._*`, and `*.icloud`) to keep commits clean.
