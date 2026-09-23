<script>
import { onMount } from "svelte";
import { fade } from "svelte/transition";

// Global WordPress data
const wpData = window.dashlyticsAdmin || {};
const restUrl = wpData.restUrl || '/wp-json/dashlytics/v1/';
const nonce = wpData.nonce || '';
const pluginUrl = wpData.pluginUrl || '';
const version = wpData.version || '';
const matomoDetected = wpData.matomoDetected || { installed: false };
const i18n = wpData.i18n || {};

// State
let settings = {
    matomo_url: '',
    site_id: 1,
    token_auth: '',
    chart_type: 'line',
    chart_color: '#2271b1',
    date_range: 30,
    auto_detect_matomo: true
};

let loading = true;
let saving = false;
let testing = false;
let autoConnecting = false;
let connectionStatus = null; // null, 'success', 'error'
let connectionMessage = '';
let toast = null;
let activeTab = 'connection';
let showToken = false;
let autoConnected = false;

// Preview data
let previewLoading = false;
let previewError = null;
let previewData = [];

// Mask token for display
function maskToken(token) {
    if (!token || token.length < 8) return '••••••••';
    return token.substring(0, 4) + '••••••••' + token.substring(token.length - 4);
}

const chartTypes = [
    { value: 'line', label: i18n.line || 'Liniendiagramm', icon: '📈' },
    { value: 'bar', label: i18n.bar || 'Balkendiagramm', icon: '📊' },
    { value: 'pie', label: i18n.pie || 'Kreisdiagramm', icon: '🥧' }
];

const dateRanges = [
    { value: 7, label: i18n.last7days || 'Letzte 7 Tage' },
    { value: 14, label: i18n.last14days || 'Letzte 14 Tage' },
    { value: 30, label: i18n.last30days || 'Letzte 30 Tage' },
    { value: 60, label: i18n.last60days || 'Letzte 60 Tage' },
    { value: 90, label: i18n.last90days || 'Letzte 90 Tage' }
];

// Persist helper (without UI feedback)
async function persistSettings() {
    try {
        const response = await fetch(`${restUrl}settings`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-WP-Nonce': nonce
            },
            body: JSON.stringify(settings)
        });
        return response.ok;
    } catch (error) {
        console.error('Save error:', error);
        return false;
    }
}

// API Funktionen
async function fetchSettings() {
    try {
        const response = await fetch(`${restUrl}settings`, {
            headers: {
                'X-WP-Nonce': nonce
            }
        });

        if (response.ok) {
            const data = await response.json();
            settings = { ...settings, ...data };

            // Determine header status once after loading
            await initializeConnectionState();
        }
    } catch (error) {
        console.error('Settings load error:', error);
    } finally {
        loading = false;
    }
}

async function initializeConnectionState() {
    // Matomo for WordPress automatisch verbinden
    if (matomoDetected.installed && settings.auto_detect_matomo) {
        await useMatomoWP(true);
        return;
    }

    // Manuelle Konfiguration testen
    if (settings.matomo_url && (settings.token_auth || settings.auto_detect_matomo)) {
        await testConnection(true);
        return;
    }

    // Not configured yet
    connectionStatus = null;
    connectionMessage = '';
}

async function saveSettings() {
    if (saving) return;
    saving = true;

    try {
        const ok = await persistSettings();

        if (ok) {
            showToast(i18n.saveSuccess || 'Einstellungen gespeichert!', 'success');
        } else {
            showToast(i18n.saveError || 'Fehler beim Speichern.', 'error');
        }
    } finally {
        saving = false;
    }
}

// Reset connection test status
function resetConnectionTest() {
    connectionStatus = null;
    connectionMessage = '';
}

// Preview: load real data from the analytics or device endpoint
function getPreviewDateRange() {
    const days = parseInt(settings.date_range, 10) || 30;
    const end = new Date();
    const start = new Date();
    start.setDate(end.getDate() - days);
    return {
        start: start.toISOString().slice(0, 10),
        end: end.toISOString().slice(0, 10)
    };
}

async function loadPreviewData() {
    if (previewLoading) return;
    previewLoading = true;
    previewError = null;
    previewData = [];

    const dates = getPreviewDateRange();
    const dateParam = `${dates.start},${dates.end}`;

    try {
        const isPie = settings.chart_type === 'pie';
        const endpoint = isPie ? `${restUrl}devices?date=${dateParam}` : `${restUrl}analytics?period=day&date=${dateParam}`;
        // Short artificial delay prevents flickering on fast load times
        await new Promise(resolve => setTimeout(resolve, 300));
        const response = await fetch(endpoint, {
            headers: { 'X-WP-Nonce': nonce }
        });

        if (!response.ok) {
            const errorData = await response.json();
            throw new Error(errorData.message || i18n.previewError || 'Fehler beim Laden der Vorschau');
        }

        const data = await response.json();

        if (isPie) {
            previewData = Array.isArray(data) ? data : [];
        } else {
            previewData = (Array.isArray(data) ? data : []).map(day => ({
                label: day.date || '',
                value: day.nb_visits || day.nb_uniq_visitors || 0
            }));
        }
    } catch (err) {
        console.error('Preview error:', err);
        previewError = err.message;
        previewData = [];
    } finally {
        previewLoading = false;
    }
}

// Auto-reload preview when changes occur
$: if (settings.chart_type !== undefined && settings.date_range !== undefined) {
    loadPreviewData();
}

// Limit selected data points to a maximum of 7
$: previewSlice = previewData.slice(-7);
$: previewMax = previewSlice.length ? Math.max(...previewSlice.map(d => d.value), 1) : 100;

// Line-chart points for SVG
$: previewLinePoints = previewSlice.map((d, i) => {
    const count = previewSlice.length || 1;
    const x = 10 + (i / Math.max(count - 1, 1)) * 120;
    const y = 70 - ((d.value / previewMax) * 60);
    return `${x},${y}`;
}).join(' ');

// Kreisdiagramm-Farbverlauf
$: previewPieGradient = (() => {
    if (!previewData.length) return 'transparent';
    const total = previewData.reduce((sum, d) => sum + (d.value || 0), 0) || 1;
    let acc = 0;
    return previewData.map((d, i) => {
        const start = acc;
        acc += ((d.value || 0) / total) * 100;
        const color = i === 0 ? settings.chart_color : (i % 2 === 0 ? settings.chart_color + 'cc' : '#d1d5db');
        return `${color} ${start.toFixed(2)}% ${acc.toFixed(2)}%`;
    }).join(', ');
})();

// Test connection to Matomo
async function testConnection(silent = false) {
    if (testing) return;
    testing = true;
    connectionStatus = null;

    try {
        const response = await fetch(`${restUrl}test-connection`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-WP-Nonce': nonce
            },
            body: JSON.stringify({
                matomo_url: settings.matomo_url,
                token_auth: settings.token_auth,
                site_id: settings.site_id,
                auto_detect_matomo: settings.auto_detect_matomo
            })
        });

        const data = await response.json();

        if (data.success) {
            connectionStatus = 'success';
            connectionMessage = data.message || '';
            if (!silent) {
                showToast(i18n.connectionSuccess || 'Verbindung erfolgreich!', 'success');
            }
        } else {
            connectionStatus = 'error';
            connectionMessage = data.message || data.data?.message || i18n.connectionError || 'Verbindung fehlgeschlagen.';
            if (!silent) {
                showToast(i18n.connectionError || 'Verbindung fehlgeschlagen.', 'error');
            }
        }
    } catch (error) {
        connectionStatus = 'error';
        connectionMessage = error.message;
        if (!silent) {
            showToast(i18n.connectionError || 'Verbindung fehlgeschlagen.', 'error');
        }
    } finally {
        testing = false;
    }
}

async function detectToken() {
    try {
        const response = await fetch(`${restUrl}detect-token`, {
            headers: {
                'X-WP-Nonce': nonce
            }
        });
        
        const data = await response.json();
        
        if (data.success && data.token) {
            settings.token_auth = data.token;
            showToast(i18n.tokenGenerated || 'Token automatisch erkannt!', 'success');
            return { useWpAuth: false, token: data.token };
        } else if (data.use_wp_auth) {
            settings.token_auth = ''; // Clear any existing token
            showToast(data.message || i18n.wpAuthUsed || 'WordPress Authentifizierung wird verwendet', 'success');
            return { useWpAuth: true };
        }
        
        return { useWpAuth: false };
    } catch (error) {
        console.error('Token detection failed:', error);
        showToast(i18n.detectTokenFailed || 'Token-Erkennung fehlgeschlagen', 'error');
        return { useWpAuth: false, error: error.message };
    }
}

function showToast(message, type = 'info') {
    toast = { message, type };
    setTimeout(() => {
        toast = null;
    }, 3000);
}

async function useMatomoWP(silent = false) {
    if (!matomoDetected.installed) {
        if (!silent) {
            showToast(i18n.mfWNotInstalled || 'Matomo for WordPress ist nicht installiert.', 'error');
        }
        return;
    }

    if (autoConnecting) return;
    autoConnecting = true;
    connectionStatus = null;
    connectionMessage = '';

    try {
        settings.matomo_url = '';
        settings.auto_detect_matomo = true;

        // Detect token and handle the response
        const result = await detectToken();

        if (result.useWpAuth) {
            // WordPress authentication will be used (no token needed)
            settings.token_auth = '';
            autoConnected = true;
            connectionStatus = 'success';
            connectionMessage = i18n.autoConnected || 'WordPress Authentifizierung aktiv - kein Token erforderlich';
        } else if (settings.token_auth) {
            // A token was found and set
            autoConnected = true;
            connectionStatus = 'success';
            connectionMessage = i18n.autoConnectedToken || 'Automatisch mit Matomo for WordPress verbunden (Token erkannt)';
        } else {
            // No token and no WordPress auth
            autoConnected = false;
            connectionStatus = 'error';
            connectionMessage = i18n.noAuthMethod || 'Konnte keine gültige Authentifizierungsmethode erkennen';
            if (!silent) {
                showToast(i18n.connectionErrorManual || 'Verbindungsfehler - bitte manuell konfigurieren', 'error');
            }
            autoConnecting = false;
            return;
        }

        // Persist the automatic configuration
        await persistSettings();

        if (!silent) {
            showToast(connectionMessage, 'success');
        }
    } catch (error) {
        autoConnected = false;
        connectionStatus = 'error';
        connectionMessage = error.message || i18n.autoConnectionFailed || 'Automatische Verbindung fehlgeschlagen';
        if (!silent) {
            showToast(i18n.autoConnectionFailed || 'Automatische Verbindung fehlgeschlagen', 'error');
        }
    } finally {
        autoConnecting = false;
    }
}

onMount(() => {
    fetchSettings();
});
</script>

<div class="dashlytics-settings">
    <!-- Header -->
    <header class="dashlytics-header">
        <div class="dashlytics-header-content">
            <div class="dashlytics-logo">📊</div>
            <div>
                <h1>WP Dashlytics</h1>
                <p>{i18n.tagline || 'Matomo Widget Dashboard für WordPress'}</p>
            </div>
        </div>
        <div class="dashlytics-header-actions">
            <span class="dashlytics-version">{version ? 'v' + version : ''}</span>
            {#if testing || autoConnecting}
                <span class="dashlytics-status dashlytics-status--checking">
                    <span class="dashlytics-status-dot dashlytics-status-dot--spin"></span>
                    {i18n.checking || 'Verbindung wird geprüft…'}
                </span>
            {:else if connectionStatus === 'success'}
                <span class="dashlytics-status dashlytics-status--connected" title={connectionMessage}>
                    <span class="dashlytics-status-dot"></span>
                    {matomoDetected.installed && settings.auto_detect_matomo ? (i18n.matomoWp || 'Matomo WP') : (i18n.connected || 'Verbunden')}
                </span>
            {:else if connectionStatus === 'error'}
                <span class="dashlytics-status dashlytics-status--disconnected" title={connectionMessage}>
                    <span class="dashlytics-status-dot"></span>
                    {i18n.notConnected || 'Nicht verbunden'}
                </span>
            {:else}
                <span class="dashlytics-status dashlytics-status--pending">
                    <span class="dashlytics-status-dot"></span>
                    {i18n.configurationRequired || 'Konfiguration erforderlich'}
                </span>
            {/if}
        </div>
    </header>

    <!-- Matomo Detection Banner -->
    {#if matomoDetected.installed}
        <div 
            class="dashlytics-detection"
            class:dashlytics-detection--success={connectionStatus === 'success' && settings.auto_detect_matomo}
            class:dashlytics-detection--error={connectionStatus === 'error' && settings.auto_detect_matomo}
        >
            <div class="dashlytics-detection-icon">
                {#if autoConnecting}
                    <span class="dashlytics-detection-spinner"></span>
                {:else if connectionStatus === 'success' && settings.auto_detect_matomo}
                    ✓
                {:else if connectionStatus === 'error' && settings.auto_detect_matomo}
                    ✗
                {:else}
                    🔍
                {/if}
            </div>
            <div class="dashlytics-detection-content">
                {#if autoConnecting}
                    <h3>{i18n.connectingMfW || 'Matomo for WordPress verbinden…'}</h3>
                    <p>{i18n.connectingMfWDesc || 'Authentifizierungsmethode wird ermittelt und Einstellungen werden übernommen.'}</p>
                {:else if connectionStatus === 'success' && settings.auto_detect_matomo}
                    <h3>{i18n.connectedMfW || 'Matomo for WordPress verbunden!'}</h3>
                    <p>{connectionMessage || i18n.connectedMfWDesc || 'WP Dashlytics nutzt die WordPress-interne Matomo-Installation.'}</p>
                {:else if connectionStatus === 'error' && settings.auto_detect_matomo}
                    <h3>{i18n.autoConnectionFailed || 'Automatische Verbindung fehlgeschlagen'}</h3>
                    <p>{connectionMessage || i18n.autoConnectionFailedDesc || 'Bitte prüfen Sie die Matomo-Einstellungen oder hinterlegen Sie Daten für eine manuelle Verbindung.'}</p>
                {:else}
                    <h3>{i18n.mfWDetected || 'Matomo for WordPress erkannt!'}</h3>
                    <p>{i18n.mfWDetectedDesc || 'Das Matomo Plugin ist installiert. WP Dashlytics kann automatisch verbunden werden.'}</p>
                {/if}
            </div>
            {#if !(connectionStatus === 'success' && settings.auto_detect_matomo)}
                <button 
                    class="dashlytics-btn dashlytics-btn--success"
                    class:dashlytics-btn--loading={autoConnecting}
                    on:click={() => useMatomoWP()}
                    disabled={autoConnecting}
                    aria-busy={autoConnecting}
                    aria-live="polite"
                    type="button"
                >
                    {autoConnecting ? (i18n.connecting || 'Verbinde…') : (i18n.connectAutomatically || 'Automatisch verbinden')}
                </button>
            {:else}
                <button 
                    class="dashlytics-btn dashlytics-btn--secondary"
                    on:click={() => {
                        settings.auto_detect_matomo = false;
                        connectionStatus = null;
                        connectionMessage = '';
                        autoConnected = false;
                    }}
                    type="button"
                >
                    {i18n.disableAutomatically || 'Automatisch deaktivieren'}
                </button>
            {/if}
        </div>
    {/if}

    <!-- Tabs -->
    <div class="dashlytics-tabs" role="tablist" aria-label={i18n.settingsTabs || 'Einstellungsbereiche'}>
        <button 
            class="dashlytics-tab" 
            class:dashlytics-tab--active={activeTab === 'connection'}
            on:click={() => activeTab = 'connection'}
            role="tab"
            aria-selected={activeTab === 'connection'}
            aria-controls="dashlytics-tab-panel"
            id="dashlytics-tab-connection"
            type="button"
        >
            🔗 {i18n.connection || 'Verbindung'}
        </button>
        <button 
            class="dashlytics-tab" 
            class:dashlytics-tab--active={activeTab === 'display'}
            on:click={() => activeTab = 'display'}
            role="tab"
            aria-selected={activeTab === 'display'}
            aria-controls="dashlytics-tab-panel"
            id="dashlytics-tab-display"
            type="button"
        >
            🎨 {i18n.display || 'Darstellung'}
        </button>
        <button 
            class="dashlytics-tab" 
            class:dashlytics-tab--active={activeTab === 'help'}
            on:click={() => activeTab = 'help'}
            role="tab"
            aria-selected={activeTab === 'help'}
            aria-controls="dashlytics-tab-panel"
            id="dashlytics-tab-help"
            type="button"
        >
            ❓ {i18n.help || 'Hilfe'}
        </button>
    </div>

    {#if loading}
        <div class="dashlytics-card" role="status" aria-live="polite" aria-label={i18n.loadingSettings || 'Einstellungen werden geladen'}>
            <div class="dashlytics-card-body">
                <div class="dashlytics-skeleton" style="height: 24px; margin-bottom: 16px;"></div>
                <div class="dashlytics-skeleton" style="height: 120px;"></div>
            </div>
        </div>
    {:else}
    {#key activeTab}
    <div class="dashlytics-tab-panel" id="dashlytics-tab-panel" role="tabpanel" aria-labelledby="dashlytics-tab-{activeTab}" in:fade={{ duration: 200, delay: 50 }}>
        <!-- Connection Tab -->
        {#if activeTab === 'connection'}
            <div class="dashlytics-grid">
                <div class="dashlytics-card dashlytics-card--flex">
                    <div class="dashlytics-card-header">
                        <h2 class="dashlytics-card-title">
                            <span class="dashlytics-card-icon">🔌</span>
                            {i18n.apiConnection || 'API Verbindung'}
                        </h2>
                    </div>
                    <div class="dashlytics-card-body dashlytics-card-body--grow">
                        {#if !matomoDetected.installed}
                            <div class="dashlytics-form-group">
                                <label class="dashlytics-label" for="dashlytics-matomo-url">
                                    {i18n.matomoUrl || 'Matomo URL'}
                                    <span class="dashlytics-label-hint">({i18n.matomoUrlHint || 'Ihre Matomo Installation'})</span>
                                </label>
                                <input 
                                    type="url" 
                                    class="dashlytics-input" 
                                    bind:value={settings.matomo_url}
                                    placeholder={i18n.matomoUrlPlaceholder || 'https://analytics.ihre-domain.de'}
                                />
                            </div>
                        {/if}

                        <div class="dashlytics-form-group">
                            <label class="dashlytics-label" for="dashlytics-site-id">
                                {i18n.siteId || 'Site ID'}
                                <span class="dashlytics-label-hint">({i18n.siteIdHint || 'Standard: 1'})</span>
                            </label>
                            <input 
                                type="number" 
                                class="dashlytics-input" 
                                bind:value={settings.site_id}
                                min="1"
                                style="max-width: 120px;"
                            />
                        </div>

                        <div class="dashlytics-form-group">
                            <label class="dashlytics-label" for="dashlytics-auth-token">
                                {i18n.authToken || 'Auth Token'}
                                <span class="dashlytics-label-hint">
                                    {#if autoConnected && settings.token_auth}
                                        ({i18n.autoDetected || 'automatisch erkannt'})
                                    {:else if autoConnected && !settings.token_auth}
                                        ({i18n.wpAuth || 'WordPress Authentifizierung'})
                                    {:else}
                                        ({i18n.apiAccessToken || 'API Zugriffstoken'})
                                    {/if}
                                </span>
                            </label>
                            <div class="dashlytics-input-group">
                                <input 
                                    type="text"
                                    class="dashlytics-input" 
                                    class:dashlytics-input--readonly={autoConnected || (matomoDetected.installed && settings.token_auth)}
                                    value={showToken ? settings.token_auth : (settings.token_auth ? maskToken(settings.token_auth) : '')}
                                    placeholder={i18n.authTokenPlaceholder || 'Ihr Matomo API Token'}
                                    readonly={autoConnected || (matomoDetected.installed && settings.token_auth)}
                                    on:input={(e) => { if (!autoConnected && !(matomoDetected.installed && settings.token_auth)) settings.token_auth = e.target.value; }}
                                />
                                <button 
                                    type="button"
                                    class="dashlytics-btn dashlytics-btn--icon"
                                    on:click={() => showToken = !showToken}
                                    title={showToken ? (i18n.hideToken || 'Token verbergen') : (i18n.showToken || 'Token anzeigen')}
                                >
                                    <span class="dashicons" class:dashicons-visibility={!showToken} class:dashicons-hidden={showToken}></span>
                                </button>
                                {#if matomoDetected.installed && !autoConnected && !settings.token_auth}
                                    <button 
                                        type="button"
                                        class="dashlytics-btn dashlytics-btn--secondary"
                                        on:click={detectToken}
                                        title={i18n.autoDetect || 'Token automatisch erkennen'}
                                    >
                                        🔍 Auto
                                    </button>
                                {/if}
                            </div>
                            {#if autoConnected && settings.token_auth}
                                <p class="dashlytics-field-info">
                                    ✓ {i18n.tokenAutoImported || 'Token wurde automatisch von Matomo for WordPress übernommen'}
                                </p>
                            {:else if autoConnected && !settings.token_auth}
                                <p class="dashlytics-field-info">
                                    ✓ {i18n.autoConnected || 'WordPress Authentifizierung aktiv - kein Token erforderlich'}
                                </p>
                            {/if}
                        </div>

                        {#if connectionMessage}
                            <div class="dashlytics-alert" class:dashlytics-alert--success={connectionStatus === 'success'} class:dashlytics-alert--error={connectionStatus === 'error'}>
                                <span class="dashlytics-alert-icon">
                                    {connectionStatus === 'success' ? '✓' : '✗'}
                                </span>
                                <div class="dashlytics-alert-content">
                                    <p>{connectionMessage}</p>
                                </div>
                            </div>
                        {/if}
                    </div>
                    <div class="dashlytics-card-footer dashlytics-card-footer--sticky">
                        {#if connectionStatus !== null}
                            <button 
                                type="button"
                                class="dashlytics-btn dashlytics-btn--tertiary"
                                on:click={resetConnectionTest}
                                title={i18n.resetConnectionTest || 'Verbindungstest zurücksetzen'}
                            >
                                🔄 {i18n.reset || 'Zurücksetzen'}
                            </button>
                        {/if}
                        <button 
                            type="button"
                            class="dashlytics-btn dashlytics-btn--secondary"
                            on:click={testConnection}
                            disabled={testing}
                            class:dashlytics-btn--loading={testing}
                            aria-busy={testing}
                            aria-live="polite"
                        >
                            {testing ? '' : '🔄'} {i18n.testConnection || 'Verbindung testen'}
                        </button>
                        <button 
                            type="button"
                            class="dashlytics-btn dashlytics-btn--primary"
                            on:click={saveSettings}
                            disabled={saving}
                            class:dashlytics-btn--loading={saving}
                            aria-busy={saving}
                            aria-live="polite"
                        >
                            {saving ? '' : '💾'} {i18n.save || 'Speichern'}
                        </button>
                    </div>
                </div>

                <!-- Quick Stats Preview -->
                <div class="dashlytics-card">
                    <div class="dashlytics-card-header">
                        <h2 class="dashlytics-card-title">
                            <span class="dashlytics-card-icon">📈</span>
                            {i18n.preview || 'Vorschau'}
                        </h2>
                    </div>
                    <div class="dashlytics-card-body">
                        <div class="dashlytics-preview">
                            <div class="dashlytics-preview-chart" aria-live="polite">
                                {#if previewLoading}
                                    <div class="dashlytics-preview-status" role="status">
                                        <span class="dashlytics-preview-spinner" aria-hidden="true"></span>
                                        {i18n.loadingPreview || 'Lade Vorschau…'}
                                    </div>
                                {:else if previewError || !previewSlice.length}
                                    <div class="dashlytics-preview-status" role="status">{i18n.noPreviewData || 'Keine Vorschaudaten'}</div>
                                {:else}
                                    {#each previewSlice as d, i}
                                        <div 
                                            class="dashlytics-preview-bar" 
                                            style="height: {(d.value / previewMax) * 100}%; background: {settings.chart_color}; animation-delay: {i * 0.1}s;"
                                            aria-hidden="true"
                                        ></div>
                                    {/each}
                                {/if}
                            </div>
                            <p style="color: #666; font-size: 13px;">
                                {chartTypes.find(t => t.value === settings.chart_type)?.label || i18n.chart || 'Diagramm'}
                            </p>
                        </div>
                    </div>
                </div>
            </div>
        {/if}

        <!-- Display Tab -->
        {#if activeTab === 'display'}
            <div class="dashlytics-grid">
                <div class="dashlytics-card">
                    <div class="dashlytics-card-header">
                        <h2 class="dashlytics-card-title">
                            <span class="dashlytics-card-icon">📊</span>
                            {i18n.chartSettings || 'Chart Einstellungen'}
                        </h2>
                    </div>
                    <div class="dashlytics-card-body">
                        <div class="dashlytics-form-group">
                            <span class="dashlytics-label" id="dashlytics-chart-type-label">{i18n.chartType || 'Diagramm-Typ'}</span>
                            <div class="dashlytics-chart-types">
                                {#each chartTypes as type}
                                    <label class="dashlytics-chart-type" class:active={settings.chart_type === type.value}>
                                        <input 
                                            type="radio" 
                                            name="chart_type" 
                                            value={type.value}
                                            bind:group={settings.chart_type}
                                        />
                                        <span class="dashlytics-chart-type-icon">{type.icon}</span>
                                        <span class="dashlytics-chart-type-label">{type.label}</span>
                                    </label>
                                {/each}
                            </div>
                        </div>

                        <div class="dashlytics-form-group">
                            <label class="dashlytics-label" for="dashlytics-chart-color">{i18n.primaryColor || 'Hauptfarbe'}</label>
                            <div class="dashlytics-color-picker">
                                <input id="dashlytics-chart-color" 
                                    type="color" 
                                    class="dashlytics-color-input"
                                    bind:value={settings.chart_color}
                                />
                                <span class="dashlytics-color-value">{settings.chart_color}</span>
                            </div>
                        </div>

                        <div class="dashlytics-form-group">
                            <label class="dashlytics-label" for="dashlytics-date-range">{i18n.defaultPeriod || 'Standard Zeitraum'}</label>
                            <select id="dashlytics-date-range" class="dashlytics-select" bind:value={settings.date_range}>
                                {#each dateRanges as range}
                                    <option value={range.value}>{range.label}</option>
                                {/each}
                            </select>
                        </div>
                    </div>
                    <div class="dashlytics-card-footer">
                        <button 
                            class="dashlytics-btn dashlytics-btn--primary"
                            on:click={saveSettings}
                            disabled={saving}
                            class:dashlytics-btn--loading={saving}
                        >
                            {saving ? '' : '💾'} {i18n.save || 'Speichern'}
                        </button>
                    </div>
                </div>

                <!-- Live Preview -->
                <div class="dashlytics-card">
                    <div class="dashlytics-card-header">
                        <h2 class="dashlytics-card-title">
                            <span class="dashlytics-card-icon">👁️</span>
                            {i18n.livePreview || 'Live Vorschau'}
                        </h2>
                    </div>
                    <div class="dashlytics-card-body">
                        <div class="dashlytics-preview" style="background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);">
                            <div class="dashlytics-preview-chart" aria-live="polite">
                                {#if previewLoading}
                                    <div class="dashlytics-preview-status" role="status">
                                        <span class="dashlytics-preview-spinner" aria-hidden="true"></span>
                                        {i18n.loadingPreview || 'Lade Vorschau…'}
                                    </div>
                                {:else if previewError || !previewSlice.length}
                                    <div class="dashlytics-preview-status">{i18n.noPreviewData || 'Keine Vorschaudaten'}</div>
                                {:else if settings.chart_type === 'line'}
                                    <!-- Line chart with real points -->
                                    <svg viewBox="0 0 140 80" style="width: 100%; height: 100px;">
                                        {#if previewLinePoints}
                                            <polyline 
                                                fill="none" 
                                                stroke="{settings.chart_color}" 
                                                stroke-width="2"
                                                points={previewLinePoints}
                                            />
                                        {/if}
                                        {#each previewSlice as d, i}
                                            {@const x = 10 + (i / Math.max(previewSlice.length - 1, 1)) * 120}
                                            {@const y = 70 - ((d.value / previewMax) * 60)}
                                            <circle cx={x} cy={y} r="4" fill="{settings.chart_color}"/>
                                        {/each}
                                    </svg>
                                {:else if settings.chart_type === 'bar'}
                                    <!-- Bar chart with real data -->
                                    {#each previewSlice as d, i}
                                        <div 
                                            class="dashlytics-preview-bar" 
                                            style="height: {(d.value / previewMax) * 100}%; background: {settings.chart_color}; border-radius: 4px 4px 0 0; width: 20px; animation-delay: {i * 0.1}s;"
                                        ></div>
                                    {/each}
                                {:else}
                                    <!-- Pie chart with real shares -->
                                    <div style="width: 120px; height: 120px; border-radius: 50%; background: conic-gradient({previewPieGradient});"></div>
                                {/if}
                            </div>
                            <p style="margin: 16px 0 0; color: #666; font-size: 13px;">
                                {chartTypes.find(t => t.value === settings.chart_type)?.label || i18n.chart || 'Diagramm'}
                            </p>
                        </div>
                    </div>
                </div>
            </div>
        {/if}

        <!-- Help Tab -->
        {#if activeTab === 'help'}
            <div class="dashlytics-grid dashlytics-grid--full">
                <div class="dashlytics-card">
                    <div class="dashlytics-card-header">
                        <h2 class="dashlytics-card-title">
                            <span class="dashlytics-card-icon">📖</span>
                            {i18n.quickstart || 'Schnellstart Anleitung'}
                        </h2>
                    </div>
                    <div class="dashlytics-card-body">
                        <div class="dashlytics-help-steps">
                            {#if matomoDetected.installed}
                                <!-- Simplified guide for Matomo for WordPress -->
                                <div class="dashlytics-help-step">
                                    <span class="dashlytics-help-step-number">1</span>
                                    <div class="dashlytics-help-step-content">
                                        <strong>{i18n.connectAutomatically || 'Automatisch verbinden'}</strong>
                                        <p>{i18n.connectAutomaticallyHelp || 'Matomo for WordPress wurde erkannt! Klicken Sie oben auf "Automatisch verbinden" - WP Dashlytics übernimmt alle Einstellungen automatisch.'}</p>
                                    </div>
                                </div>
                                <div class="dashlytics-help-step">
                                    <span class="dashlytics-help-step-number">2</span>
                                    <div class="dashlytics-help-step-content">
                                        <strong>{i18n.useDashboardWidget || 'Dashboard Widget nutzen'}</strong>
                                        <p>{i18n.useDashboardWidgetHelp || 'Nach der Verbindung erscheint das Statistik-Widget auf Ihrem WordPress Dashboard. Sie können Zeitraum, Diagramm-Typ und Farbe direkt im Widget anpassen.'}</p>
                                    </div>
                                </div>
                                <div class="dashlytics-help-step">
                                    <span class="dashlytics-help-step-number">3</span>
                                    <div class="dashlytics-help-step-content">
                                        <strong>{i18n.exportReports || 'Reports exportieren'}</strong>
                                        <p>{i18n.exportReportsHelp || 'Nutzen Sie den "Report" Button im Widget um Ihre Statistiken als PDF-Bericht oder PNG-Bild zu exportieren.'}</p>
                                    </div>
                                </div>
                            {:else}
                                <!-- Guide for external Matomo installation -->
                                <div class="dashlytics-help-step">
                                    <span class="dashlytics-help-step-number">1</span>
                                    <div class="dashlytics-help-step-content">
                                        <strong>{i18n.installMfW || 'Matomo for WordPress installieren'}</strong>
                                        <p>{i18n.installMfWHelp || 'Für die beste Integration installieren Sie das kostenlose "Matomo Analytics" Plugin aus dem WordPress Plugin-Verzeichnis.'}</p>
                                    </div>
                                </div>
                                <div class="dashlytics-help-step">
                                    <span class="dashlytics-help-step-number">2</span>
                                    <div class="dashlytics-help-step-content">
                                        <strong>{i18n.externalMfW || 'Alternative: Externe Matomo Installation'}</strong>
                                        <p>{i18n.externalMfWHelp || 'Falls Sie Matomo extern hosten, tragen Sie Ihre Matomo-URL, Site-ID und einen API-Token unter "Verbindung" ein.'}</p>
                                    </div>
                                </div>
                                <div class="dashlytics-help-step">
                                    <span class="dashlytics-help-step-number">3</span>
                                    <div class="dashlytics-help-step-content">
                                        <strong>{i18n.testConnection || 'Verbindung testen'}</strong>
                                        <p>{i18n.testConnectionHelp || 'Klicken Sie auf "Verbindung testen" um sicherzustellen, dass alles funktioniert.'}</p>
                                    </div>
                                </div>
                            {/if}
                        </div>

                        <!-- Features overview -->
                        <div class="dashlytics-features-section">
                            <h3 class="dashlytics-features-title">{i18n.widgetFeatures || 'Widget Funktionen'}</h3>
                            <div class="dashlytics-feature-cards">
                                <div class="dashlytics-feature-card">
                                    <div class="dashlytics-feature-card-icon" style="background: linear-gradient(135deg, #3b82f6 0%, #1d4ed8 100%);">
                                        <span class="dashicons dashicons-chart-bar"></span>
                                    </div>
                                    <div class="dashlytics-feature-card-content">
                                        <h4>{i18n.statsCards || 'Statistik-Karten'}</h4>
                                        <p>{i18n.statsCardsDesc || 'Besucher, Seitenaufrufe, Absprungrate und Verweildauer auf einen Blick'}</p>
                                    </div>
                                </div>
                                <div class="dashlytics-feature-card">
                                    <div class="dashlytics-feature-card-icon" style="background: linear-gradient(135deg, #10b981 0%, #059669 100%);">
                                        <span class="dashicons dashicons-chart-line"></span>
                                    </div>
                                    <div class="dashlytics-feature-card-content">
                                        <h4>{i18n.interactiveCharts || 'Interaktive Charts'}</h4>
                                        <p>{i18n.interactiveChartsDesc || 'Linie, Balken oder Kreis - wählen Sie Ihre Darstellung'}</p>
                                    </div>
                                </div>
                                <div class="dashlytics-feature-card">
                                    <div class="dashlytics-feature-card-icon" style="background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%);">
                                        <span class="dashicons dashicons-calendar-alt"></span>
                                    </div>
                                    <div class="dashlytics-feature-card-content">
                                        <h4>{i18n.flexiblePeriod || 'Flexibler Zeitraum'}</h4>
                                        <p>{i18n.flexiblePeriodDesc || 'Beliebigen Zeitraum per Datumswahl im Widget auswählen'}</p>
                                    </div>
                                </div>
                                <div class="dashlytics-feature-card">
                                    <div class="dashlytics-feature-card-icon" style="background: linear-gradient(135deg, #8b5cf6 0%, #7c3aed 100%);">
                                        <span class="dashicons dashicons-download"></span>
                                    </div>
                                    <div class="dashlytics-feature-card-content">
                                        <h4>{i18n.exportReady || 'PDF & PNG Export'}</h4>
                                        <p>{i18n.exportReadyDesc || 'Statistiken als professionellen Report oder Bild exportieren'}</p>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <div class="dashlytics-support">
                            <a href="https://matt-interfaces.ch/wp-dashlytics" target="_blank" rel="noopener noreferrer" class="dashlytics-support-link" aria-label="Plugin-Seite für WP Dashlytics - Matomo Analytics Widget besuchen">
                                <span class="dashlytics-support-link-icon">🌐</span>
                                <span>{i18n.pluginWebsite || 'Plugin-Website'}</span>
                            </a>
                            <a href="https://github.com/Matt-Interfaces/wp-dashlytics" target="_blank" rel="noopener noreferrer" class="dashlytics-support-link" aria-label="GitHub Repository für WP Dashlytics öffnen">
                                <span class="dashlytics-support-link-icon">📦</span>
                                <span>{i18n.githubRepository || 'GitHub Repository'}</span>
                            </a>
                            <a href="https://developer.matomo.org/api-reference/reporting-api" target="_blank" rel="noopener noreferrer" class="dashlytics-support-link">
                                <span class="dashlytics-support-link-icon">📚</span>
                                <span>{i18n.matomoApiDocs || 'Matomo API Docs'}</span>
                            </a>
                            <a href="https://matt-interfaces.ch/zahlen" target="_blank" rel="noopener noreferrer" class="dashlytics-support-link">
                                <span class="dashlytics-support-link-icon">☕</span>
                                <span>{i18n.supportDeveloper || 'Entwickler unterstützen'}</span>
                            </a>
                            <a href="https://www.matt-interfaces.ch" target="_blank" rel="noopener noreferrer" class="dashlytics-support-link">
                                <img 
                                    src="{pluginUrl}assets/images/matt-interface-logo-v3-100x40px.png" 
                                    alt="Matt Interfaces" 
                                    class="dashlytics-support-link-logo"
                                    width="24"
                                    height="10"
                                    loading="lazy"
                                />
                                <span>matt-interfaces.ch</span>
                            </a>
                        </div>
                    </div>
                </div>
            </div>
        {/if}
    </div>
    {/key}
    {/if}

    <!-- Toast Notification -->
    {#if toast}
        <div class="dashlytics-toast" class:dashlytics-toast--success={toast.type === 'success'} class:dashlytics-toast--error={toast.type === 'error'}>
            {toast.message}
    </div>
    {/if}
</div>

<style>
    .dashlytics-settings {
        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Oxygen-Sans, Ubuntu, Cantarell, "Helvetica Neue", sans-serif;
    }

    .dashlytics-chart-types {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(140px, 1fr));
        gap: 12px;
    }

    .dashlytics-chart-type {
        display: flex;
        flex-direction: column;
        align-items: center;
        gap: 8px;
        padding: 16px;
        background: #f0f0f1;
        border: 2px solid transparent;
        border-radius: 8px;
        cursor: pointer;
        transition: all 0.2s ease;
    }

    .dashlytics-chart-type:hover {
        background: #e7f3ff;
    }

    .dashlytics-chart-type.active {
        background: #e7f3ff;
        border-color: #2271b1;
    }

    .dashlytics-chart-type input {
        display: none;
    }

    .dashlytics-chart-type-icon {
        font-size: 28px;
    }

    .dashlytics-chart-type-label {
        font-size: 13px;
        font-weight: 500;
        color: #1d2327;
    }

    /* Token Field */
    .dashlytics-input--readonly {
        background: #f6f7f7;
        font-family: monospace;
        letter-spacing: 1px;
    }

    .dashlytics-field-info {
        margin: 8px 0 0;
        font-size: 12px;
        color: #00a32a;
    }

    /* Features Section */
    .dashlytics-features-section {
        margin-top: 24px;
        padding-top: 24px;
        border-top: 1px solid #e2e8f0;
    }

    .dashlytics-features-title {
        margin: 0 0 20px;
        font-size: 16px;
        font-weight: 600;
        color: #1e293b;
        display: flex;
        align-items: center;
        gap: 8px;
    }

    .dashlytics-features-title::before {
        content: '';
        width: 4px;
        height: 20px;
        background: linear-gradient(135deg, #2271b1 0%, #135e96 100%);
        border-radius: 2px;
    }

    .dashlytics-feature-cards {
        display: grid;
        grid-template-columns: repeat(2, 1fr);
        gap: 16px;
    }

    @media (max-width: 768px) {
        .dashlytics-feature-cards {
            grid-template-columns: 1fr;
        }
    }

    .dashlytics-feature-card {
        display: flex;
        align-items: flex-start;
        gap: 16px;
        padding: 20px;
        background: #ffffff;
        border: 1px solid #e2e8f0;
        border-radius: 12px;
        transition: all 0.2s ease;
    }

    .dashlytics-feature-card:hover {
        border-color: #2271b1;
        box-shadow: 0 4px 12px rgba(34, 113, 177, 0.1);
        transform: translateY(-2px);
    }

    .dashlytics-feature-card-icon {
        flex-shrink: 0;
        width: 48px;
        height: 48px;
        display: flex;
        align-items: center;
        justify-content: center;
        border-radius: 12px;
        color: #ffffff;
    }

    .dashlytics-feature-card-icon .dashicons {
        font-size: 24px;
        width: 24px;
        height: 24px;
    }

    .dashlytics-feature-card-content h4 {
        margin: 0 0 6px;
        font-size: 15px;
        font-weight: 600;
        color: #1e293b;
    }

    .dashlytics-feature-card-content p {
        margin: 0;
        font-size: 13px;
        color: #64748b;
        line-height: 1.5;
    }

    /* Button Styles - Tertiary */
    .dashlytics-btn--tertiary {
        background-color: transparent;
        border: 1px solid #e2e8f0;
        color: #64748b;
    }

    .dashlytics-btn--tertiary:hover {
        background-color: #f8fafc;
        border-color: #cbd5e1;
        color: #334155;
    }

    /* Animations */
    .dashlytics-preview-bar {
        animation: growUp 0.6s ease-out forwards;
        transform-origin: bottom;
    }

    @keyframes growUp {
        from {
            transform: scaleY(0);
        }
        to {
            transform: scaleY(1);
        }
    }
</style>
