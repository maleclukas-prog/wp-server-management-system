#!/bin/bash

set -euo pipefail

TEST_USER="tester"
HOME_DIR="/home/$TEST_USER"

assert_file() {
    local path="$1"
    if [ ! -f "$path" ]; then
        echo "Missing expected file: $path" >&2
        exit 1
    fi
}

assert_contains() {
    local needle="$1"
    local path="$2"
    if ! grep -q "$needle" "$path"; then
        echo "Expected '$needle' in $path" >&2
        exit 1
    fi
}

run_as_tester() {
    su - "$TEST_USER" -c "$1"
}

seed_old_backups_for_retention_test() {
    run_as_tester "mkdir -p ~/backups-lite ~/mysql-backups ~/backups-rollback/site1"

    run_as_tester "touch -d '40 days ago' ~/backups-lite/lite-site1-20260101-010101.tar.gz"
    run_as_tester "touch -d '39 days ago' ~/backups-lite/lite-site1-20260102-010101.tar.gz"
    run_as_tester "touch -d '38 days ago' ~/backups-lite/lite-site1-20260103-010101.tar.gz"

    run_as_tester "touch -d '40 days ago' ~/mysql-backups/db-site1-20260101-010101.sql.gz"
    run_as_tester "touch -d '39 days ago' ~/mysql-backups/db-site1-20260102-010101.sql.gz"
    run_as_tester "touch -d '38 days ago' ~/mysql-backups/db-site1-20260103-010101.sql.gz"

    run_as_tester "mkdir -p ~/backups-rollback/site1/20260101_010101 ~/backups-rollback/site1/20260102_010101 ~/backups-rollback/site1/20260103_010101"
    run_as_tester "touch -d '40 days ago' ~/backups-rollback/site1/20260101_010101/files.tar.gz"
    run_as_tester "touch -d '39 days ago' ~/backups-rollback/site1/20260102_010101/files.tar.gz"
    run_as_tester "touch -d '38 days ago' ~/backups-rollback/site1/20260103_010101/files.tar.gz"
}

validate_retention_effect() {
    local lite_count
    local mysql_count
    local rollback_count

    lite_count=$(run_as_tester "ls -1 ~/backups-lite/lite-site1-*.tar.gz 2>/dev/null | wc -l")
    mysql_count=$(run_as_tester "ls -1 ~/mysql-backups/db-site1-*.sql.gz 2>/dev/null | wc -l")
    rollback_count=$(run_as_tester "find ~/backups-rollback/site1 -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l")

    if [ "$lite_count" -ne 2 ]; then
        echo "Expected exactly 2 lite-site1 backups after emergency cleanup, got: $lite_count" >&2
        exit 1
    fi

    if [ "$mysql_count" -ne 2 ]; then
        echo "Expected exactly 2 db-site1 backups after emergency cleanup, got: $mysql_count" >&2
        exit 1
    fi

    if [ "$rollback_count" -ne 2 ]; then
        echo "Expected exactly 2 rollback snapshots for site1 after emergency cleanup, got: $rollback_count" >&2
        exit 1
    fi
}

validate_logs() {
    assert_file "$HOME_DIR/logs/wsms/retention/retention.log"
    assert_file "$HOME_DIR/logs/wsms/sync/nas-sync.log"

    assert_contains "EMERGENCY MODE" "$HOME_DIR/logs/wsms/retention/retention.log"
    assert_contains "Processing backups-lite" "$HOME_DIR/logs/wsms/retention/retention.log"
    assert_contains "Missing NAS configuration" "$HOME_DIR/logs/wsms/sync/nas-sync.log"
}

run_runtime_scripts() {
    run_as_tester "TERM=xterm bash ~/scripts/wp-help.sh > /tmp/wsms-help.out 2>&1"
    run_as_tester "bash ~/scripts/wp-essential-assets-backup.sh > /tmp/wsms-lite.out 2>&1"
    run_as_tester "bash ~/scripts/wp-full-recovery-backup.sh > /tmp/wsms-full.out 2>&1"
    run_as_tester "bash ~/scripts/wp-smart-retention-manager.sh list > /tmp/wsms-list-before.out 2>&1"

    seed_old_backups_for_retention_test

    run_as_tester "sed -i 's/^DISK_ALERT_THRESHOLD=.*/DISK_ALERT_THRESHOLD=0/' ~/scripts/wsms-config.sh"
    run_as_tester "bash ~/scripts/wp-smart-retention-manager.sh force-clean > /tmp/wsms-clean.out 2>&1"
    run_as_tester "bash ~/scripts/wp-smart-retention-manager.sh list > /tmp/wsms-list-after.out 2>&1"

    run_as_tester "mkdir -p ~/.ssh && touch ~/.ssh/fake_nas_key && chmod 600 ~/.ssh/fake_nas_key"
    run_as_tester "NAS_HOST= NAS_PORT=22 NAS_USER=tester NAS_PATH=/tmp/nas NAS_SSH_KEY=/home/tester/.ssh/fake_nas_key bash ~/scripts/nas-sftp-sync.sh > /tmp/wsms-nas.out 2>&1 || true"
}

validate_stdout_markers() {
    assert_contains "Completed" "/tmp/wsms-lite.out"
    assert_contains "Completed" "/tmp/wsms-full.out"
    assert_contains "EMERGENCY MODE" "/tmp/wsms-clean.out"
    assert_contains "Processing backups-lite" "/tmp/wsms-clean.out"
    assert_contains "backups-rollback" "/tmp/wsms-clean.out"
    assert_contains "Missing NAS configuration" "/tmp/wsms-nas.out"
}

main() {
    /workspace/tests/docker/run-install-smoke.sh

    run_runtime_scripts
    validate_stdout_markers
    validate_retention_effect
    validate_logs

    echo "WSMS runtime behavior smoke test passed"
}

main "$@"
