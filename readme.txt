=== WP Dashlytics - Matomo Analytics Widget ===
Contributors: matt-interfaces
Donate link: https://matt-interfaces.ch/zahlen
Tags: matomo, analytics, dashboard, statistics, widget, piwik, tracking
Requires at least: 5.8
Tested up to: 6.7
Stable tag: 0.8.8
Requires PHP: 7.4
License: GPLv2 or later
License URI: https://www.gnu.org/licenses/gpl-2.0.html

Optimize your website success. Integrate Matomo Analytics seamlessly into your WordPress dashboard. WP Dashlytics — your analytics companion!

== Description ==

Optimize your website success. Integrate Matomo Analytics seamlessly into your WordPress website. Maximize your performance with WP Dashlytics — your ultimate analytics companion! Download and try it for free.

**WP Dashlytics** brings your Matomo Analytics data directly into your WordPress dashboard. No more switching between tabs — see your most important metrics at a glance and make data-driven decisions.

= Features =

* **Dashboard widget**: Elegant widget with visitor numbers, page views and more
* **Interactive charts**: Choose between line, bar and pie charts
* **Flexible date range**: Analyze any time period
* **Customizable colors**: Adapt the design to your brand
* **Auto-detection**: Automatic connection with Matomo for WordPress
* **Modern UI**: User-friendly interface following WordPress design standards
* **Secure**: Uses the WordPress REST API with nonce verification

= Matomo Integration =

WP Dashlytics works with:

* **Matomo for WordPress** (recommended) - automatic detection and connection
* **External Matomo installation** - connect to any Matomo instance
* **Matomo Cloud** - full support for hosted solutions

= Displayed Metrics =

* Unique visitors
* Page views
* Bounce rate
* Average session duration
* Visitor trends over time

= Customization Options =

* 4 different chart types
* Freely selectable primary color
* Configurable default time ranges
* Responsive design for all screen sizes

== Installation ==

= Automatic Installation =

1. Go to **Plugins > Add New** in your WordPress admin
2. Search for "WP Dashlytics"
3. Click **Install Now** and then **Activate**

= Manual Installation =

1. Download the plugin ZIP
2. Go to **Plugins > Add New > Upload Plugin**
3. Select the ZIP file and click **Install Now**
4. Activate the plugin

= Configuration =

1. Go to **WP Dashlytics** in the admin menu
2. If Matomo for WordPress is installed: click "Connect automatically"
3. Or enter manually:
   - Matomo URL (e.g. https://analytics.your-domain.com)
   - Site ID (usually 1)
   - API token (from Matomo settings)
4. Click "Test connection"
5. Save the settings

== Frequently Asked Questions ==

= Where do I find my Matomo API token? =

1. Open your Matomo dashboard
2. Go to Settings > Personal > Security
3. Under "Auth Token" you will find your token or can create a new one

= Does the plugin work with Matomo Cloud? =

Yes! Simply enter your Matomo Cloud URL (e.g. https://your-company.matomo.cloud) together with your API token.

= Can I track multiple websites? =

Currently WP Dashlytics supports one website per WordPress installation. The Site ID can be adjusted in the settings.

= Is the plugin GDPR compliant? =

WP Dashlytics itself does not store visitor data. It only displays data from your Matomo installation. Make sure your Matomo configuration is GDPR compliant.

= The widget shows no data =

1. Check whether the connection in the settings is successful
2. Make sure your API token has the correct permissions
3. Verify that Matomo has data for the selected time period

== Screenshots ==

1. Combined dashboard widget with line chart and key metrics
2. Pie chart showing visitor operating-system families
3. Connection settings page for the Matomo API token and URL
4. PNG/PDF export options from the WordPress dashboard widget

== Changelog ==

= 0.8.3 =
* Migrated repository references to Matt-Interfaces organization.
* All documentation translated to English.
* Added project rules under `.clinerules/wp-dashlytics.md`.

= 0.8.2 =
* Integrated WordPress-native updates via GitHub Releases until the WordPress.org directory is active.

= 0.8.1 =
* Corrected donate link to https://matt-interfaces.ch/zahlen.

= 0.8.0 =
* PDF/PNG export now respects the user-defined accent color instead of fixed colors
* Report badge in export is now twice as wide for better readability
* Version number in settings header is now pulled dynamically from plugin metadata
* Translation template (.pot) included in distribution package
* Readme updated for WordPress 6.7
* Preparation for WordPress.org submission (PHPCS, CI, i18n)

= 0.3.0 =
* Complete redesign of the user interface
* New modern settings page with WordPress admin UI
* Automatic detection of Matomo for WordPress
* Improved security with nonce verification
* REST API with proper permission checks
* 4 different chart types
* Responsive dashboard widget
* Statistic cards with key metrics
* Internationalization prepared
* WordPress Coding Standards compliant

== Upgrade Notice ==

= 0.8.0 =
Updates export styling to the selected accent color. Please review your settings after updating.

== Privacy Policy ==

WP Dashlytics itself does not collect user data. The plugin only displays statistics from your Matomo installation.

Stored data:
* Matomo URL (in WordPress options)
* Site ID (in WordPress options)
* API token (encrypted in WordPress options)
* Display settings (in WordPress options)

For privacy information about Matomo visit: https://matomo.org/privacy/

== Additional Info ==

= Developer =

* Plugin page: https://matt-interfaces.ch/wp-dashlytics
* GitHub: https://github.com/Matt-Interfaces/wp-dashlytics
* Website: https://www.matt-interfaces.ch
* Support: hoi@matt-interfaces.ch

= Contribute =

Pull requests are welcome! Visit our GitHub repository.

= Support =

If you like the plugin, I appreciate:
* A positive rating on WordPress.org
* A coffee: https://matt-interfaces.ch/zahlen
