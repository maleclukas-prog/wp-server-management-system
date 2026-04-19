
---

## 📄 PLIK 7/12: `CHANGELOG.md`

```markdown
# Changelog

All notable changes to WSMS PRO will be documented in this file.

## [4.2.0] - 2026-04-19

### 🆕 Added
- **Rollback Engine** (`wp-rollback.sh`): Automated pre-update snapshots with instant rollback capability
- **Organized Logging**: Structured log directory `~/logs/wsms/` with categories (backups, maintenance, security, sync, retention, rollback, system)
- **Configuration Validation**: Installer validates site configurations before deployment
- **Universal Uninstaller**: `tools/uninstall.sh` for complete system removal with `--force` option
- **Health Verification**: Automatic HTTP checks after updates and rollbacks
- **Polish Installer**: `installers/install-pl.sh` for Polish users
- **Slack/Email Notifications**: Optional webhook and email alert support
- New aliases: `wp-snapshot`, `wp-rollback`, `wp-snapshots`, `wp-rollback-clean`
- New functions: `wp-update-safe` (enhanced), `wp-rollback-safe`

### 🔧 Changed
- `wp-automated-maintenance-engine.sh` now creates rollback snapshot before updating
- `wp-automated-maintenance-engine.sh` verifies site health after updates with automatic rollback on failure
- All log files moved from home directory to organized `~/logs/wsms/` structure
- `nas-sftp-sync.sh` improved with separate error log and SSH key validation
- `wp-smart-retention-manager.sh` enhanced with interactive cleanup mode
- `wp-help.sh` completely rewritten with rollback commands and log locations
- Installer now detects current shell and installs appropriate aliases

### 🐛 Fixed
- Cron jobs now use expanded `$HOME` path for reliable execution
- SFTP sync no longer fails silently - errors logged to `nas-errors.log`
- Log files no longer clutter home directory
- Permission orchestrator properly handles web server restart

### 📚 Documentation
- Complete documentation overhaul for v4.2
- Added `FISH_SETUP_GUIDE.md` with comprehensive Fish shell configuration
- Added `TECHNICAL_REFERENCE.md` with detailed module descriptions
- Added `DEPLOYMENT_GUIDE.md` with SOP and incident response procedures
- Updated `README.md` with new features and command reference

## [4.1.0] - 2026-03-15

### Added
- Initial public release
- 17 operational modules
- Bash and Fish shell support
- NAS sync functionality
- ClamAV integration
- Smart retention manager with emergency mode

[4.1.0]: https://github.com/maleclukas-prog/wp-server-management-system/releases/tag/v4.1.0
[4.2.0]: https://github.com/maleclukas-prog/wp-server-management-system/releases/tag/v4.2.0