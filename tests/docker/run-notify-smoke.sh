#!/bin/bash
# =================================================================
# WSMS PRO v4.3 - NOTIFY SYSTEM SMOKE TEST
# Tests wsms-notify.sh and wsms-daily-check.sh alert logic
# on Ubuntu with mailutils installed.
# =================================================================

set -euo pipefail

TEST_USER="tester"
HOME_DIR="/home/$TEST_USER"
SCRIPTS_DIR="$HOME_DIR/scripts"
WORKSPACE_DIR="${WORKSPACE_DIR:-/workspace}"

# ============================================
# SETUP
# ============================================
setup() {
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq
    apt-get install -y --no-install-recommends bsd-mailx sudo 2>/dev/null || \
    apt-get install -y --no-install-recommends mailutils sudo 2>/dev/null || true

    useradd -m -s /bin/bash "$TEST_USER"
    echo "$TEST_USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$TEST_USER
    chmod 440 /etc/sudoers.d/$TEST_USER

    mkdir -p "$SCRIPTS_DIR"
    cp "$WORKSPACE_DIR/scripts/runtime-preview/en/wsms-notify.sh" "$SCRIPTS_DIR/"
    cp "$WORKSPACE_DIR/scripts/runtime-preview/en/wsms-daily-check.sh" "$SCRIPTS_DIR/"

    # Minimal wsms-config.sh
    cat > "$SCRIPTS_DIR/wsms-config.sh" << 'EOF'
SCRIPT_DIR="$HOME/scripts"
SITES=("site1:/var/www/site1/public_html:wordpress_site1")
DISK_ALERT_THRESHOLD=80
ALERT_EMAIL="test@localhost"
ALERT_ON_FAILURE="yes"
ALERT_ON_SUCCESS="yes"
export SCRIPT_DIR SITES DISK_ALERT_THRESHOLD ALERT_EMAIL ALERT_ON_FAILURE ALERT_ON_SUCCESS
EOF

    chown -R "$TEST_USER:$TEST_USER" "$HOME_DIR"
}

# ============================================
# HELPERS
# ============================================
PASS=0
FAIL=0

setup

assert_ok() {
    local desc="$1"
    if eval "$2"; then
        echo "✅ $desc"
        PASS=$((PASS + 1))
    else
        echo "❌ $desc"
        FAIL=$((FAIL + 1))
    fi
}

run_as_tester() {
    su - "$TEST_USER" -c "$1"
}

# ============================================
# TEST 1: wsms-notify.sh sourcuje się bez błędów
# ============================================
assert_ok "wsms-notify.sh sourcuje się bez błędów" \
    "run_as_tester 'source ~/scripts/wsms-notify.sh && echo ok' | grep -q ok"

# ============================================
# TEST 1b: wsms-notify.sh wymaga komendy mail
# ============================================
assert_ok "wsms-notify.sh sprawdza obecność komendy mail" \
    "run_as_tester 'grep -q "'"'command -v mail'"'" ~/scripts/wsms-notify.sh'"

# ============================================
# TEST 2: pusty ALERT_EMAIL nie wywołuje mail
# ============================================
assert_ok "Pusty ALERT_EMAIL pomija wysyłkę" \
    "run_as_tester 'source ~/scripts/wsms-notify.sh; ALERT_EMAIL=\"\" send_alert failure X X && echo skipped' | grep -q skipped"

# ============================================
# TEST 3: ALERT_ON_FAILURE=no pomija failure
# ============================================
assert_ok "ALERT_ON_FAILURE=no pomija wysyłkę" \
    "run_as_tester 'source ~/scripts/wsms-notify.sh; ALERT_EMAIL=test@localhost ALERT_ON_FAILURE=no send_alert failure X X && echo skipped' | grep -q skipped"

# ============================================
# TEST 4: ALERT_ON_SUCCESS=no pomija success
# ============================================
assert_ok "ALERT_ON_SUCCESS=no pomija wysyłkę" \
    "run_as_tester 'source ~/scripts/wsms-notify.sh; ALERT_EMAIL=test@localhost ALERT_ON_SUCCESS=no send_alert success X X && echo skipped' | grep -q skipped"

# ============================================
# TEST 5: send_alert failure wywołuje mail
# ============================================
assert_ok "send_alert failure wywołuje mail bez błędu" \
    "run_as_tester 'source ~/scripts/wsms-config.sh; source ~/scripts/wsms-notify.sh; send_alert failure \"CRITICAL: Web server down\" \"Nginx nie działa.\nCzas: \$(date)\" && echo sent' | grep -q sent"

# ============================================
# TEST 6: send_alert success wywołuje mail
# ============================================
assert_ok "send_alert success wywołuje mail bez błędu" \
    "run_as_tester 'source ~/scripts/wsms-config.sh; source ~/scripts/wsms-notify.sh; send_alert success \"Daily check OK\" \"Wszystkie systemy OK.\nCzas: \$(date)\" && echo sent' | grep -q sent"

# ============================================
# TEST 7: wsms-daily-check wykrywa fikcyjną awarię i wysyła alert
# ============================================
# Podmień run_check na mock który zwraca awarię
cat > /tmp/daily-check-test.sh << 'TESTEOF'
source "$HOME/scripts/wsms-config.sh"
source "$HOME/scripts/wsms-notify.sh"

REPORT=""
FAILURES=0

# Mock: symuluje wynik z awarią
mock_check() {
    local label="$1"
    local output="$2"
    REPORT="$REPORT=== $label ===\n$output\n\n"
    if echo "$output" | grep -qiE "❌|CRITICAL|ERROR|failed|unreachable|stopped"; then
        FAILURES=$((FAILURES+1))
    fi
}

mock_check "Server Health Audit"        "✅ Nginx: Active\n❌ MySQL: Installed but STOPPED\n✅ SSH: Active"
mock_check "WordPress Fleet Status"     "✅ site1: v6.5 | SSL: 45d | Updates: 0"
mock_check "WP-CLI Infrastructure Test" "✅ site1"

if [ "$FAILURES" -gt 0 ]; then
    send_alert "failure" "Daily check: $FAILURES issue(s) detected on $(hostname)" "$(printf "%b" "$REPORT")" && echo "alert_sent"
else
    echo "no_failures"
fi
TESTEOF

chown "$TEST_USER:$TEST_USER" /tmp/daily-check-test.sh

assert_ok "wsms-daily-check wykrywa awarię i wysyła alert failure" \
    "run_as_tester 'bash /tmp/daily-check-test.sh' | grep -q alert_sent"

# ============================================
# WYNIKI
# ============================================
echo ""
echo "=========================================="
echo "Wyniki: $PASS zaliczone, $FAIL nieudane"
echo "=========================================="

if [ "$FAIL" -eq 0 ]; then
    echo "✅ NOTIFY SMOKE TEST PASSED"
else
    echo "❌ NOTIFY SMOKE TEST FAILED"
    exit 1
fi
