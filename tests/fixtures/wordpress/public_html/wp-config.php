<?php
define('DB_NAME', 'wsms_fixture');
define('DB_USER', 'wsms_fixture');
define('DB_PASSWORD', 'wsms_fixture');
define('DB_HOST', '127.0.0.1');

define('DB_CHARSET', 'utf8');
define('DB_COLLATE', '');

define('AUTH_KEY', 'fixture-auth-key');
define('SECURE_AUTH_KEY', 'fixture-secure-auth-key');
define('LOGGED_IN_KEY', 'fixture-logged-in-key');
define('NONCE_KEY', 'fixture-nonce-key');
define('AUTH_SALT', 'fixture-auth-salt');
define('SECURE_AUTH_SALT', 'fixture-secure-auth-salt');
define('LOGGED_IN_SALT', 'fixture-logged-in-salt');
define('NONCE_SALT', 'fixture-nonce-salt');

$table_prefix = 'wp_';

define('WP_DEBUG', false);
define('WP_HOME', 'http://site1');
define('WP_SITEURL', 'http://site1');

if (!defined('ABSPATH')) {
    define('ABSPATH', __DIR__ . '/');
}

require_once ABSPATH . 'wp-settings.php';