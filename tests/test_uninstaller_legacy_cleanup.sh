#!/bin/bash
# =================================================================
# WSMS PRO - Legacy uninstaller cleanup test
# Verifies removal of old v4.2-style shell blocks without markers.
# =================================================================

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
UNINSTALLER="$ROOT_DIR/tools/wsms-uninstall.sh"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

TEST_HOME="$TMP_DIR/home"
FAKE_BIN="$TMP_DIR/fake-bin"
mkdir -p "$TEST_HOME/.config/fish" "$FAKE_BIN"

cat > "$TEST_HOME/.config/fish/config.fish" <<'EOF'
# keep-this-fish-line
# WSMS PRO v4.2 - FISH SHELL ALIASES
alias db-backup='bash $SCRIPTS_DIR/mysql-backup-manager.sh'
function wp-status
    echo "hello"
end
echo "✅ WSMS PRO v4.2 - Fish aliases loaded!"
echo "   Type 'wp-help' for command reference"
echo "   Type 'wp-status' for system overview"
echo "   Type 'wp-health' for health check"
# keep-after-fish-line
EOF

cat > "$TEST_HOME/.bashrc" <<'EOF'
# keep-this-bash-line
# WSMS PRO v4.2 - BASH SHELL ALIASES
alias db-backup='bash $SCRIPTS_DIR/mysql-backup-manager.sh'
echo "✅ WSMS PRO v4.2 - Bash aliases loaded!"
echo "   Type 'wp-help' for command reference"
echo "   Type 'wp-status' for system overview"
echo "   Type 'wp-health' for health check"
# keep-after-bash-line
EOF

cat > "$FAKE_BIN/sudo" <<'EOF'
#!/bin/sh
exit 1
EOF
chmod +x "$FAKE_BIN/sudo"

cat > "$FAKE_BIN/crontab" <<'EOF'
#!/bin/sh
if [ "$1" = "-l" ]; then
  exit 1
fi
exit 0
EOF
chmod +x "$FAKE_BIN/crontab"

HOME="$TEST_HOME" PATH="$FAKE_BIN:$PATH" bash "$UNINSTALLER" --force > "$TMP_DIR/uninstall.log" 2>&1 || {
    echo "Uninstaller execution failed"
    cat "$TMP_DIR/uninstall.log"
    exit 1
}

if grep -q "WSMS PRO v4.2 - FISH SHELL ALIASES" "$TEST_HOME/.config/fish/config.fish"; then
    echo "Legacy fish header was not removed"
    cat "$TEST_HOME/.config/fish/config.fish"
    exit 1
fi

if grep -q "Type 'wp-help' for command reference" "$TEST_HOME/.config/fish/config.fish"; then
    echo "Legacy fish help lines were not removed"
    cat "$TEST_HOME/.config/fish/config.fish"
    exit 1
fi

if grep -q "WSMS PRO v4.2 - BASH SHELL ALIASES" "$TEST_HOME/.bashrc"; then
    echo "Legacy bash header was not removed"
    cat "$TEST_HOME/.bashrc"
    exit 1
fi

if grep -q "Type 'wp-help' for command reference" "$TEST_HOME/.bashrc"; then
    echo "Legacy bash help lines were not removed"
    cat "$TEST_HOME/.bashrc"
    exit 1
fi

if ! grep -q "keep-this-fish-line" "$TEST_HOME/.config/fish/config.fish" || ! grep -q "keep-after-fish-line" "$TEST_HOME/.config/fish/config.fish"; then
    echo "Fish non-WSMS lines were unexpectedly removed"
    cat "$TEST_HOME/.config/fish/config.fish"
    exit 1
fi

if ! grep -q "keep-this-bash-line" "$TEST_HOME/.bashrc" || ! grep -q "keep-after-bash-line" "$TEST_HOME/.bashrc"; then
    echo "Bash non-WSMS lines were unexpectedly removed"
    cat "$TEST_HOME/.bashrc"
    exit 1
fi

echo "✅ Legacy cleanup test passed"
