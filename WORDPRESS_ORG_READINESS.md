# Dashlytics — WordPress.org Deployment Guide

This document describes how to move Dashlytics from GitHub Releases to the WordPress.org plugin directory.

Until WP.org approval is granted, the plugin uses **GitHub Releases + Plugin Update Checker (PUC)** for WordPress-native updates.

---

## 1. Current Status (v0.8.8)

| Element | Status | Note |
|---|---|---|
| Plugin version synchronized | ✅ Done | `0.8.8` in `dashlytics-matomo.php`, `build-plugin.sh`, `readme.txt` |
| ZIP build | ✅ Done | `dist/dashlytics-0.8.8.zip` |
| Update mechanism | ✅ Done | PUC v5 vendored, GitHub `Matt-Interfaces/wp-dashlytics` |
| Translation files | ✅ Done | `.pot` template + `de_DE` and `en_US` `.po/.mo` |
| PHPCS / WPCS | ✅ Done | Clean run, PUC excluded from linting |
| Automated GitHub release workflow | ✅ Done | `.github/workflows/release.yml` builds and attaches ZIP on tag push |
| Plugin icons | ✅ Done | `icon-128x128.png`, `icon-256x256.png` in `.wordpress-org/` |
| Plugin banners | ✅ Done | `banner-772x250.png`, `banner-1544x500.png` in `.wordpress-org/` |
| Social / OG image | ✅ Done | `dashlytics-og-1200x630.png` in `assets/images/` |
| Custom admin menu icon | ✅ Done | `dashlytics-icon.svg` in `assets/images/` |
| WordPress.org submission | ⏳ Open | Requires SVN repo, review, approval |

---

## 2. Automated GitHub Release Workflow

Pushing a Git tag `vX.Y.Z` triggers `.github/workflows/release.yml`:

1. Runs PHPCS and the Svelte build.
2. Executes `build-plugin.sh` to create `dist/dashlytics-X.Y.Z.zip`.
3. Creates a GitHub Release and attaches the ZIP automatically.

Local release commands:

```bash
# 1. Bump version in dashlytics-matomo.php, build-plugin.sh and readme.txt
# 2. Run quality gates
composer run phpcs
cd app && npm run build && cd ..
bash build-plugin.sh

# 3. Commit, tag and push
git add .
git commit -m "chore(release): bump version to 0.8.9"
git tag -a v0.8.9 -m "Release 0.8.9"
git push origin main
git push origin refs/tags/v0.8.9
```

The Plugin Update Checker in installed plugins checks `https://github.com/Matt-Interfaces/wp-dashlytics/releases/latest` and shows a native WordPress update notification when a newer release exists.

---

## 3. Code Quality & Standards

Run the checks locally:

```bash
composer install
composer run phpcs
```

Remaining tasks before WP.org submission:

- [ ] Remove remaining `console.log` / `console.error` / `console.warn` from the Svelte build.
- [ ] Security audit: nonces, capabilities, sanitization.
- [ ] Keep PHP compatible from 7.4 up to current 8.4.

---

## 4. Internationalization

- Use text domain `dashlytics` consistently.
- Update `languages/dashlytics.pot` before every release.
- Maintain `dashlytics-de_DE.po/mo` and `dashlytics-en_US.po/mo`.
- For additional languages, add `dashlytics-{locale}.po/mo` files and register them in `build-plugin.sh`.

---

## 5. readme.txt & Assets

- [ ] Keep `Tested up to` on the current WordPress version.
- [ ] Keep the description concise and factual.
- [x] Plugin icons: `icon-128x128.png`, `icon-256x256.png`.
- [x] Plugin banners: `banner-772x250.png`, `banner-1544x500.png`.
- [x] Screenshots: `screenshot-1.png` … `screenshot-4.png`. See `SCREENSHOTS.md`.
- [x] Ensure the released ZIP contains no `.gitignore`, `vendor/`, source maps or dev files.

### Asset folder mapping

| Repository folder | WordPress.org SVN folder | Purpose |
|---|---|---|
| `.wordpress-org/icon-*.png` | `assets/icon-*.png` | Plugin page icon |
| `.wordpress-org/banner-*.png` | `assets/banner-*.png` | Plugin page header banner |
| `assets/screenshot-*.png` | `assets/screenshot-*.png` | Plugin page screenshots |
| `dist/dashlytics-X.Y.Z.zip` contents | `trunk/` + `tags/X.Y.Z/` | The plugin itself |

---

## 6. Pre-submission Checklist

Before submitting at https://wordpress.org/plugins/developers/add/, confirm the following:

### Read and confirm

- [ ] Read the [Plugin Directory FAQ](https://wordpress.org/plugins/developers/faq/).
- [ ] Read the [Plugin Directory Guidelines](https://developer.wordpress.org/plugins/wordpress-org/detailed-plugin-guidelines/).
- [ ] Test the plugin with the [Plugin Check](https://wordpress.org/plugins/plugin-check/) plugin and resolve all indicated issues (except clear false-positives).

### Naming and ownership

- **Plugin name:** Dashlytics - Matomo Analytics Widget
- The name includes the project/brand identifier "Dashlytics" and is distinctive.
- It does not imply ownership of "Matomo"; it describes an integration with Matomo.
- The WordPress.org account submitting the plugin must accurately represent the plugin owner.

### Functionality restrictions (trialware)

- [ ] Confirm the plugin does **not** use paywalls, license gating, time-limited trials, usage cutoffs, or artificial limitations on built-in functionality.

### Not accepted plugin categories — compliance audit

Dashlytics does **not** fall into any of these categories. Code audit result:

| Rejection category | Dashlytics behavior | Compliant |
|---|---|---|
| Arbitrary PHP/JS code execution, file managers, AI code execution | No `eval()`, `exec()`, `shell_exec()`, `assert()`, `create_function()`, `file_put_contents()`, `base64_decode()`, or unserialize of user input. No code editors, file managers, or AI code generators. | ✅ |
| Downloading executable code from external sources | The plugin only fetches JSON analytics data from the user-configured Matomo API endpoint via `wp_remote_get()`. No executable code, binaries, or remote scripts are downloaded or executed. | ✅ |
| Functionality already well represented without differentiation | Dashlytics focuses specifically on displaying Matomo metrics inside the WordPress dashboard with privacy-first, self-hosted data. This is a differentiated use case compared to general analytics plugins. | ✅ |

### Additional Information field

Copy and paste the following text into the submission form:

```
Dashlytics is a lightweight dashboard widget that displays Matomo Analytics data directly inside the WordPress admin. It connects to a user-provided Matomo instance (self-hosted, Matomo Cloud, or the Matomo for WordPress plugin) via the official Matomo Reporting API, proxies requests server-side, and renders charts and metrics without adding frontend tracking code. The plugin does not execute arbitrary code, download external executables, or artificially restrict functionality. All REST endpoints use WordPress nonces and manage_options capability checks.
```


### Submission acknowledgement

- [ ] Understand that submissions must follow the guidelines; violations can lead to rejection or account restrictions.
- [ ] Understand that hosting is subject to continued compliance.

### Review facts

- Review time: typically **1–10 days**, usually within **5 business days**.
- The most common rejection reasons are:
  - Unescaped output
  - Unsanitized input
  - Missing nonces on form processing
- Dashlytics uses WordPress nonces, capability checks, and sanitization/escaping throughout.

### Plugin URL / slug

- The plugin URL will be derived from the `Plugin Name` header in `dashlytics-matomo.php`.
- Expected slug: `wp-dashlytics` (or `wp-dashlytics-2` if the slug is already taken).
- The slug can be changed **once** before the review begins.
- The display name can be updated later; the slug cannot be renamed after approval.

---

## 7. WordPress.org Deployment

### Prerequisites

- WordPress.org account: https://wordpress.org/
- SVN client installed (`svn --version`)
- Plugin approved by the WordPress.org review team

### Step 1: Submit the plugin for review

1. Go to https://wordpress.org/plugins/developers/add/
2. Upload `dist/dashlytics-0.8.8.zip` (maximum file size: 10 MB).
3. Confirm all checkboxes in the submission form.
4. Add any additional information that helps the review team.
5. Submit and wait for approval (typically a few days to a few weeks).

### Step 2: Check out the SVN repository

Once approved, WordPress.org creates an empty SVN repo at:

```
https://plugins.svn.wordpress.org/dashlytics
```

Check it out locally:

```bash
mkdir -p ~/wp-org-svn
cd ~/wp-org-svn
svn co https://plugins.svn.wordpress.org/dashlytics
cd dashlytics
```

You will see three default folders: `assets/`, `tags/`, `trunk/`.

### Step 3: Copy plugin files into `trunk/`

Build the plugin first, then copy the contents of the build directory (not the ZIP):

```bash
cd /Users/chooom/dev/wp-dashlytics
bash build-plugin.sh

# Copy plugin files into SVN trunk
rsync -av --delete dist/dashlytics/ ~/wp-org-svn/dashlytics/trunk/
```

### Step 4: Copy image assets into SVN `assets/`

```bash
rsync -av .wordpress-org/ ~/wp-org-svn/dashlytics/assets/
rsync -av assets/screenshot-*.png ~/wp-org-svn/dashlytics/assets/
```

### Step 5: Create a version tag

```bash
cd ~/wp-org-svn/dashlytics
svn cp trunk tags/0.8.8
```

### Step 6: Review and commit

```bash
cd ~/wp-org-svn/dashlytics
svn status
svn add --force .
svn ci -m "Initial release 0.8.8"
```

### Step 7: Set the stable tag

In `trunk/readme.txt`, ensure the header contains:

```
Stable tag: 0.8.8
```

The `Stable tag` tells WordPress.org which tagged version users should download.

---

## 8. Future Updates

After the initial release, each new version follows this flow:

```bash
# 1. Build locally
cd /Users/chooom/dev/wp-dashlytics
composer run phpcs
cd app && npm run build && cd ..
bash build-plugin.sh

# 2. Sync to SVN trunk
cd ~/wp-org-svn/dashlytics
svn up
rsync -av --delete /Users/chooom/dev/wp-dashlytics/dist/dashlytics/ trunk/

# 3. Sync assets if they changed
rsync -av /Users/chooom/dev/wp-dashlytics/.wordpress-org/ assets/

# 4. Create a new tag (replace X.Y.Z)
VERSION="0.8.9"
svn cp trunk "tags/${VERSION}"

# 5. Update stable tag in trunk/readme.txt
#    Change: Stable tag: X.Y.Z

# 6. Commit
svn add --force .
svn ci -m "Release ${VERSION}"
```

---

## 9. Plugin Update Checker status

The Plugin Update Checker has been removed from the distribution package for the WordPress.org submission:

1. PUC initialization removed from `dashlytics-matomo.php`.
2. `build-plugin.sh` no longer copies `includes/plugin-update-checker/` into the ZIP.
3. The vendored directory remains in the repository for historical reference but is excluded from WP.org builds.

After WP.org approval, updates are delivered through the official WordPress.org plugin directory.

---

## 10. Decisions

| Topic | Decision | Reason |
|---|---|---|
| Update server | WordPress.org plugin directory | Required for WP.org hosting; PUC removed from distribution |
| Own server / Vercel | No | Unnecessary overhead |
| n8n as update server | No | Not established, complex |
| PUC directory in repo | Keep for reference, exclude from ZIP | Vendored, read-only; avoids hand-editing and keeps history |

---

## 11. Next Actions

1. [ ] Verify the plugin on a clean WordPress test site.
2. [ ] Submit the plugin at https://wordpress.org/plugins/developers/add/
3. [ ] On the submission page, change the plugin slug to `dashlytics` before review begins so it matches the Text Domain.
4. [ ] After approval, deploy version `0.8.8` to SVN as described in Section 6.

---
*Document updated 2026-09-24 for Dashlytics v0.8.8.*
