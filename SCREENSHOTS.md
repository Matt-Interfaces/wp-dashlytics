# Dashlytics Screenshot Guide

> Anleitung, welche Screenshots für das WordPress.org Plugin-Verzeichnis und das README erstellt werden müssen – inkl. empfohlener Auflösung, Dateinamen und Inhalt.

## WordPress.org Anforderungen

- **Format:** PNG oder JPG.
- **Auflösung:** mindestens `1200×900px` (empfohlen `2880×1800px` für Retina).
- **Maximale Dateigröße:** 10 MB pro Bild.
- **Dateien in `/assets/`:** `screenshot-1.png`, `screenshot-2.png`, …
- **Maximal 4 Screenshots** empfohlen, kurze Legende pro Bild in die `readme.txt` unter `== Screenshots ==`.

## Empfohlene Screenshots

### screenshot-1.png – Dashboard Widget (Hauptansicht)

**Szenario:** WordPress Dashboard mit aktiviertem Dashlytics-Widget und echten Daten.

**Inhalt:**
- Liniendiagramm (Standard) mit Besuchen der letzten 30 Tage.
- Oben die vier Statistikkarten: Besuche, Seitenaufrufe, Besucher, Absprungrate.
- Zeitraum-Auswahl (z. B. „Letzte 30 Tage“).
- Export-Buttons PNG/PDF sichtbar.
- Hintergrund: Standard WordPress Dashboard (WP Admin Theme).

**Tipp:** Nutze die Option „Sichtbare Daten“, also mit echtem Verkehr, falls vorhanden.

### screenshot-2.png – Kreisdiagramm OS-Familien

**Szenario:** Gleiches Dashboard-Widget, aber auf Kreisdiagramm umgestellt.

**Inhalt:**
- Kreisdiagramm mit OS-Familien-Verteilung (Windows, macOS, iOS, Android, Linux, Sonstige).
- Farbige Legende rechts oder unten.
- Statistikkarten oben weiterhin sichtbar.
- Zeigt ein klares „Device-Daten“-Feature.

### screenshot-3.png – Einstellungen (Connection-Tab)

**Szenario:** Dashlytics Settings-Seite, Reiter „Verbindung“.

**Inhalt:**
- Verbindungsformular mit Matomo URL, Site ID, Auth Token.
- Toggle „Matomo for WordPress automatisch erkennen".
- „Verbindung testen"-Button.
- Erfolgsmeldung „Verbindung erfolgreich!".

### screenshot-4.png – Einstellungen (Anzeige-Tab mit Vorschau)

**Szenario:** Dashlytics Settings-Seite, Reiter „Anzeige".

**Inhalt:**
- Chart-Typ Auswahl (Linien / Balken / Kreis).
- Farbauswahl.
- Datumsbereich (z. B. letzte 30 Tage).
- Live-Vorschau des Widgets mit echten Beispieldaten unterhalb.

## Workflow zum Erstellen

1. **Testseite vorbereiten**
   - Frische WordPress-Instanz mit Dashlytics installieren und verbinden (am besten Matomo for WordPress oder Demo-Daten).
2. **Dashboard besuchen**
   - `/wp-admin/index.php`
3. **Fenstergröße**
   - Browser auf 1440 px Breite skalieren, Widget vollständig im Sichtbereich.
4. **Bildschirmfoto**
   - Ausschnitt auf das Dashlytics-Widget beschränken.
   - Sensible Token/URLs unkenntlich machen.
5. **Export/Bearbeitung**
   - PNG mit 2× Skalierung exportieren, z. B. 1440×900 → 2880×1800 px.
   - Kein Branding/Overlay im Bild, außer das eigene Logo ist Teil der UI.
6. **Benennen**
   - `screenshot-1.png`, `screenshot-2.png`, ... ins Plugin-Root-`/assets/`-Verzeichnis legen.
7. **readme.txt aktualisieren**
   ```
   == Screenshots ==
   1. Dashlytics-Chart mit Besuchen der letzten 30 Tage.
   2. OS-Familien-Verteilung als Kreisdiagramm.
   3. Verbindungseinstellungen mit automatischer Matomo-Erkennung.
   4. Anzeige-Einstellungen mit Live-Vorschau.
   ```

## Optional: Banner & Icon

Für WP.org solltest du im Plugin-Root ein `/assets/`-Verzeichnis mit folgenden Dateien ergänzen:

- `banner-772x250.png` – Plugin-Banner in der Verzeichnis-Liste.
- `icon-128x128.png` – Plugin-Icon (auch 256×256 als @2x).
- `icon-256x256.png` – Optional für hochauflösende Displays.

**Konventionen:**
- Kein rein weißer Hintergrund für Icons (sonst unsichtbar im WP-Admin).
- Banner max. 772×250 px, Icon quadratisch mit abgerundeten Ecken.

## Sprache

- WP.org Screenshots sollten primär auf **Englisch** sein.
- Für das deutsche Verzeichnis kannst du separate deutsche Screenshots verwenden oder englische beibehalten.
