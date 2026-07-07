# Tools Usage Guide

This directory contains helper tools for WSMS repository operations.

## Available Tools

- `wsms-export-runtime-scripts.sh` - extract runtime modules from installer deploy blocks
- `wsms-uninstall.sh` - remove WSMS runtime components from a server

## wsms-export-runtime-scripts.sh

Export runtime modules from:

- `installers/install_wsms.sh` (EN)
- `installers/install_wsms_pl.sh` (PL)

into:

- `<output>/en/`
- `<output>/pl/`

### Usage

```bash
bash tools/wsms-export-runtime-scripts.sh [output_dir] [--only script.sh] [--only script2.sh]
```

Alternative with comma list:

```bash
bash tools/wsms-export-runtime-scripts.sh [output_dir] --only script1.sh,script2.sh
```

Examples:

```bash
# Export all modules to runtime-preview
bash tools/wsms-export-runtime-scripts.sh

# Export one module to temporary directory
bash tools/wsms-export-runtime-scripts.sh /tmp/wsms-one --only wp-smart-retention-manager.sh

# Export selected modules using repeated --only
bash tools/wsms-export-runtime-scripts.sh /tmp/wsms-one --only wp-help.sh --only server-health-audit.sh
```

Notes:

- If `--only` matches no module, the tool exits with error.
- Existing `<output>/en` and `<output>/pl` are replaced on each run.

## Single-Script Hotfix Workflow

Use this when you want to replace only one script on a server.

1. Export one script:

```bash
bash tools/wsms-export-runtime-scripts.sh /tmp/wsms-one --only wp-smart-retention-manager.sh
```

1. Compare with current preview:

```bash
diff -u scripts/runtime-preview/en/wp-smart-retention-manager.sh /tmp/wsms-one/en/wp-smart-retention-manager.sh | sed -n '1,200p'
echo ""
diff -u scripts/runtime-preview/pl/wp-smart-retention-manager.sh /tmp/wsms-one/pl/wp-smart-retention-manager.sh | sed -n '1,200p'
```

1. Upload one selected language variant:

```bash
SCRIPT_NAME="wp-smart-retention-manager.sh"
LANG="en"                       # en or pl
SERVER_USER="your_user"
SERVER_HOST="your.host.tld"
SERVER_SCRIPT_DIR="/home/your_user/scripts"

scp "/tmp/wsms-one/$LANG/$SCRIPT_NAME" "$SERVER_USER@$SERVER_HOST:$SERVER_SCRIPT_DIR/$SCRIPT_NAME"
```

1. Verify on remote host:

```bash
ssh "$SERVER_USER@$SERVER_HOST" "ls -la $SERVER_SCRIPT_DIR/$SCRIPT_NAME && bash $SERVER_SCRIPT_DIR/$SCRIPT_NAME --help 2>/dev/null || true"
```

## When to Use Full Reinstall Instead

Use uninstall + install when changes affect:

- aliases and shell startup files
- crontab entries
- multiple modules at once
- installer-side orchestration behavior
