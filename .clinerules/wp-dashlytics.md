# Dashlytics Project Rules

This repository is a **WordPress plugin** that renders Matomo Analytics data inside the WordPress dashboard. It is **not** a SvelteKit app, a generic Node project, or part of the Divi 5 landing-page work in `divi5/`.

## Stack

| Layer | Technology |
|---|---|
| Backend | PHP 7.4+ (WordPress plugin API, REST, capabilities, nonces) |
| Main class | `includes/class-dashlytics.php` |
| Frontend | Svelte 4 SPAs built with Rollup |
| Dashboard widget | `app/DashboardWidget.svelte` → `app/public/build/dashboardwidget.js` |
| Settings page | `app/DashlyticsSettings.svelte` → `app/public/build/settings.js` |
| Styles | `assets/css/admin.css`, `assets/css/widget.css` |
| Admin JS | `assets/js/admin.js` |
| i18n | Text domain `dashlytics-matomo-analytics-widget`; `languages/dashlytics-matomo-analytics-widget.pot` + `dashlytics-matomo-analytics-widget-de_DE` / `dashlytics-matomo-analytics-widget-en_US` `.po/.mo` |
| Updates | Vendored Plugin Update Checker pointing to GitHub `Matt-Interfaces/wp-dashlytics` |
| Code standards | WPCS via `composer.json` + `phpcs.xml.dist` |
| CI | GitHub Actions `.github/workflows/ci.yml` (PHPCS + Svelte build) |
| CD | GitHub Actions `.github/workflows/release.yml` (build + attach ZIP to release) |

## Repository boundaries

- `divi5/` is an isolated zone for Divi 5 landing pages. **Never** reference it from the plugin code or build pipeline.
- Do **not** run `npm run build` or `composer` against `divi5/`.
- `vendor/`, `node_modules/`, `build/`, `dist/`, and `app/public/build/` are ignored and must never be committed.
- `showcase/` and documentation files (`SCREENSHOTS.md`, `WORDPRESS_ORG_READINESS.md`) may be committed for repository docs, but they are **not** copied into the distribution ZIP.

## Git workflow

- **Commit messages are in English**, use [Conventional Commits](https://www.conventionalcommits.org/).
- Examples: `chore(repo): ...`, `feat(widget): ...`, `fix(settings): ...`, `docs(readme): ...`.
- Keep commits atomic and focused on one concern.
- Tag releases with `vX.Y.Z` and push tags (`git push origin refs/tags/vX.Y.Z`).
- The canonical remote is `git@github.com:Matt-Interfaces/wp-dashlytics.git`.

## Build process

```bash
cd app
npm install --legacy-peer-deps
npm run build
cd ..
bash build-plugin.sh
```

Result: `dist/dashlytics-matomo-analytics-widget-{VERSION}.zip`.

## Quality gate before push

Run these before committing changes to PHP or Svelte sources:

```bash
composer run phpcs
cd app && npm run build && cd ..
bash build-plugin.sh
```

PHPCS must be clean. The vendored `includes/plugin-update-checker/` is excluded from linting and must not be hand-edited.

## i18n rules

- Use `__( 'String', 'dashlytics-matomo-analytics-widget' )` in PHP; do not hardcode untranslated UI strings.
- Source strings are currently German; `dashlytics-matomo-analytics-widget-de_DE.po` maps msgstr to msgid, `dashlytics-matomo-analytics-widget-en_US.po` provides English translations.
- When adding new translatable strings, regenerate/extend `.pot`, `.po` and `.mo` files and update `build-plugin.sh` if needed.

## Update checker

The Plugin Update Checker (PUC) vendored library remains in `includes/plugin-update-checker/` for historical reference, but it is **not copied into the distribution ZIP** and its initialization code has been removed from `dashlytics-matomo.php` for the WordPress.org submission. After WP.org approval, updates are delivered through the official WordPress.org plugin directory.
