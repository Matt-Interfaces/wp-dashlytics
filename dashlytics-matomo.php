<?php
/**
 * Plugin Name: Dashlytics - Matomo Analytics Widget
 * Plugin URI: https://matt-interfaces.ch/wp-dashlytics
 * Description: View Matomo Analytics data directly in your WordPress dashboard. Simple integration, data-driven decisions.
 * Version: 0.8.8
 * Requires at least: 5.8
 * Requires PHP: 7.4
 * Author: Christopher Matt
 * Author URI: https://www.matt-interfaces.ch
 * License: GPL-2.0-or-later
 * License URI: https://www.gnu.org/licenses/gpl-2.0.html
 * Text Domain: dashlytics
 * Domain Path: /languages
 */

// Prevent direct access
if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

// Plugin constants
define( 'DASHLYTICS_VERSION', '0.8.8' );
define( 'DASHLYTICS_PLUGIN_FILE', __FILE__ );
define( 'DASHLYTICS_PLUGIN_URL', plugin_dir_url( __FILE__ ) );
define( 'DASHLYTICS_PLUGIN_PATH', plugin_dir_path( __FILE__ ) );
define( 'DASHLYTICS_PLUGIN_BASENAME', plugin_basename( __FILE__ ) );

/**
 * Load main plugin class
 */
require_once DASHLYTICS_PLUGIN_PATH . 'includes/class-dashlytics.php';

/**
 * Initialize plugin
 */
function dashlytics_init() {
	return Dashlytics::get_instance();
}

/**
 * Run plugin
 */
add_action( 'plugins_loaded', 'dashlytics_init' );
