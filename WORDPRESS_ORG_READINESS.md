# WP Dashlytics – WordPress.org Readiness Roadmap

Dieses Dokument beschreibt den Schritt-für-Schritt-Pfad, um WP Dashlytics ins WordPress.org Plugin Directory zu überführen. Bis dahin nutzt das Plugin **GitHub Releases + Plugin Update Checker** für WordPress-native Updates.

## 1. Aktueller Stand (v0.8.2)

| Element | Status | Hinweis |
|---|---|---|
| Donate-Link korrigiert | ✅ Erledigt | `https://matt-interfaces.ch/zahlen` überall ersetzt |
| Versionen synchronisiert | ✅ Erledigt | `0.8.2` in allen relevanten Dateien |
| ZIP-Build | ✅ Erledigt | `dist/dashlytics-0.8.2.zip` |
| Update-Mechanismus | ✅ Erledigt | Plugin Update Checker v5.7 vendored |
| WordPress.org Einreichung | ⏳ Offen | Erfordert SVN-Repo, Assets, Review |

## 2. Codequalität & Standards

- [ ] WPCS / PHPCS sauber durchlaufen lassen
  ```bash
  composer install
  composer run phpcs
  ```
- [ ] Verbleibende `console.log` / `console.error` / `console.warn` aus dem Svelte-Build entfernen (aktuell 10 Vorkommen)
- [ ] Sicherheit auditieren: Nonces, Capabilities, Sanitization
- [ ] PHP 7.4 bis aktuell 8.4 kompatibel halten

## 3. Internationalisierung

- [ ] Textdomain `dashlytics` konsistent verwenden
- [ ] `languages/dashlytics.pot` vor jedem Release aktualisieren

## 4. readme.txt & Assets

- [ ] `Tested up to` auf aktuelle WordPress-Version halten (aktuell `6.7`)
- [ ] Marketing-Fluff in Beschreibung reduzieren
- [ ] Plugin-Icon erstellen: `icon-128x128.png`, `icon-256x256.png`
- [ ] Banner erstellen: `banner-772x250.png`, `banner-1544x500.png`
- [ ] Screenshots erstellen und benennen: `screenshot-1.png` etc.
- [ ] ZIP enthält keinen `.gitignore`, `vendor/`, Sourcemaps oder Dev-Dateien

## 5. WordPress.org Einreichung

### Schritt 1: Account vorbereiten
- Account unter https://wordpress.org/ mit passendem Benutzernamen
- SVN-Passwort in den Account-Einstellungen setzen

### Schritt 2: Plugin einreichen
- URL: https://wordpress.org/plugins/developers/add/
- Plugin-Name, Beschreibung, Readme einfügen
- Auf Freigabe warten (Tage bis Wochen)

### Schritt 3: SVN befüllen
```bash
svn co https://plugins.svn.wordpress.org/dashlytics
cp -r dist/dashlytics/* trunk/
svn cp trunk tags/0.8.2
svn add assets/* trunk/* tags/0.8.2
svn ci -m "Initial release 0.8.2"
```

### Schritt 4: Stable tag pflegen
- In `trunk/readme.txt`: `Stable tag: 0.8.2`
- Tag `tags/0.8.2/` muss existieren

### Schritt 5: Zukünftige Updates
1. Version erhöhen und bauen
2. `trunk/` aktualisieren
3. `svn cp trunk tags/X.Y.Z`
4. `svn ci -m "Release X.Y.Z"`

## 6. Entscheidungen

| Thema | Entscheidung | Begründung |
|---|---|---|
| Update-Server bis WordPress.org | GitHub Releases + PUC | Kostenlos, De-facto-Standard, native UX |
| Eigener Server / Vercel | Nein | Unnötiger Overhead |
| n8n als Update-Server | Nein | Nicht etabliert, komplex |
| PUC entfernen wann? | Nach WordPress.org-Freigabe | WordPress.org ist primärer Kanal |

## 7. Nächste Aktionen

1. Diesen Stand commiten/taggen als `v0.8.2` und GitHub-Release erstellen
2. In WordPress-Testinstanz hochladen und Update prüfen
3. `0.8.3` mit entfernten `console.*` Aufrufen für WordPress.org-Readiness
4. WordPress.org-Einreichung vorbereiten

---
*Dokument erstellt am 23.09.2026 für WP Dashlytics.*
