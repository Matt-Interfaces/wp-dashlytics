# WP Dashlytics — WordPress.org Readiness Roadmap

This document describes the step-by-step path to move WP Dashlytics into the WordPress.org plugin directory. Until then the plugin uses **GitHub Releases + Plugin Update Checker** for WordPress-native updates.

## 1. Current Status (v0.8.3)

| Element | Status | Note |
|---|---|---|
| Donate link corrected | ✅ Done | `https://matt-interfaces.ch/zahlen` replaced everywhere |
| Versions synchronized | ✅ Done | `0.8.3` in all relevant files |
| ZIP build | ✅ Done | `dist/dashlytics-0.8.3.zip` |
| Update mechanism | ✅ Done | Plugin Update Checker v5 vendored, GitHub `Matt-Interfaces/wp-dashlytics` |
| Translation files | ✅ Done | `.pot` template + `de_DE` and `en_US` `.po/.mo` |
| PHPCS / WPCS | ✅ Done | Clean run, PUC excluded from linting |
| WordPress.org submission | ⏳ Open | Requires SVN repo, assets, review |

## 2. Code Quality & Standards

Run the checks locally:

```bash
composer install
composer run phpcs
```

Remaining tasks before submission:

- [ ] Remove remaining `console.log` / `console.error` / `console.warn` from the Svelte build (currently 10 occurrences).
- [ ] Security audit: nonces, capabilities, sanitization.
- [ ] Keep PHP compatible from 7.4 up to current 8.4.

## 3. Internationalization

- Use text domain `dashlytics` consistently.
- Update `languages/dashlytics.pot` before every release.
- Maintain `dashlytics-de_DE.po/mo` and `dashlytics-en_US.po/mo`.
- For additional languages, add `dashlytics-{locale}.po/mo` files and register them in `build-plugin.sh`.

## 4. readme.txt & Assets

- [ ] Keep `Tested up to` on the current WordPress version (currently `6.7`).
- [ ] Reduce marketing fluff in the description.
- [ ] Create plugin icon: `icon-128x128.png`, `icon-256x256.png`.
- [ ] Create banner: `banner-772x250.png`, `banner-1544x500.png`.
- [ ] Create and name screenshots: `screenshot-1.png`, etc. See `SCREENSHOTS.md`.
- [ ] Ensure the released ZIP contains no `.gitignore`, `vendor/`, source maps or dev files.

## 5. WordPress.org Submission

### Step 1: Prepare Account
- Create an account at https://wordpress.org/ with the appropriate username.
- Set the SVN password in the account settings.

### Step 2: Submit Plugin
- URL: https://wordpress.org/plugins/developers/add/
- Enter plugin name, description and readme.
- Wait for approval (days to weeks).

### Step 3: Populate SVN
```bash
svn co https://plugins.svn.wordpress.org/dashlytics
cp -r dist/dashlytics/* trunk/
svn cp trunk tags/0.8.3
svn add assets/* trunk/* tags/0.8.3
svn ci -m "Initial release 0.8.3"
```

### Step 4: Maintain Stable Tag
- In `trunk/readme.txt`: `Stable tag: 0.8.3`
- Tag `tags/0.8.3/` must exist.

### Step 5: Future Updates
1. Bump version and build.
2. Update `trunk/`.
3. `svn cp trunk tags/X.Y.Z`
4. `svn ci -m "Release X.Y.Z"`

## 6. Decisions

| Topic | Decision | Reason |
|---|---|---|
| Update server until WP.org | GitHub Releases + PUC | Free, de-facto standard, native UX |
| Own server / Vercel | No | Unnecessary overhead |
| n8n as update server | No | Not established, complex |
| Remove PUC when? | After WP.org approval | WP.org becomes primary channel |

## 7. Next Actions

1. Create the `Matt-Interfaces/wp-dashlytics` repository on GitHub and push the current main branch + `v0.8.3` tag.
2. Create a GitHub Release for `v0.8.3` and attach `dist/dashlytics-0.8.3.zip`.
3. Upload to a WordPress test instance and verify the update notification works.
4. Remove `console.*` calls from the Svelte build for WP.org readiness.
5. Prepare WordPress.org submission.

---
*Document created 2026-09-23 for WP Dashlytics.*
