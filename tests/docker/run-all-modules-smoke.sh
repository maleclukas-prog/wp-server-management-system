#!/bin/bash

set -euo pipefail

TEST_USER="tester"
REPORT_DIR="/tmp/wsms-all-modules"
REPORT_FILE="$REPORT_DIR/report.txt"

mkdir -p "$REPORT_DIR"

run_as_tester() {
    su - "$TEST_USER" -c "$1"
}

write_report_header() {
    {
        echo "WSMS ALL MODULES SMOKE REPORT"
        echo "Generated: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
        echo "=========================================================="
    } > "$REPORT_FILE"
}

run_check() {
    local name="$1"
    local mode="$2"
    local command="$3"
    local marker="${4:-}"

    local out_file="$REPORT_DIR/${name}.out"
    local rc=0

    set +e
    run_as_tester "timeout 180 bash -lc '$command'" > "$out_file" 2>&1
    rc=$?
    set -e

    local status="FAIL"
    local reason=""

    case "$mode" in
        success)
            if [ "$rc" -eq 0 ]; then
                status="PASS"
                reason="exit=0"
            else
                status="FAIL"
                reason="exit=$rc"
            fi
            ;;
        expected-fail)
            if [ "$rc" -ne 0 ] && [ -n "$marker" ] && grep -q "$marker" "$out_file"; then
                status="PASS"
                reason="expected failure observed (exit=$rc, marker='$marker')"
            elif [ "$rc" -ne 0 ]; then
                status="WARN"
                reason="failed as expected but marker missing (exit=$rc)"
            else
                status="WARN"
                reason="unexpected success"
            fi
            ;;
        marker)
            if [ "$rc" -eq 0 ] && [ -n "$marker" ] && grep -q "$marker" "$out_file"; then
                status="PASS"
                reason="exit=0 + marker '$marker'"
            elif [ "$rc" -eq 124 ]; then
                status="WARN"
                reason="timeout"
            else
                status="FAIL"
                reason="exit=$rc or marker missing"
            fi
            ;;
        *)
            status="FAIL"
            reason="invalid test mode"
            ;;
    esac

    printf "%-38s | %-5s | %s\n" "$name" "$status" "$reason" | tee -a "$REPORT_FILE"
}

prepare_environment() {
    run_as_tester "mkdir -p ~/logs/wsms/sync ~/logs/wsms/retention ~/logs/wsms/backups"
    run_as_tester "mkdir -p ~/.ssh && touch ~/.ssh/fake_nas_key && chmod 600 ~/.ssh/fake_nas_key"
}

prepare_valid_domains_for_hosts_sync() {
    run_as_tester "cp ~/scripts/wsms-config.sh ~/scripts/wsms-config.sh.bak"
    run_as_tester "sed -i 's/site1:\/var\/www\/site1\/public_html/site1.local:\/var\/www\/site1\/public_html/g' ~/scripts/wsms-config.sh"
    run_as_tester "sed -i 's/site2:\/var\/www\/site2\/public_html/site2.local:\/var\/www\/site2\/public_html/g' ~/scripts/wsms-config.sh"
}

run_all_module_checks() {
    run_check "server-health-audit.sh" "success" "TERM=xterm ~/scripts/server-health-audit.sh"
    run_check "wp-fleet-status-monitor.sh" "success" "~/scripts/wp-fleet-status-monitor.sh"
    run_check "wp-multi-instance-audit.sh" "success" "~/scripts/wp-multi-instance-audit.sh"
    run_check "wp-automated-maintenance-engine.sh" "marker" "~/scripts/wp-automated-maintenance-engine.sh" "MAINTENANCE SUMMARY"
    run_check "infrastructure-permission-orchestrator.sh" "success" "~/scripts/infrastructure-permission-orchestrator.sh"
    run_check "wp-full-recovery-backup.sh" "marker" "~/scripts/wp-full-recovery-backup.sh" "Completed"
    run_check "wp-essential-assets-backup.sh" "marker" "~/scripts/wp-essential-assets-backup.sh" "Completed"
    run_check "mysql-backup-manager.sh:list" "success" "~/scripts/mysql-backup-manager.sh list"
    run_check "mysql-backup-manager.sh:all" "success" "~/scripts/mysql-backup-manager.sh all"
    run_check "nas-sftp-sync.sh" "expected-fail" "NAS_HOST= NAS_PORT=22 NAS_USER=tester NAS_PATH=/tmp/nas NAS_SSH_KEY=/home/tester/.ssh/fake_nas_key ~/scripts/nas-sftp-sync.sh" "Missing NAS configuration"
    run_check "wp-smart-retention-manager.sh" "success" "~/scripts/wp-smart-retention-manager.sh list"
    run_check "wp-help.sh" "success" "TERM=xterm ~/scripts/wp-help.sh"
    run_check "wp-interactive-backup-tool.sh" "success" "printf '0\n' | ~/scripts/wp-interactive-backup-tool.sh"
    run_check "standalone-mysql-backup-engine.sh" "success" "~/scripts/standalone-mysql-backup-engine.sh"
    run_check "red-robin-system-backup.sh" "marker" "~/scripts/red-robin-system-backup.sh" "System backup"
    run_check "clamav-auto-scan.sh" "success" "~/scripts/clamav-auto-scan.sh"
    run_check "clamav-full-scan.sh" "marker" "~/scripts/clamav-full-scan.sh" "Full scan complete"
    run_check "wp-cli-infrastructure-validator.sh" "success" "~/scripts/wp-cli-infrastructure-validator.sh"
    run_check "wp-rollback.sh:snapshot-all" "success" "~/scripts/wp-rollback.sh snapshot all"
    run_check "wp-rollback.sh:list-site1" "success" "~/scripts/wp-rollback.sh list site1"
    run_check "wp-rollback.sh:rollback-site1" "success" "~/scripts/wp-rollback.sh rollback site1"
    prepare_valid_domains_for_hosts_sync
    run_check "wp-hosts-sync.sh" "success" "~/scripts/wp-hosts-sync.sh"
    run_check "wsms-clean.sh" "success" "~/scripts/wsms-clean.sh --force"
}

summarize() {
    local pass_count warn_count fail_count
    pass_count=$(grep -c "| PASS " "$REPORT_FILE" || true)
    warn_count=$(grep -c "| WARN " "$REPORT_FILE" || true)
    fail_count=$(grep -c "| FAIL " "$REPORT_FILE" || true)

    {
        echo "=========================================================="
        echo "PASS: $pass_count"
        echo "WARN: $warn_count"
        echo "FAIL: $fail_count"
    } | tee -a "$REPORT_FILE"

    echo "Detailed outputs: $REPORT_DIR/*.out"
    echo "Summary report: $REPORT_FILE"

    if [ "$fail_count" -gt 0 ]; then
        return 1
    fi

    return 0
}

main() {
    /workspace/tests/docker/run-install-smoke.sh
    write_report_header
    prepare_environment
    run_all_module_checks
    summarize
}

main "$@"
