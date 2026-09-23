# WP Dashlytics — Matomo Analytics Dashboard Widget

A lightweight WordPress plugin that brings your Matomo analytics data into the WordPress dashboard. View visitors, page views, bounce rate and trends without switching tabs.

## Highlights

- **Dashboard widget** with key metrics and trend charts
- **Interactive charts** — line, bar and pie views
- **Flexible date range** with date-picker support
- **Custom accent color** to match your brand
- **Auto-detect Matomo for WordPress** for one-click setup
- **PDF and PNG export** for quick reports
- **WordPress-native security** — REST endpoints with nonces and capability checks

## Requirements

- WordPress 5.8 or later
- PHP 7.4 or later
- Matomo installation: self-hosted, Matomo Cloud, or the *Matomo for WordPress* plugin

## Installation

1. Download the latest ZIP from the [releases page](https://github.com/mattinterfaces/wp-dashlytics/releases).
2. In WordPress, go to **Plugins → Add New → Upload Plugin** and activate it.
3. Open **WP Dashlytics** in the admin menu.
4. Connect Matomo automatically (if *Matomo for WordPress* is installed) or enter URL, Site ID and API token manually.

## Development

### Architecture

WP Dashlytics is built as a modern WordPress plugin around two Svelte 4 SPAs:

- **Dashboard Widget** (`app/DashboardWidget.svelte`) — rendered via `wp_dashboard_setup`, built to `app/public/build/dashboardwidget.js`.
- **Settings Page** (`app/DashlyticsSettings.svelte`) — rendered on `toplevel_page_dashlytics`, built to `app/public/build/settings.js` and `bundle.css`.

The PHP backend (`dashlytics-matomo.php`) uses the singleton pattern, exposes a custom REST namespace `dashlytics/v1`, proxies Matomo API requests, validates nonces and checks the `manage_options` capability.

### Build

```bash
cd app
npm install --legacy-peer-deps
npm run build
cd ..
bash build-plugin.sh
```

The resulting installable ZIP is written to `dist/dashlytics-{VERSION}.zip`.

### Dependency Notes

| Package | Version | Purpose | Maintenance |
|---------|---------|---------|-------------|
| `chart.js` | `^4.4.x` | Interactive charts | Current minor is stable |
| `jspdf` | `^2.5.x` | PDF report generation | Upgrade to `jspdf@4.x` requires separate QA |
| `svelte` | `^4.2.x` | UI framework | Migration to Svelte 5 is planned separately |
| `rollup` | `^4.x` | Bundler | Latest compatible minor |

The plugin uses the `dashlytics` text domain. A `.pot` template is available under `languages/`.

### Plugin Updates

Until the plugin is published on WordPress.org, updates are delivered through GitHub Releases via the vendored [Plugin Update Checker](https://github.com/YahnisElsts/plugin-update-checker). WordPress will show update notifications exactly like it does for repository plugins.

## License

GPL-2.0-or-later. See [LICENSE](LICENSE) for details.

## Author

Developed by [Matt Interfaces](https://www.matt-interfaces.ch).

- Website: [https://matt-interfaces.ch/wp-dashlytics](https://matt-interfaces.ch/wp-dashlytics)
- Support: [hoi@matt-interfaces.ch](mailto:hoi@matt-interfaces.ch)
- Support the project: [https://matt-interfaces.ch/zahlen](https://matt-interfaces.ch/zahlen)

