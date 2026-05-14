# Changelog

All notable changes to WSMS PRO are documented in this file.

## [4.3.10] - 2026-05-13

### Added
- New mail setup guide: `docs/MAIL_CONFIGURATION.md`.
- Example SMTP relay config files: `docs/msmtprc.example` and `docs/mailrc.example`.

### Changed
- `wp-fleet-status-monitor.sh` (EN/PL): SSL expiry is now checked for the real WordPress domain (resolved from WP home URL), not just the SITES config nickname. Output: `SSL: N d` or `SSL: N/A`.

### Fixed
- `wsms-notify.sh`: alert delivery no longer masks `mail` failures with `|| true`; WSMS now returns a real error when local mail submission fails.
- `wsms-notify.sh`: explicit check added for missing `mail` command.
- `wsms-test-alert` messaging updated to say alert was submitted to the local mail system, instead of implying final mailbox delivery.

## [4.3.9] - 2026-05-12

### Added
- Email alert system: `wsms-notify.sh` module with `send_alert()` function (sourced by other scripts).
- `wsms-daily-check.sh`: daily cron script that runs `server-health-audit`, `wp-fleet-status-monitor`, and `wp-cli-infrastructure-validator`, then sends a consolidated alert email.
- Three new configuration variables in `wsms-config.sh`: `ALERT_EMAIL`, `ALERT_ON_FAILURE`, `ALERT_ON_SUCCESS`. Empty `ALERT_EMAIL` disables all alerts.
- `send_alert` calls added to: `wp-automated-maintenance-engine.sh` (rollback triggered, cycle summary), `wp-smart-retention-manager.sh` (disk threshold exceeded), `server-health-audit.sh` (web server down, disk critical), `clamav-auto-scan.sh` (infected files found), `clamav-full-scan.sh` (infected files found).
- Docker smoke test `tests/docker/run-notify-smoke.sh` and launcher `tests/run_docker_notify_smoke_test.sh` (7 tests on Ubuntu with mailutils).
- `tests/test_suite.sh` expanded with 24 new assertions covering notify/daily-check modules, installer content, and EN/PL parity (171 total).
- `tests/docker/run-all-modules-smoke.sh` updated: `wsms-notify.sh` and `wsms-daily-check.sh` added to module run list (25 modules total).
- `tests/docker/run-install-smoke.sh` updated: asserts presence of `wsms-notify.sh` and `wsms-daily-check.sh` after installation.
- `tools/wsms-uninstall.sh`: `wsms-daily-check.sh` added to crontab cleanup list.
- `docs/TECHNICAL_REFERENCE.md`: new "Email Alerting" section with alert trigger table and cron setup.

## [4.3.8] - 2026-05-12

### Fixed
- `nas-sftp-sync.sh`: `ensure_remote_dir` was checking for literal string `"remote_dir"` instead of the variable value — replaced `grep -q "remote_dir"` with `grep -qF "$remote_dir"` (EN) / `grep -qF "$zdalny_folder"` (PL).
- `nas-sftp-sync.sh`: replaced `for file in $(ls ...)` with `while IFS= read -r file; done < <(find ...)` to handle filenames with spaces correctly.
- `mysql-backup-manager.sh`: unquoted `$name` in glob `db-$name-*.sql.gz` — now `db-"$name"-*.sql.gz`.
- `tools/wsms-uninstall.sh`: `((removed_script_dirs++))` replaced with `removed_script_dirs=$((removed_script_dirs + 1))` for bash 3 compatibility.
- `tools/wsms-export-runtime-scripts.sh`: added safety guard before `rm -rf` to prevent accidental deletion if output paths are empty or `/`.
- All fixes applied to both EN and PL installer deploy blocks (source of truth) and runtime preview files.

## [4.3.7] - 2026-05-12

### Changed
- `tests/test_suite.sh` expanded with full behavioral coverage (143 tests):
  - syntax checks for all installers, tools, and runtime preview scripts (EN/PL),
  - required file presence checks,
  - documentation format validation,
  - installer content markers (all key modules, version, crontab),
  - EN/PL module parity (12 modules verified),
  - runtime script content checks (key functions and patterns),
  - behavioral tests: `normalize_backup_key` logic, `emergency_cleanup` file grouping, hosts-sync domain validation, hosts-sync marker idempotency, uninstaller legacy cleanup, uninstaller `--dry-run` no-op, rollback graceful error on missing snapshot, maintenance engine usage on invalid mode, retention manager usage on unknown arg.

## [4.3.6] - 2026-05-12

### Added
- Docker runtime smoke test (`tests/docker/run-runtime-behavior-smoke.sh`) expanded with real script behavior checks:
	- runs `wp-hosts-sync` twice and verifies idempotent WSMS marker block handling in `/etc/hosts`,
	- validates `wp-fleet-status-monitor` output includes SSL status field (`SSL:`).

## [4.3.5] - 2026-05-12

### Added
- SSL certificate expiry monitoring in `wp-fleet-status-monitor.sh`: each site in fleet status now shows remaining days of SSL validity (`SSL: N days`).
  - Green if ≥ 14 days remaining, red if < 14 days, yellow if certificate is unavailable or unreachable.
  - EN version displays days as `d`, PL version as `dni`.

## [4.3.4] - 2026-05-05

### Added
- New regression test `tests/test_uninstaller_legacy_cleanup.sh` to verify cleanup of legacy v4.2 shell blocks without marker delimiters in Fish and Bash configs.
- Main test suite now executes this behavior test (`tests/test_suite.sh`).

### Fixed
- Uninstaller (`tools/wsms-uninstall.sh`) now removes legacy v4.2-style shell blocks that do not have WSMS marker delimiters, including old helper echo lines, while preserving non-WSMS user lines.

## [4.3.3] - 2026-05-02

### Added
- Granular maintenance engine modes in `wp-automated-maintenance-engine.sh`:
	- `site <site>` for one-site full update,
	- `plugin <site> <plugin>` for one-plugin update,
	- `theme <site> <theme>` for one-theme update.
- New aliases for granular updates in Bash and Fish blocks:
	- `wp-update-site`, `wp-update-plugin`, `wp-update-theme`.
- `wp-help.sh` updated (EN/PL) with the new update command variants.
- `tools/wsms-export-runtime-scripts.sh` supports selective export using `--only script1,script2,...`.

### Changed
- Emergency cleanup now also prunes rollback snapshots in `backups-rollback` while keeping 2 latest snapshots per site.

## [4.3.2] - 2026-05-02

### Fixed
- `infrastructure-permission-orchestrator.sh`: after `setfacl -R -m u:$USER:r-x`, the ACL on `wp-config.php` is now immediately overridden to `r--` (no execute bit). This prevents `stat` from reporting permissions as `650` instead of `640` due to ACL mask recalculation.
- Uninstaller (`tools/wsms-uninstall.sh`): sed patterns are now version-agnostic (`v[0-9].[0-9]`), removing alias blocks from any previously installed WSMS version, not only v4.3. Also cleans `~/.bash_profile` if it contains WSMS blocks.

## [4.3.1] - 2026-05-02

### Added
- `emergency_global_cleanup()` function in `wp-smart-retention-manager.sh`: keeps only the 2 newest files **total per backup directory** (lite/full/mysql), regardless of site grouping — the most aggressive disk-space recovery mode.
- New alias `backup-emergency-global` (`eg` shorthand) calling `emergency-global` mode.
- Interactive menu option 7 added to `wp-smart-retention-manager.sh`.
- `wp-help.sh` updated in all 4 copies (EN/PL × runtime-preview/installer heredoc): new `backup-emergency-global` entry in Cleanup section, updated Low disk space troubleshooting tip.
- `shell/aliases.fish` updated: `backup-emergency-global` alias, `wp-hosts-sync` alias (was missing).

## [4.3.0] - 2026-04-29

### Added
- Installer live logging to terminal and file for English and Polish installers.
- Detailed installer error context via traps (current step, line, command, exit code).
- Automatic live-log bootstrap for generated runtime scripts sourced from `~/scripts/wsms-config.sh`.
- Runtime hosts synchronization module (`wp-hosts-sync`) generated by both installers.
- Uninstaller preview mode (`--dry-run`) for no-op cleanup verification.
- Runtime preview exporter `tools/wsms-export-runtime-scripts.sh` to generate copy-ready module previews from installer deploy blocks.

### Changed
- Unified alias setup in installers as self-contained Bash/Fish blocks.
- Updated repository and documentation references to current installer/uninstaller names.
- Repository `scripts/` directory converted to metadata-only note; runtime modules are installer-generated artifacts.
- Installer runtime deployment count updated to match current generated module set.

### Fixed
- Test suite required file checks updated to current file names.
- Stale v4.2 references replaced where relevant.
- Installer multiline site config replacement now uses robust tempfile + awk flow (avoids sed multiline substitution errors).
- Uninstaller cleanup narrowed to WSMS marker blocks to avoid over-broad alias removal.

## [4.2.0] - 2026-04-19

### Added
- Rollback engine (`wp-rollback.sh`) with pre-update snapshots.
- Organized logging under `~/logs/wsms/`.
- Configuration validation in installer.
- Universal uninstaller.

## [4.1.0] - 2026-03-15

### Added
- Initial public release.

[4.3.3]: https://github.com/maleclukas-prog/wp-server-management-system/compare/v4.3.2...v4.3.3
[4.3.6]: https://github.com/maleclukas-prog/wp-server-management-system/compare/v4.3.5...v4.3.6
[4.3.5]: https://github.com/maleclukas-prog/wp-server-management-system/compare/v4.3.4...v4.3.5
[4.3.4]: https://github.com/maleclukas-prog/wp-server-management-system/compare/v4.3.3...v4.3.4
[4.3.2]: https://github.com/maleclukas-prog/wp-server-management-system/compare/v4.3.1...v4.3.2
[4.3.1]: https://github.com/maleclukas-prog/wp-server-management-system/compare/v4.3.0...v4.3.1
[4.3.0]: https://github.com/maleclukas-prog/wp-server-management-system/releases/tag/v4.3.0
[4.2.0]: https://github.com/maleclukas-prog/wp-server-management-system/releases/tag/v4.2.0
[4.1.0]: https://github.com/maleclukas-prog/wp-server-management-system/releases/tag/v4.1.0
