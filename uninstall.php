<?php
/**
 * Dashlytics Uninstall
 *
 * Runs when the plugin is uninstalled.
 * Removes all plugin data from the database.
 *
 * @package Dashlytics
 * @since 1.0.0
 */

// Security check - only run when WordPress triggers uninstall
if ( ! defined( 'WP_UNINSTALL_PLUGIN' ) ) {
	exit;
}

// Delete plugin options
delete_option( 'dashlytics_settings' );
delete_option( 'dashlytics_review_dismissed' );
delete_option( 'dashlytics_review_next' );

// Delete legacy options from version 0.3 if present
delete_option( 'tokenauth' );
delete_option( 'apiurl' );
delete_option( 'siteidarl' );

// Remove capabilities
$dashlytics_role = get_role( 'administrator' );
if ( $dashlytics_role ) {
	$dashlytics_role->remove_cap( 'manage_dashlytics' );
}

// Delete transients if present
delete_transient( 'dashlytics_analytics_cache' );

// Multisite support
if ( is_multisite() ) {
	global $wpdb;

	$blog_ids = $wpdb->get_col( "SELECT blog_id FROM $wpdb->blogs" );

	foreach ( $blog_ids as $dashlytics_blog_id ) {
		switch_to_blog( $dashlytics_blog_id );

		delete_option( 'dashlytics_settings' );
		delete_option( 'tokenauth' );
		delete_option( 'apiurl' );
		delete_option( 'siteidarl' );

		restore_current_blog();
	}
}
