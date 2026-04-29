#!/bin/bash

set -euo pipefail

WORKSPACE_DIR="${WORKSPACE_DIR:-/workspace}"
FIXTURE_DIR="$WORKSPACE_DIR/tests/fixtures/wordpress/public_html"
TEST_USER="tester"
TEST_WORKSPACE="/home/$TEST_USER/workspace"

prepare_system_user() {
    local username="$1"
    local site_root="$2"

    if ! id "$username" >/dev/null 2>&1; then
        useradd -m -s /bin/bash "$username"
    fi

    mkdir -p "$site_root"
    cp -R "$FIXTURE_DIR/." "$site_root/"
    chown -R "$username:$username" "$site_root"
}

prepare_sites() {
    prepare_system_user "wordpress_site1" "/var/www/site1/public_html"
    prepare_system_user "wordpress_site2" "/var/www/site2/public_html"
}

prepare_tester() {
    if ! id "$TEST_USER" >/dev/null 2>&1; then
        useradd -m -s /bin/bash "$TEST_USER"
    fi

    echo "$TEST_USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$TEST_USER
    chmod 440 /etc/sudoers.d/$TEST_USER
}

run_installer() {
    rm -rf "$TEST_WORKSPACE"
    cp -R "$WORKSPACE_DIR" "$TEST_WORKSPACE"
    chown -R "$TEST_USER:$TEST_USER" "$TEST_WORKSPACE"
    su - "$TEST_USER" -c "cd '$TEST_WORKSPACE' && bash installers/install_wsms.sh"
}

assert_file() {
    local path="$1"
    if [ ! -e "$path" ]; then
        echo "Missing expected path: $path" >&2
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

validate_installation() {
    assert_file "/home/$TEST_USER/scripts/wsms-config.sh"
    assert_file "/home/$TEST_USER/scripts/wp-help.sh"
    assert_file "/home/$TEST_USER/logs/wsms/system"
    assert_file "/var/www/site1/public_html/wp-config.php"
    assert_file "/var/www/site2/public_html/wp-config.php"

    assert_contains 'site1:/var/www/site1/public_html:wordpress_site1' "/home/$TEST_USER/scripts/wsms-config.sh"
    assert_contains 'site2:/var/www/site2/public_html:wordpress_site2' "/home/$TEST_USER/scripts/wsms-config.sh"
    assert_contains 'WSMS PRO v4.3 BASH' "/home/$TEST_USER/.bashrc"

    crontab -u "$TEST_USER" -l | grep -q 'WSMS PRO v4.3 - CRONTAB'
    crontab -u "$TEST_USER" -l | grep -q 'wp-smart-retention-manager.sh force-clean'
    su - "$TEST_USER" -c 'TERM=xterm bash ~/scripts/wp-help.sh >/tmp/wsms-help.out'
    su - "$TEST_USER" -c 'bash ~/scripts/wp-smart-retention-manager.sh dirs >/tmp/wsms-backup-dirs.out'
}

main() {
    prepare_tester
    prepare_sites
    run_installer
    validate_installation
    echo "WSMS docker smoke test passed"
}

main "$@"