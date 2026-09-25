# Dashlytics Settings-Page Refactor

## Schritt 1: CSS-Grundlage konsolidieren
- [x] Admin-CSS für Inputs/Selects prüfen
- [x] Alert-Top-Spacing-Klasse `.dashlytics-alert--inline` hinzugefügt
- [x] Ungenutzte CSS-Regeln entfernt (KPI-Preview-Bar in admin.css, KPI-Metric-Cards in Svelte)
- [x] Color-Picker auf 44 px Höhe + gleichen Border/Border-Radius wie Inputs abgestimmt

## Schritt 2: Wiederverwendbare Svelte-Komponente
- [x] `app/components/DashlyticsInput.svelte` erstellt
- [x] In `DashlyticsSettings.svelte` importiert und für URL/Site-ID genutzt

## Schritt 3: Tabs zusammenlegen + KPI-Vorschau entfernen
- [x] `activeTab` Default auf `'settings'` geändert
- [x] Connection-Tab entfernt, Display-Tab zu "Einstellungen" umbenannt
- [x] Site-ID + Auth-Token in Chart-Einstellungen vor Diagramm-Typ verschoben
- [x] KPI-Vorschau-Komplettblock entfernt (inkl. reactive Helpers `previewStats`, `formatTime`, `formatPercent`, `previewMax`)
- [x] Live-Vorschau (Chart) beibehalten
- [x] Sticky Footer mit Reset-Button für Verbindungstest hinzugefügt

## Schritt 4: Sprache konsistent halten
- [x] `display` → `settings` i18n-Key in PHP geändert
- [x] `.po/.pot` Dateien aktualisiert und `.mo` neu generiert
- [x] Svelte-Fallbacks auf Deutsch belassen

## Schritt 5: Build & Qualität
- [x] `npm run build` ausgeführt
- [x] `composer run phpcs` ausgeführt
- [x] Diff reviewed
- [x] Plugin-ZIP via `build-plugin.sh` erstellt

## Offen / Nächste Schritte
- [x] Commit & Push (erledigt: `e966944`)
- [x] Handling für untracked PNGs im Repo-Root geprüft — Dateien sind nicht mehr vorhanden
- [ ] Browser-Verifikation auf WP-Admin Einstellungsseite
