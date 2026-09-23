# Dashlytics Screenshot Guide

Guide for creating screenshots for the WordPress.org plugin directory and the plugin README, including recommended resolution, file names and content.

## WordPress.org Requirements

- **Format:** PNG or JPG.
- **Resolution:** at least `1200×900px` (recommended `2880×1800px` for Retina).
- **Max file size:** 10 MB per image.
- **Files in `/assets/`:** `screenshot-1.png`, `screenshot-2.png`, …
- **Maximum 4 screenshots** recommended, with a short caption per image in `readme.txt` under `== Screenshots ==`.

## Recommended Screenshots

### screenshot-1.png — Dashboard Widget (Main View)

**Scenario:** WordPress Dashboard with the Dashlytics widget active and real data.

**Content:**
- Line chart (default) showing visits for the last 30 days.
- Four statistic cards at the top: Visits, Page views, Visitors, Bounce rate.
- Date range selector (e.g. "Last 30 days").
- PNG/PDF export buttons visible.
- Background: standard WordPress Dashboard (WP Admin theme).

**Tip:** Use "real visible data" if actual traffic is available.

### screenshot-2.png — Pie Chart OS Families

**Scenario:** Same dashboard widget, switched to pie chart.

**Content:**
- Pie chart showing OS family distribution (Windows, macOS, iOS, Android, Linux, Other).
- Color legend to the right or bottom.
- Statistic cards remain visible at the top.
- Shows a clear "device data" feature.

### screenshot-3.png — Settings (Connection Tab)

**Scenario:** Dashlytics Settings page, "Connection" tab.

**Content:**
- Connection form with Matomo URL, Site ID, Auth Token.
- Toggle "Auto-detect Matomo for WordPress".
- "Test connection" button.
- Success message "Connection successful!".

### screenshot-4.png — Settings (Display Tab with Preview)

**Scenario:** Dashlytics Settings page, "Display" tab.

**Content:**
- Chart type selection (Line / Bar / Pie).
- Color picker.
- Date range (e.g. last 30 days).
- Live preview of the widget with real sample data below.

## Workflow

1. **Prepare test site**
   - Fresh WordPress instance with Dashlytics installed and connected (prefer Matomo for WordPress or demo data).
2. **Visit dashboard**
   - `/wp-admin/index.php`
3. **Window size**
   - Scale browser to 1440 px width, widget fully in viewport.
4. **Screenshot**
   - Crop to the Dashlytics widget only.
   - Blur sensitive tokens/URLs.
5. **Export / Edit**
   - Export PNG at 2× scale, e.g. 1440×900 → 2880×1800 px.
   - No branding/overlay in the image unless it is part of the UI.
6. **Naming**
   - Place `screenshot-1.png`, `screenshot-2.png`, ... in the plugin root `/assets/` directory.
7. **Update readme.txt**
   ```
   == Screenshots ==
   1. Dashlytics line chart showing visits for the last 30 days.
   2. OS family distribution as a pie chart.
   3. Connection settings with automatic Matomo detection.
   4. Display settings with live preview.
   ```

## Optional: Banner & Icon

For WP.org add a plugin root `/assets/` directory with these files:

- `banner-772x250.png` — plugin banner in the directory listing.
- `icon-128x128.png` — plugin icon (also provide 256×256 as @2x).
- `icon-256x256.png` — optional for high-resolution displays.

**Conventions:**
- Do not use a pure white icon background (it becomes invisible in WP Admin).
- Banner maximum 772×250 px, icon square with rounded corners.

## Language

- WP.org screenshots should primarily be in **English**.
- For the German directory you may use separate German screenshots or keep the English ones.
