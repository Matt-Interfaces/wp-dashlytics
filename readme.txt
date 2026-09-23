=== WP Dashlytics - Matomo Analytics Widget ===
Contributors: matt-interfaces
Donate link: https://matt-interfaces.ch/zahlen
Tags: matomo, analytics, dashboard, statistics, widget, piwik, tracking
Requires at least: 5.8
Tested up to: 6.7
Stable tag: 0.8.3
Requires PHP: 7.4
License: GPLv2 or later
License URI: https://www.gnu.org/licenses/gpl-2.0.html

Optimieren Sie Ihren Website-Erfolg. Integrieren Sie Matomo Analytics nahtlos in Ihr WordPress-Dashboard. WP Dashlytics – Ihr Analytics-Begleiter!

== Description ==

Optimieren Sie Ihren Website-Erfolg. Integrieren Sie mühelos Matomo Analytics in Ihre WordPress-Website. Maximieren Sie Ihre Performance mit WP Dashlytics – Ihrem ultimativen Analytics-Begleiter! Jetzt kostenlos downloaden und ausprobieren.

**WP Dashlytics** bringt Ihre Matomo Analytics Daten direkt in Ihr WordPress Dashboard. Keine Notwendigkeit mehr, zwischen verschiedenen Tabs zu wechseln – sehen Sie Ihre wichtigsten Metriken auf einen Blick und treffen Sie datenbasierte Entscheidungen.

= 🚀 Features =

* **Dashboard Widget**: Elegantes Widget mit Besucherzahlen, Seitenaufrufen und mehr
* **Interaktive Charts**: Wählen Sie zwischen Linien-, Balken- und Kreisdiagrammen
* **Flexibler Zeitraum**: Analysieren Sie beliebige Zeiträume
* **Anpassbare Farben**: Passen Sie das Design an Ihre Marke an
* **Auto-Erkennung**: Automatische Verbindung mit Matomo for WordPress
* **Moderne UI**: Benutzerfreundliche Oberfläche nach WordPress Design Standards
* **Sicher**: Nutzt WordPress REST API mit Nonce-Verifizierung

= 🔗 Matomo Integration =

WP Dashlytics funktioniert mit:

* **Matomo for WordPress** (empfohlen) - Automatische Erkennung und Verbindung
* **Externe Matomo Installation** - Verbinden Sie sich mit jeder Matomo-Instanz
* **Matomo Cloud** - Volle Unterstützung für gehostete Lösungen

= 📊 Angezeigte Metriken =

* Eindeutige Besucher
* Seitenaufrufe
* Absprungrate
* Durchschnittliche Verweildauer
* Besuchertrends über Zeit

= 🎨 Anpassungsoptionen =

* 4 verschiedene Diagramm-Typen
* Frei wählbare Hauptfarbe
* Konfigurierbare Standardzeiträume
* Responsive Design für alle Bildschirmgrößen

== Installation ==

= Automatische Installation =

1. Gehen Sie zu **Plugins > Installieren** in Ihrem WordPress Admin
2. Suchen Sie nach "WP Dashlytics"
3. Klicken Sie auf **Jetzt installieren** und dann **Aktivieren**

= Manuelle Installation =

1. Laden Sie die Plugin-ZIP herunter
2. Gehen Sie zu **Plugins > Installieren > Plugin hochladen**
3. Wählen Sie die ZIP-Datei und klicken Sie auf **Jetzt installieren**
4. Aktivieren Sie das Plugin

= Konfiguration =

1. Gehen Sie zu **WP Dashlytics** im Admin-Menü
2. Falls Matomo for WordPress installiert ist: Klicken Sie auf "Automatisch verbinden"
3. Oder geben Sie manuell ein:
   - Matomo URL (z.B. https://analytics.ihre-domain.de)
   - Site ID (normalerweise 1)
   - API Token (aus Matomo Einstellungen)
4. Klicken Sie auf "Verbindung testen"
5. Speichern Sie die Einstellungen

== Frequently Asked Questions ==

= Wo finde ich meinen Matomo API Token? =

1. Öffnen Sie Ihr Matomo Dashboard
2. Gehen Sie zu Einstellungen > Persönlich > Sicherheit
3. Unter "Auth Token" finden Sie Ihren Token oder können einen neuen erstellen

= Funktioniert das Plugin mit Matomo Cloud? =

Ja! Geben Sie einfach Ihre Matomo Cloud URL ein (z.B. https://ihre-firma.matomo.cloud) zusammen mit Ihrem API Token.

= Kann ich mehrere Websites tracken? =

Aktuell unterstützt WP Dashlytics eine Website pro WordPress-Installation. Die Site ID kann in den Einstellungen angepasst werden.

= Ist das Plugin DSGVO-konform? =

WP Dashlytics selbst speichert keine Besucherdaten. Es zeigt lediglich Daten aus Ihrer Matomo-Installation an. Stellen Sie sicher, dass Ihre Matomo-Konfiguration DSGVO-konform ist.

= Das Widget zeigt keine Daten an =

1. Prüfen Sie, ob die Verbindung in den Einstellungen erfolgreich ist
2. Stellen Sie sicher, dass Ihr API Token die richtigen Berechtigungen hat
3. Überprüfen Sie, ob Matomo Daten für den gewählten Zeitraum hat

== Screenshots ==

1. Dashboard Widget mit Statistiken und Chart
2. Einstellungsseite - Verbindung
3. Einstellungsseite - Darstellung
4. Chart-Typ Auswahl
5. Automatische Matomo-Erkennung

== Changelog ==

= 0.8.3 =
* Alle Code-Kommentare ins Englische übersetzt.
* README.md auf professionelles Englisch überarbeitet.
* divi5-Ordner aus dem Repository ausgeschlossen.

= 0.8.2 =
* WordPress-native Updates über GitHub Releases integriert (bis WordPress.org-Verzeichnis aktiv ist).

= 0.8.1 =
* Donate-Link auf https://matt-interfaces.ch/zahlen korrigiert.

= 0.8.0 =
* PDF/PNG Export berücksichtigt die nutzerdefinierte Akzentfarbe statt fester Farbwerte
* Report Badge im Export ist jetzt doppelt so breit für bessere Lesbarkeit
* Versionsnummer im Settings-Header wird dynamisch aus den Plugin-Metadaten bezogen
* Sprachvorlage (.pot) im Distribution-Paket enthalten
* Readme auf WordPress 7.1 aktualisiert
* Vorbereitung für WordPress.org Einreichung (PHPCS, CI, i18n)

= 0.3.0 =
* Komplettes Redesign der Benutzeroberfläche
* Neue moderne Settings-Seite mit WordPress Admin UI
* Automatische Erkennung von Matomo for WordPress
* Verbesserte Sicherheit mit Nonce-Verifizierung
* REST API mit ordentlicher Permission-Prüfung
* 4 verschiedene Chart-Typen
* Responsive Dashboard Widget
* Statistik-Karten mit Key Metrics
* Internationalisierung vorbereitet
* WordPress Coding Standards konform

== Upgrade Notice ==

= 0.8.0 =
Aktualisiert den Export-Styling auf die gewählte Akzentfarbe. Bitte überprüfen Sie nach dem Update Ihre Einstellungen.

== Privacy Policy ==

WP Dashlytics selbst sammelt keine Benutzerdaten. Das Plugin zeigt lediglich Statistiken aus Ihrer Matomo-Installation an.

Gespeicherte Daten:
* Matomo URL (in WordPress Options)
* Site ID (in WordPress Options)
* API Token (verschlüsselt in WordPress Options)
* Anzeigeeinstellungen (in WordPress Options)

Für Datenschutzinformationen zu Matomo besuchen Sie: https://matomo.org/privacy/

== Additional Info ==

= Entwickler =

* Plugin-Seite: https://matt-interfaces.ch/wp-dashlytics
* GitHub: https://github.com/Matt-Interfaces/wp-dashlytics
* Website: https://www.matt-interfaces.ch
* Support: hoi@matt-interfaces.ch

= Mitwirken =

Pull Requests sind willkommen! Besuchen Sie unser GitHub Repository.

= Unterstützung =

Wenn Ihnen das Plugin gefällt, freue ich mich über:
* Eine positive Bewertung auf WordPress.org
* Einen Kaffee: https://matt-interfaces.ch/zahlen

