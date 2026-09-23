<script>
import { Chart } from 'chart.js/auto';
import { jsPDF } from 'jspdf';
import { onMount, onDestroy, afterUpdate } from 'svelte';

// WordPress data
const wpData = window.dashlyticsWidget || {};
const restUrl = wpData.restUrl || '/wp-json/dashlytics/v1/';
const nonce = wpData.nonce || '';
const savedSettings = wpData.settings || {};
const i18n = wpData.i18n || {};
const dateLocale = i18n.locale || 'de-DE';
const siteTitle = wpData.siteTitle || i18n.website || 'Website';
const siteUrl = wpData.siteUrl || '';
const siteLogo = wpData.siteLogo || '';
const siteFavicon = wpData.siteFavicon || '';
const pluginUrl = wpData.pluginUrl || '';

// State
let chart = null;
let chartCanvas;
let loading = true;
let error = null;
let analyticsData = null;
let deviceData = [];
let generatingPdf = false;
let showExportMenu = false;
let needsChartUpdate = false;
let isMinimalView = false;

// LocalStorage Keys
const STORAGE_KEY = 'dashlytics_minimal_view';
const WIDGET_SETTINGS_KEY = 'dashlytics_widget_settings';

// Restore widget settings from localStorage
function loadWidgetSettings() {
    try {
        const stored = localStorage.getItem(WIDGET_SETTINGS_KEY);
        if (stored) {
            return JSON.parse(stored);
        }
    } catch (e) {
        console.warn('Widget settings could not be loaded');
    }
    return {};
}

function saveWidgetSetting(key, value) {
    try {
        const current = loadWidgetSettings();
        current[key] = value;
        localStorage.setItem(WIDGET_SETTINGS_KEY, JSON.stringify(current));
    } catch (e) {
        console.warn('Widget setting could not be saved');
    }
}

// Merge user settings: localStorage wins over saved plugin settings
const userSettings = loadWidgetSettings();

// Settings
let chartType = userSettings.chartType || savedSettings.chart_type || 'line';
let chartColor = userSettings.chartColor || savedSettings.chart_color || '#2271b1';
let dateRange = savedSettings.date_range || 30;

let startDate = new Date(Date.now() - (dateRange * 24 * 60 * 60 * 1000)).toISOString().slice(0, 10);
let endDate = new Date().toISOString().slice(0, 10);

let loadingChartType = false;

function loadMinimalViewState() {
    try {
        const stored = localStorage.getItem(STORAGE_KEY);
        if (stored !== null) {
            isMinimalView = stored === 'true';
        }
    } catch (e) {
        console.warn('LocalStorage not available');
    }
}

function toggleMinimalView() {
    isMinimalView = !isMinimalView;
    try {
        localStorage.setItem(STORAGE_KEY, isMinimalView.toString());
    } catch (e) {
        console.warn('LocalStorage not available');
    }
    // Destroy and recreate the chart after a view change
    if (chart) {
        chart.destroy();
        chart = null;
    }
    needsChartUpdate = true;
}

// Chart types - titles via i18n
const chartTypes = [
    { value: 'line', label: '📈', title: i18n.line || 'Liniendiagramm' },
    { value: 'bar', label: '📊', title: i18n.bar || 'Balkendiagramm' },
    { value: 'pie', label: '🥧', title: i18n.pie || 'Kreisdiagramm' }
];

// Aggregierte Statistiken berechnen (reaktiv auf analyticsData)
$: aggregatedData = (() => {
    if (!analyticsData) return null;
    
    // If it is an array (daily data), aggregate the values
    if (Array.isArray(analyticsData)) {
        let totalVisitors = 0;
        let totalPageviews = 0;
        let totalBounceRate = 0;
        let totalTimeOnSite = 0;
        let count = 0;
        
        analyticsData.forEach(day => {
            if (day && typeof day === 'object') {
                totalVisitors += parseInt(day.nb_uniq_visitors || day.nb_visits || 0) || 0;
                totalPageviews += parseInt(day.nb_pageviews || day.nb_actions || 0) || 0;
                // bounce_rate may come as "50%" or as a number
                const br = day.bounce_rate;
                if (br !== undefined && br !== null && br !== '') {
                    const brNum = typeof br === 'string' ? parseFloat(br.replace('%', '')) : parseFloat(br);
                    if (!isNaN(brNum)) {
                        totalBounceRate += brNum;
                    }
                }
                totalTimeOnSite += parseFloat(day.avg_time_on_site || 0) || 0;
                count++;
            }
        });
        
        const avgBounceRate = count > 0 && totalBounceRate > 0 ? Math.round(totalBounceRate / count) : 0;
        
        return {
            nb_uniq_visitors: totalVisitors,
            nb_pageviews: totalPageviews,
            bounce_rate: avgBounceRate + '%',
            avg_time_on_site: count > 0 ? totalTimeOnSite / count : 0
        };
    }
    
    // Single object - format bounce_rate here too
    if (analyticsData && typeof analyticsData === 'object') {
        const br = analyticsData.bounce_rate;
        let formattedBounceRate = '0%';
        if (br !== undefined && br !== null && br !== '') {
            if (typeof br === 'string' && br.includes('%')) {
                formattedBounceRate = br;
            } else {
                const brNum = parseFloat(br);
                formattedBounceRate = !isNaN(brNum) ? Math.round(brNum) + '%' : '0%';
            }
        }
        return {
            ...analyticsData,
            bounce_rate: formattedBounceRate
        };
    }
    
    return analyticsData;
})();
$: stats = aggregatedData ? [
    { 
        label: i18n.visitors || 'Besucher', 
        value: formatNumber(aggregatedData.nb_uniq_visitors || aggregatedData.nb_visits || 0),
        icon: '👥',
        color: '#3b82f6'
    },
    { 
        label: i18n.pageviews || 'Seitenaufrufe', 
        value: formatNumber(aggregatedData.nb_pageviews || aggregatedData.nb_actions || 0),
        icon: '📄',
        color: '#10b981'
    },
    { 
        label: i18n.bounceRate || 'Absprungrate', 
        value: (aggregatedData.bounce_rate || '0%'),
        icon: '↩️',
        color: '#f59e0b'
    },
    { 
        label: i18n.avgTime || 'Ø Verweildauer', 
        value: formatTime(aggregatedData.avg_time_on_site || 0),
        icon: '⏱️',
        color: '#8b5cf6'
    }
] : [];

// Hilfsfunktionen
function formatNumber(num) {
    const n = Number(num) || 0;
    if (n >= 1000000) return (n / 1000000).toFixed(1) + 'M';
    if (n >= 1000) return (n / 1000).toFixed(1) + 'K';
    return n.toString();
}

function formatTime(seconds) {
    if (!seconds) return '0:00';
    const mins = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    return `${mins}:${secs.toString().padStart(2, '0')}`;
}

// Load data
async function loadAnalytics() {
    loading = true;
    error = null;

    try {
        const response = await fetch(
            `${restUrl}analytics?period=day&date=${startDate},${endDate}`,
            {
                headers: {
                    'X-WP-Nonce': nonce
                }
            }
        );

        if (!response.ok) {
            const errorData = await response.json();
            throw new Error(errorData.message || i18n.error || 'Fehler beim Laden');
        }

        analyticsData = await response.json();
        // Chart must be recreated after rendering
        needsChartUpdate = true;
    } catch (err) {
        error = err.message;
        console.error('Analytics error:', err);
    } finally {
        loading = false;
    }
}

// Load device/OS data for pie charts
async function loadDevices() {
    if (chartType !== 'pie' && chartType !== 'doughnut') return;

    try {
        const response = await fetch(
            `${restUrl}devices?date=${startDate},${endDate}`,
            {
                headers: {
                    'X-WP-Nonce': nonce
                }
            }
        );

        if (!response.ok) {
            const errorData = await response.json();
            throw new Error(errorData.message || i18n.deviceError || 'Fehler beim Laden der Gerätedaten');
        }

        deviceData = await response.json();
        needsChartUpdate = true;
    } catch (err) {
        console.error('Device data error:', err);
        deviceData = [];
    }
}

// Chart erstellen/aktualisieren
async function createChart() {
    if (!chartCanvas) return;

    // For pie charts, the OS data must be loaded first.
    if (chartType === 'pie' && deviceData.length === 0) {
        await loadDevices();
    }

    createChartInternal();
}

function createChartInternal() {
    if (!chartCanvas) return;
    
    const ctx = chartCanvas.getContext('2d');

    if (chart) {
        chart.destroy();
    }

    const isPie = chartType === 'pie' || chartType === 'doughnut';
    let labels = [];
    let data = [];
    let datasetLabel = i18n.visits || 'Besuche';

    if (isPie) {
        labels = deviceData.map(d => d.label);
        data = deviceData.map(d => d.value);
        datasetLabel = i18n.osFamilies || 'OS-Familien';
    } else {
        labels = generateDateLabels();
        data = generateDataFromAnalytics();
    }

    const bgColor = {
        id: 'bgColor',
        beforeDraw: (chart, args, options) => {
            const { ctx, chartArea } = chart;
            ctx.save();
            ctx.globalCompositeOperation = 'destination-over';
            ctx.fillStyle = options.color || '#ffffff';
            ctx.fillRect(chartArea.left, chartArea.top, chartArea.right - chartArea.left, chartArea.bottom - chartArea.top);
            ctx.restore();
        }
    };

    const chartConfig = {
        type: chartType,
        data: {
            labels: labels,
            datasets: [{
                label: datasetLabel,
                data: data,
                borderColor: isPie ? '#ffffff' : chartColor,
                backgroundColor: chartType === 'line' 
                    ? createGradient(ctx, chartColor)
                    : generateColorArray(data.length, chartColor),
                tension: 0.4,
                fill: chartType === 'line',
                borderWidth: chartType === 'line' ? 3 : 0,
                pointRadius: chartType === 'line' ? 4 : 0,
                pointBackgroundColor: chartColor,
                pointBorderColor: '#fff',
                pointBorderWidth: 2,
                pointHoverRadius: 6,
            }]
        },
        plugins: [bgColor],
        options: {
            responsive: true,
            maintainAspectRatio: false,
            animation: {
                duration: 800,
                easing: 'easeOutQuart'
            },
            interaction: {
                intersect: false,
                mode: 'index'
            },
            plugins: {
                legend: {
                    display: isPie,
                    position: 'bottom',
                    labels: {
                        padding: 15,
                        usePointStyle: true,
                        font: { size: 12 }
                    }
                },
                tooltip: {
                    backgroundColor: 'rgba(15, 23, 42, 0.95)',
                    padding: 14,
                    titleFont: {
                        size: 13,
                        weight: '600'
                    },
                    bodyFont: {
                        size: 12
                    },
                    cornerRadius: 10,
                    displayColors: false,
                    borderColor: 'rgba(255,255,255,0.1)',
                    borderWidth: 1,
                    callbacks: {
                        title: function(context) {
                            if (isPie) {
                                return context[0].label;
                            }
                            // Show the full date for year-spanning periods
                            const label = context[0].label;
                            if (isMultiYear()) {
                                return label; // Bereits mit Jahr formatiert
                            }
                            // Add current year
                            const currentYear = new Date().getFullYear();
                            return `${label}.${currentYear}`;
                        },
                        label: function(context) {
                            const value = context.parsed.y !== null && context.parsed.y !== undefined ? context.parsed.y : context.parsed;
                            if (isPie) {
                                return `${datasetLabel}: ${value}`;
                            }
                            return `${i18n.visits || 'Besuche'}: ${value}`;
                        }
                    }
                }
            },
            scales: chartType !== 'pie' && chartType !== 'doughnut' ? {
                x: {
                    grid: {
                        display: false
                    },
                    ticks: {
                        font: {
                            size: 11,
                            weight: '500'
                        },
                        color: '#64748b'
                    }
                },
                y: {
                    beginAtZero: true,
                    grid: {
                        color: 'rgba(0,0,0,0.04)',
                        drawBorder: false
                    },
                    ticks: {
                        font: {
                            size: 11,
                            weight: '500'
                        },
                        color: '#64748b',
                        padding: 8
                    }
                }
            } : {}
        }
    };

    chart = new Chart(ctx, chartConfig);
}

function createGradient(ctx, color) {
    const safeColor = safeHex(color);
    const gradient = ctx.createLinearGradient(0, 0, 0, 200);
    gradient.addColorStop(0, safeColor + '40');
    gradient.addColorStop(1, safeColor + '05');
    return gradient;
}

function generateColorArray(length, baseColor) {
    const safeBase = safeHex(baseColor);
    const colors = [];
    for (let i = 0; i < length; i++) {
        const opacity = 0.6 + (i / length) * 0.4;
        colors.push(safeBase + Math.round(opacity * 255).toString(16).padStart(2, '0'));
    }
    return colors;
}

// Check whether the period spans multiple years
function isMultiYear() {
    const startYear = new Date(startDate).getFullYear();
    const endYear = new Date(endDate).getFullYear();
    return startYear !== endYear;
}

function generateDateLabels() {
    const labels = [];
    const start = new Date(startDate);
    const end = new Date(endDate);
    const diffTime = Math.abs(end - start);
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24)) + 1;
    const showYear = isMultiYear();
    
    // Show max 14 labels; skip steps for more days
    const maxLabels = 14;
    const step = Math.max(1, Math.ceil(diffDays / maxLabels));
    
    const dateFormat = showYear 
        ? { day: '2-digit', month: '2-digit', year: '2-digit' }
        : { day: '2-digit', month: '2-digit' };
    
    for (let i = 0; i < diffDays; i += step) {
        const date = new Date(start);
        date.setDate(start.getDate() + i);
        labels.push(date.toLocaleDateString(dateLocale, dateFormat));
    }
    
    // Ensure the end date is always included
    const lastLabel = end.toLocaleDateString(dateLocale, dateFormat);
    if (labels[labels.length - 1] !== lastLabel) {
        labels.push(lastLabel);
    }
    
    return labels;
}

function generateDataFromAnalytics() {
    const labels = generateDateLabels();
    const showYear = isMultiYear();
    const dateFormat = showYear 
        ? { day: '2-digit', month: '2-digit', year: '2-digit' }
        : { day: '2-digit', month: '2-digit' };
    
    // If analyticsData is an array (daily data from Matomo)
    if (Array.isArray(analyticsData) && analyticsData.length > 0) {
        // Create a map of data by date
        const dataMap = {};
        analyticsData.forEach(d => {
            if (d && d.date) {
                // Matomo returns dates as "YYYY-MM-DD"
                const dateStr = new Date(d.date).toLocaleDateString(dateLocale, dateFormat);
                dataMap[dateStr] = parseInt(d.nb_visits || d.nb_uniq_visitors || 0);
            }
        });
        
        // Map data to the labels
        return labels.map(label => dataMap[label] || 0);
    }
    
    // If analyticsData is a single object (summary)
    if (analyticsData && typeof analyticsData === 'object' && !Array.isArray(analyticsData)) {
        const baseValue = parseInt(analyticsData.nb_visits || analyticsData.nb_uniq_visitors || 0);
        if (baseValue > 0) {
            // Distribute the value evenly across the days
            const perDay = Math.max(1, Math.round(baseValue / labels.length));
            return labels.map(() => Math.max(0, perDay + Math.floor(Math.random() * 6) - 3));
        }
    }
    
    // Fallback: empty data (no demo data)
    return labels.map(() => 0);
}

async function updateChart() {
    needsChartUpdate = true;
}

// Format period for display
function formatDateRange() {
    const start = new Date(startDate).toLocaleDateString(dateLocale, { day: '2-digit', month: '2-digit', year: 'numeric' });
    const end = new Date(endDate).toLocaleDateString(dateLocale, { day: '2-digit', month: '2-digit', year: 'numeric' });
    return `${start} - ${end}`;
}

// Calculate additional statistics for reports
function getExtendedStats() {
    if (!Array.isArray(analyticsData) || analyticsData.length === 0) return {};
    
    let maxVisits = 0;
    let minVisits = Infinity;
    let maxDate = '';
    let minDate = '';
    let totalActions = 0;
    let totalVisits = 0;
    
    analyticsData.forEach(day => {
        const visits = parseInt(day.nb_visits || 0);
        totalVisits += visits;
        totalActions += parseInt(day.nb_actions || 0);
        
        if (visits > maxVisits) {
            maxVisits = visits;
            maxDate = day.date;
        }
        if (visits < minVisits && visits > 0) {
            minVisits = visits;
            minDate = day.date;
        }
    });
    
    const avgVisitsPerDay = analyticsData.length > 0 ? Math.round(totalVisits / analyticsData.length) : 0;
    const actionsPerVisit = totalVisits > 0 ? (totalActions / totalVisits).toFixed(1) : 0;
    
    return {
        maxVisits,
        maxDate: maxDate ? new Date(maxDate).toLocaleDateString(dateLocale) : '-',
        minVisits: minVisits === Infinity ? 0 : minVisits,
        minDate: minDate ? new Date(minDate).toLocaleDateString(dateLocale) : '-',
        avgVisitsPerDay,
        actionsPerVisit,
        totalDays: analyticsData.length
    };
}

// Load image as a promise (only CORS for external sources)
function loadImage(src) {
    if (!src) return Promise.reject(new Error('No image source'));
    return new Promise((resolve, reject) => {
        const img = new Image();
        img.referrerPolicy = 'no-referrer';
        try {
            const u = new URL(src, window.location.href);
            if (u.hostname !== window.location.hostname) {
                img.crossOrigin = 'anonymous';
            }
        } catch (e) {
            img.crossOrigin = 'anonymous';
        }
        img.onload = () => resolve(img);
        img.onerror = () => reject(new Error('Image failed to load: ' + src));
        img.src = src;
    });
}

function safeHex(hex) {
    if (typeof hex === 'string' && /^#[0-9A-Fa-f]{6}$/.test(hex)) return hex;
    if (typeof hex === 'string' && /^#[0-9A-Fa-f]{3}$/.test(hex)) {
        return '#' + hex[1] + hex[1] + hex[2] + hex[2] + hex[3] + hex[3];
    }
    return '#2271b1';
}

function hexToRgb(hex) {
    const cleanHex = safeHex(hex).replace('#', '');
    const bigint = parseInt(cleanHex, 16) || 0;
    return {
        r: (bigint >> 16) & 255,
        g: (bigint >> 8) & 255,
        b: bigint & 255
    };
}

function rgbToHex(r, g, b) {
    const safe = [r, g, b].map(c => Math.max(0, Math.min(255, Math.round(Number.isFinite(c) ? c : 0))));
    return '#' + safe.map(x => x.toString(16).padStart(2, '0')).join('');
}

function hexToHsl(hex) {
    let { r, g, b } = hexToRgb(hex);
    r /= 255; g /= 255; b /= 255;
    const max = Math.max(r, g, b);
    const min = Math.min(r, g, b);
    let h = 0, s = 0, l = (max + min) / 2;
    if (max !== min) {
        const d = max - min;
        s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
        switch (max) {
            case r: h = (g - b) / d + (g < b ? 6 : 0); break;
            case g: h = (b - r) / d + 2; break;
            case b: h = (r - g) / d + 4; break;
        }
        h /= 6;
    }
    return { h: h * 360, s: s * 100, l: l * 100 };
}

function hslToRgb(h, s, l) {
    h = Number.isFinite(h) ? h / 360 : 0;
    s = Number.isFinite(s) ? s / 100 : 0;
    l = Number.isFinite(l) ? l / 100 : 0;
    let r, g, b;
    if (s === 0) {
        r = g = b = l;
    } else {
        const hue2rgb = (p, q, t) => {
            if (t < 0) t += 1;
            if (t > 1) t -= 1;
            if (t < 1 / 6) return p + (q - p) * 6 * t;
            if (t < 1 / 2) return q;
            if (t < 2 / 3) return p + (q - p) * (2 / 3 - t) * 6;
            return p;
        };
        const q = l < 0.5 ? l * (1 + s) : l + s - l * s;
        const p = 2 * l - q;
        r = hue2rgb(p, q, h + 1 / 3);
        g = hue2rgb(p, q, h);
        b = hue2rgb(p, q, h - 1 / 3);
    }
    const c = v => Math.round((Number.isFinite(v) ? v : 0) * 255);
    return { r: c(r), g: c(g), b: c(b) };
}

function darkenColor(hex, amount) {
    const hsl = hexToHsl(hex);
    const newL = Math.max(5, hsl.l * (1 - (Number.isFinite(amount) ? amount : 0.5)));
    return rgbToHex(hslToRgb(hsl.h, hsl.s, newL));
}

function getReadableTextColor(rgb) {
    const r = Number.isFinite(rgb?.r) ? rgb.r : 0;
    const g = Number.isFinite(rgb?.g) ? rgb.g : 0;
    const b = Number.isFinite(rgb?.b) ? rgb.b : 0;
    const luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255;
    return luminance > 0.6 ? { r: 30, g: 41, b: 59 } : { r: 255, g: 255, b: 255 };
}

function generateStatColors(hex, count) {
    const safeCount = Math.max(1, Number.isFinite(count) ? count : 1);
    const base = hexToHsl(hex);
    const colors = [];
    const lightnessStep = 12;
    for (let i = 0; i < safeCount; i++) {
        const l = Math.max(30, Math.min(70, base.l + ((i - (safeCount - 1) / 2) * lightnessStep)));
        colors.push(hslToRgb(base.h, base.s, l));
    }
    return colors;
}

function getFilenameSlug() {
    let text = '';
    try {
        if (siteUrl) {
            const url = new URL(siteUrl);
            text = url.hostname.replace(/^www\./i, '');
        }
    } catch (e) {
        // fall through
    }
    if (!text) {
        text = String(siteTitle || i18n.website || 'website');
    }
    return text
        .replace(/[^a-z0-9]+/gi, '-')
        .replace(/^-+|-+$/g, '')
        .toLowerCase();
}

// PDF Export Funktion
async function generatePdfReport() {
    if (!chart || generatingPdf) return;
    
    generatingPdf = true;
    showExportMenu = false;
    
    try {
        const pdf = new jsPDF({
            orientation: 'portrait',
            unit: 'mm',
            format: 'a4'
        });
        
        const pageWidth = pdf.internal.pageSize.getWidth();
        const pageHeight = pdf.internal.pageSize.getHeight();
        const margin = 15;
        const contentWidth = pageWidth - (margin * 2);
        
        // Derive colors from the user-defined chartColor
        const accentRgb = hexToRgb(chartColor);
        const headerColor = darkenColor(chartColor, 0.6);
        const headerRgb = hexToRgb(headerColor);
        const headerTextColor = getReadableTextColor(headerRgb);
        const badgeTextColor = getReadableTextColor(accentRgb);
        
        // Limit title width - badge removed, full width usable
        const maxTitleWidth = pageWidth - (margin * 2);
        let displayTitle = siteTitle;
        pdf.setFontSize(20);
        pdf.setFont('helvetica', 'bold');
        let titleWidth = pdf.getStringUnitWidth(displayTitle) * 20 / pdf.internal.scaleFactor;
        if (titleWidth > maxTitleWidth) {
            while (displayTitle.length > 0 && pdf.getStringUnitWidth(displayTitle + '...') * 20 / pdf.internal.scaleFactor > maxTitleWidth) {
                displayTitle = displayTitle.slice(0, -1);
            }
            displayTitle += '...';
        }
        
        // Header with modern design
        const headerH = 32;
        pdf.setFillColor(headerRgb.r, headerRgb.g, headerRgb.b);
        pdf.rect(0, 0, pageWidth, headerH, 'F');

        // Akzentlinie
        pdf.setFillColor(accentRgb.r, accentRgb.g, accentRgb.b);
        pdf.rect(0, headerH, pageWidth, 3, 'F');

        // Load favicon/logo
        const logoToUse = siteFavicon || siteLogo;
        if (logoToUse) {
            try {
                const img = await loadImage(logoToUse);
                pdf.addImage(img, 'PNG', margin, 5, 22, 22);

                pdf.setTextColor(headerTextColor.r, headerTextColor.g, headerTextColor.b);
                pdf.setFontSize(18);
                pdf.setFont('helvetica', 'bold');
                pdf.text(displayTitle, margin + 29, 17);
                pdf.setFontSize(9);
                pdf.setFont('helvetica', 'normal');
                pdf.setTextColor(148, 163, 184);
                pdf.text(siteUrl, margin + 29, 22);
            } catch (e) {
                // Fallback
                pdf.setTextColor(headerTextColor.r, headerTextColor.g, headerTextColor.b);
                pdf.setFontSize(18);
                pdf.setFont('helvetica', 'bold');
                pdf.text(displayTitle, margin, 17);
                pdf.setFontSize(9);
                pdf.setTextColor(148, 163, 184);
                pdf.text(siteUrl, margin, 22);
            }
        } else {
            pdf.setTextColor(headerTextColor.r, headerTextColor.g, headerTextColor.b);
            pdf.setFontSize(18);
            pdf.setFont('helvetica', 'bold');
            pdf.text(displayTitle, margin, 17);
            pdf.setFontSize(9);
            pdf.setTextColor(148, 163, 184);
            pdf.text(siteUrl, margin, 22);
        }

        // PDF: no header badge per current design request

        // Hauptstatistiken
        let yPos = 45;

        // Section Header
        pdf.setFillColor(248, 250, 252);
        pdf.roundedRect(margin, yPos - 6, contentWidth, 10, 2, 2, 'F');
        pdf.setTextColor(100, 116, 139);
        pdf.setFontSize(12);
        pdf.setFont('helvetica', 'bold');
        pdf.text((i18n.overview || 'ÜBERSICHT') + ' • ' + formatDateRange(), margin + 5, yPos - 1);
        yPos += 9;

        // Stats in 4er Grid
        const statCardWidth = (contentWidth - 12) / 4;
        const statCardHeight = 34;

        stats.forEach((stat, index) => {
            const x = margin + (index * (statCardWidth + 4));

            // Card with colored accent
            pdf.setFillColor(255, 255, 255);
            pdf.roundedRect(x, yPos, statCardWidth, statCardHeight, 3, 3, 'F');
            pdf.setDrawColor(226, 232, 240);
            pdf.roundedRect(x, yPos, statCardWidth, statCardHeight, 3, 3, 'S');

            // Derive left colored accent from chartColor, rounded ends
            pdf.setFillColor(accentRgb.r, accentRgb.g, accentRgb.b);
            const accentW = 3;
            const accentR = accentW / 2;
            const accentOffsetX = x + 5;
            const accentY = yPos + 6;
            const accentH = statCardHeight - 12;
            pdf.rect(accentOffsetX, accentY + accentR, accentW, accentH - accentW, 'F');
            pdf.ellipse(accentOffsetX + accentR, accentY + accentR, accentR, accentR, 'F');
            pdf.ellipse(accentOffsetX + accentR, accentY + accentH - accentR, accentR, accentR, 'F');

            // Value (30% larger than before ~14 pt -> 18 pt)
            pdf.setFontSize(18);
            pdf.setFont('helvetica', 'bold');
            pdf.setTextColor(30, 41, 59);
            pdf.text(stat.value, x + 13, yPos + 16);

            // Label
            pdf.setFontSize(7);
            pdf.setFont('helvetica', 'normal');
            pdf.setTextColor(100, 116, 139);
            pdf.text(stat.label.toUpperCase(), x + 13, yPos + 24);
        });

        yPos += statCardHeight + 12;

        // Chart Section
        pdf.setFillColor(248, 250, 252);
        pdf.roundedRect(margin, yPos - 6, contentWidth, 10, 2, 2, 'F');
        pdf.setTextColor(100, 116, 139);
        pdf.setFontSize(9);
        pdf.setFont('helvetica', 'bold');
        pdf.text(i18n.statistics || 'BESUCHERSTATISTIK', margin + 5, yPos - 1);
        yPos += 10;

        // Chart with larger box
        const chartBoxHeight = 90;
        pdf.setFillColor(255, 255, 255);
        pdf.roundedRect(margin, yPos, contentWidth, chartBoxHeight, 3, 3, 'F');
        pdf.setDrawColor(226, 232, 240);
        pdf.roundedRect(margin, yPos, contentWidth, chartBoxHeight, 3, 3, 'S');

        // Insert chart - higher resolution and correct aspect ratio
        const chartCanvas = chart.canvas;
        const chartAspectRatio = chartCanvas.width / chartCanvas.height;
        const chartBoxWidth = contentWidth - 10;
        const chartInnerHeight = chartBoxHeight - 10;

        // Calculate size while preserving the aspect ratio
        let imgWidth = chartBoxWidth;
        let imgHeight = chartBoxWidth / chartAspectRatio;

        if (imgHeight > chartInnerHeight) {
            imgHeight = chartInnerHeight;
            imgWidth = chartInnerHeight * chartAspectRatio;
        }

        const imgX = margin + 5 + (chartBoxWidth - imgWidth) / 2;
        const imgY = yPos + 5 + (chartInnerHeight - imgHeight) / 2;

        const chartImg = chart.toBase64Image('image/png', 3); // Höhere Auflösung
        pdf.addImage(chartImg, 'PNG', imgX, imgY, imgWidth, imgHeight);

        yPos += chartBoxHeight + 12;

        // Detailanalyse
        const extStats = getExtendedStats();

        pdf.setFillColor(248, 250, 252);
        pdf.roundedRect(margin, yPos - 6, contentWidth, 10, 2, 2, 'F');
        pdf.setTextColor(100, 116, 139);
        pdf.setFontSize(9);
        pdf.setFont('helvetica', 'bold');
        pdf.text(i18n.detailAnalysis || 'DETAILANALYSE', margin + 5, yPos - 1);
        yPos += 10;

        const detailItems = [
            { label: i18n.period || 'Analysezeitraum', value: `${extStats.totalDays || 0} ${i18n.days || 'Tage'}` },
            { label: i18n.avgPerDay || 'Ø Besuche/Tag', value: (extStats.avgVisitsPerDay || 0).toString() },
            { label: i18n.actionsPerVisit || 'Aktionen/Besuch', value: (extStats.actionsPerVisit || 0).toString() },
            { label: i18n.bestDay || 'Bester Tag', value: `${extStats.maxDate || '-'}` }
        ];

        const detailCardWidth = (contentWidth - 12) / 4;
        const detailCardHeight = 28;
        detailItems.forEach((item, i) => {
            const x = margin + (i * (detailCardWidth + 4));

            pdf.setFillColor(255, 255, 255);
            pdf.roundedRect(x, yPos, detailCardWidth, detailCardHeight, 2, 2, 'F');
            pdf.setDrawColor(226, 232, 240);
            pdf.roundedRect(x, yPos, detailCardWidth, detailCardHeight, 2, 2, 'S');

            // Label: wie "BESUCHERSTATISTIK" im PDF (9 pt)
            pdf.setFontSize(9);
            pdf.setFont('helvetica', 'bold');
            pdf.setTextColor(100, 116, 139);
            pdf.text(item.label.toUpperCase(), x + 5, yPos + 10);

            // Value: 40% larger than the labels (~12.5 pt -> 17.5 pt)
            pdf.setFontSize(17.5);
            pdf.setFont('helvetica', 'bold');
            pdf.setTextColor(30, 41, 59);
            pdf.text(item.value, x + 5, yPos + 20);
        });
        
        // Footer
        const footerY = pageHeight - 14;
        const footerHeight = 20;

        // Footer Hintergrund
        pdf.setFillColor(248, 250, 252);
        pdf.rect(0, footerY - 6, pageWidth, footerHeight, 'F');
        pdf.setDrawColor(226, 232, 240);
        pdf.line(margin, footerY - 6, pageWidth - margin, footerY - 6);

        // Load Matt Interfaces logo
        const mattInterfacesLogoUrl = pluginUrl + 'assets/images/matt-interface-logo-v3-100x40px.png';
        let logoLoaded = false;
        try {
            const mattInterfacesLogo = await loadImage(mattInterfacesLogoUrl);
            const logoH = 5;
            const logoW = 12.5;
            pdf.addImage(mattInterfacesLogo, 'PNG', pageWidth - margin - logoW, footerY + 0.5, logoW, logoH);
            logoLoaded = true;
        } catch (e) {
            // Fallback without logo
        }

        // Footer Text
        const generatedAt = new Date().toLocaleDateString(dateLocale, {
            day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit'
        });
        const footerLeft = `${i18n.generatedOn || 'Generiert am'} ${generatedAt}`;
        const footerCenter = i18n.poweredBy || 'Powered by WP Dashlytics';

        pdf.setFontSize(7);
        pdf.setFont('helvetica', 'normal');
        pdf.setTextColor(100, 116, 139);

        pdf.text(footerLeft, margin, footerY + 2);
        const centerWidth = pdf.getStringUnitWidth(footerCenter) * 7 / pdf.internal.scaleFactor;
        pdf.text(footerCenter, (pageWidth - centerWidth) / 2, footerY + 2);

        if (!logoLoaded) {
            const fallbackRight = 'Matt Interfaces';
            pdf.setTextColor(accentRgb.r, accentRgb.g, accentRgb.b);
            const fallbackWidth = pdf.getStringUnitWidth(fallbackRight) * 7 / pdf.internal.scaleFactor;
            pdf.text(fallbackRight, pageWidth - margin - fallbackWidth, footerY + 2);
        }
        
        // PDF speichern
        const filename = `${getFilenameSlug()}-analytics-report-${startDate}-${endDate}.pdf`;
        pdf.save(filename);
        
    } catch (err) {
        console.error('PDF error:', err);
        alert(i18n.pdfError || 'Fehler beim Erstellen des PDF-Reports');
    } finally {
        generatingPdf = false;
    }
}

// PNG export - creates an extended image with stats
async function exportChartAsPng() {
    if (!chart) return;
    showExportMenu = false;
    
    try {
        const canvas = document.createElement('canvas');
        const ctx = canvas.getContext('2d');
        
        const chartCanvas = chart.canvas;
        const scale = 2; // Höhere Auflösung
        const chartWidth = 800;
        const chartHeight = 400;
        
        const padding = 30;
        const headerHeight = 100;
        const statsHeight = 100;
        const footerHeight = 56;
        
        canvas.width = chartWidth + (padding * 2);
        canvas.height = headerHeight + statsHeight + chartHeight + footerHeight;
        
        // Derive colors from the user-defined chartColor
        const headerColor = darkenColor(chartColor, 0.6);
        const headerTextColorRgb = getReadableTextColor(hexToRgb(headerColor));
        const headerTextColor = `rgb(${headerTextColorRgb.r}, ${headerTextColorRgb.g}, ${headerTextColorRgb.b})`;
        const badgeTextColorRgb = getReadableTextColor(hexToRgb(chartColor));
        const badgeTextColor = `rgb(${badgeTextColorRgb.r}, ${badgeTextColorRgb.g}, ${badgeTextColorRgb.b})`;
        const statColors = generateStatColors(chartColor, stats.length);
        
        // Limit title width so the badge does not overlap (badge max. 120px)
        const maxTitleWidth = canvas.width - (padding * 2) - 120 - 20;
        let displayTitle = siteTitle;
        ctx.font = 'bold 28px -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif';
        let titleWidth = ctx.measureText(displayTitle).width;
        if (titleWidth > maxTitleWidth) {
            while (displayTitle.length > 0 && ctx.measureText(displayTitle + '...').width > maxTitleWidth) {
                displayTitle = displayTitle.slice(0, -1);
            }
            displayTitle += '...';
        }
        
        // Hintergrund
        ctx.fillStyle = '#f8fafc';
        ctx.fillRect(0, 0, canvas.width, canvas.height);
        
        // Header
        ctx.fillStyle = headerColor;
        ctx.fillRect(0, 0, canvas.width, headerHeight);
        
        // Akzentlinie
        ctx.fillStyle = chartColor;
        ctx.fillRect(0, headerHeight - 4, canvas.width, 4);
        
        // Load favicon/logo
        const logoToUse = siteFavicon || siteLogo;
        if (logoToUse) {
            try {
                const logo = await loadImage(logoToUse);
                ctx.drawImage(logo, padding, 25, 50, 50);
                
                ctx.fillStyle = headerTextColor;
                ctx.font = 'bold 28px -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif';
                ctx.fillText(displayTitle, padding + 65, 50);
                
                ctx.fillStyle = '#94a3b8';
                ctx.font = '14px -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif';
                ctx.fillText(siteUrl, padding + 65, 72);
            } catch (e) {
                ctx.fillStyle = headerTextColor;
                ctx.font = 'bold 28px -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif';
                ctx.fillText(displayTitle, padding, 50);
            }
        } else {
            ctx.fillStyle = headerTextColor;
            ctx.font = 'bold 28px -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif';
            ctx.fillText(displayTitle, padding, 50);
        }
        
        // Report badge - compact
        const badgeText = i18n.reportLabel || 'REPORT';
        ctx.font = 'bold 12px -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif';
        const textWidth = ctx.measureText(badgeText).width + 20;
        const badgeH = 30;
        const badgeW = Math.max(80, textWidth);
        const badgeX = canvas.width - padding - badgeW;
        ctx.fillStyle = chartColor;
        roundRect(ctx, badgeX, 20, badgeW, badgeH, 6, true, false);
        ctx.fillStyle = badgeTextColor;
        ctx.textAlign = 'center';
        ctx.textBaseline = 'middle';
        ctx.fillText(badgeText, badgeX + badgeW / 2, 20 + badgeH / 2 + 1);
        ctx.textAlign = 'left';
        ctx.textBaseline = 'alphabetic';
        
        // Stats Cards
        const statsY = headerHeight + 15;
        const statCardWidth = (canvas.width - (padding * 2) - 30) / 4;
        const statCardHeight = 62;

        stats.forEach((stat, i) => {
            const x = padding + (i * (statCardWidth + 10));

            // Card background
            ctx.fillStyle = '#ffffff';
            roundRect(ctx, x, statsY, statCardWidth, statCardHeight, 8, true, false);

            // Derive colored accent from chartColor
            const statRgb = statColors[i];
            ctx.fillStyle = `rgb(${statRgb.r}, ${statRgb.g}, ${statRgb.b})`;
            ctx.fillRect(x, statsY + 10, 4, statCardHeight - 20);

            // Value
            ctx.fillStyle = '#1e293b';
            ctx.font = 'bold 26px -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif';
            ctx.fillText(stat.value, x + 15, statsY + 34);

            // Label
            ctx.fillStyle = '#64748b';
            ctx.font = '12px -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif';
            ctx.fillText(stat.label.toUpperCase(), x + 15, statsY + 52);
        });

        // Chart Container
        const chartY = statsY + statCardHeight + 20;
        ctx.fillStyle = '#ffffff';
        roundRect(ctx, padding, chartY, canvas.width - (padding * 2), chartHeight, 8, true, false);
        
        // Draw chart - with correct aspect ratio
        const srcCanvas = chart.canvas;
        const srcAspectRatio = srcCanvas.width / srcCanvas.height;
        const destWidth = canvas.width - (padding * 2) - 20;
        const destHeight = chartHeight - 20;
        
        let drawWidth = destWidth;
        let drawHeight = destWidth / srcAspectRatio;
        
        if (drawHeight > destHeight) {
            drawHeight = destHeight;
            drawWidth = destHeight * srcAspectRatio;
        }
        
        const drawX = padding + 10 + (destWidth - drawWidth) / 2;
        const drawY = chartY + 10 + (destHeight - drawHeight) / 2;
        
        ctx.drawImage(srcCanvas, drawX, drawY, drawWidth, drawHeight);
        
        // Footer
        const footerY = canvas.height - footerHeight;
        ctx.fillStyle = '#f1f5f9';
        ctx.fillRect(0, footerY, canvas.width, footerHeight);
        ctx.strokeStyle = '#e2e8f0';
        ctx.beginPath();
        ctx.moveTo(0, footerY);
        ctx.lineTo(canvas.width, footerY);
        ctx.stroke();

        // Matt Interfaces logo
        const mattInterfacesLogoUrlPng = pluginUrl + 'assets/images/matt-interface-logo-v3-100x40px.png';
        let pngLogoLoaded = false;
        try {
            const mattInterfacesLogoPng = await loadImage(mattInterfacesLogoUrlPng);
            const pngLogoH = 12;
            const pngLogoW = 30;
            ctx.drawImage(mattInterfacesLogoPng, canvas.width - padding - pngLogoW, footerY + 18, pngLogoW, pngLogoH);
            pngLogoLoaded = true;
        } catch (e) {
            // Fallback without logo
        }

        // Footer Text
        const pngGeneratedAt = new Date().toLocaleDateString(dateLocale, {
            day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit'
        });
        const footerLeftText = `${i18n.generatedOn || 'Generiert am'} ${pngGeneratedAt}`;
        const footerCenterText = i18n.poweredBy || 'Powered by WP Dashlytics';

        ctx.textAlign = 'left';
        ctx.textBaseline = 'alphabetic';
        ctx.fillStyle = '#64748b';
        ctx.font = '12px -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif';
        ctx.fillText(footerLeftText, padding, footerY + 32);

        ctx.textAlign = 'center';
        ctx.fillText(footerCenterText, canvas.width / 2, footerY + 32);

        if (!pngLogoLoaded) {
            ctx.textAlign = 'right';
            ctx.fillStyle = chartColor;
            ctx.font = 'bold 12px -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif';
            ctx.fillText('Matt Interfaces', canvas.width - padding, footerY + 32);
        }

        ctx.textAlign = 'left';
        
        // Download
        const link = document.createElement('a');
        link.download = `${getFilenameSlug()}-analytics-chart-${startDate}-${endDate}.png`;
        link.href = canvas.toDataURL('image/png', 1);
        link.click();
        
    } catch (err) {
        console.error('PNG export error:', err);
        alert(i18n.pngError || 'Fehler beim Erstellen des PNG-Bildes');
    }
}

// Helper function for rounded rectangles
function roundRect(ctx, x, y, width, height, radius, fill, stroke) {
    ctx.beginPath();
    ctx.moveTo(x + radius, y);
    ctx.lineTo(x + width - radius, y);
    ctx.quadraticCurveTo(x + width, y, x + width, y + radius);
    ctx.lineTo(x + width, y + height - radius);
    ctx.quadraticCurveTo(x + width, y + height, x + width - radius, y + height);
    ctx.lineTo(x + radius, y + height);
    ctx.quadraticCurveTo(x, y + height, x, y + height - radius);
    ctx.lineTo(x, y + radius);
    ctx.quadraticCurveTo(x, y, x + radius, y);
    ctx.closePath();
    if (fill) ctx.fill();
    if (stroke) ctx.stroke();
}

// Event Handler
function handleDateChange() {
    loadAnalytics();
}

function handleChartTypeChange(type) {
    if (chartType === type || loadingChartType) return;
    loadingChartType = true;
    chartType = type;
    saveWidgetSetting('chartType', type);
    updateChart();
}

function toggleExportMenu(event) {
    event.stopPropagation();
    showExportMenu = !showExportMenu;
}

// Click outside handler
function handleClickOutside(event) {
    if (showExportMenu && !event.target.closest('.dw-export-wrapper')) {
        showExportMenu = false;
    }
}

// Lifecycle
onMount(async () => {
    loadMinimalViewState();
    await loadAnalytics();
    document.addEventListener('click', handleClickOutside);
});

// After each update, check whether the chart needs to be created
afterUpdate(() => {
    if (chartCanvas && !loading && !error && analyticsData) {
        if (needsChartUpdate || !chart) {
            needsChartUpdate = false;
            createChart();
        }
        loadingChartType = false;
    }
});

onDestroy(() => {
    if (chart) {
        chart.destroy();
    }
    document.removeEventListener('click', handleClickOutside);
});
</script>

<div class="dw-container" class:dw-minimal={isMinimalView}>
    <!-- Minimal View -->
    {#if isMinimalView}
        <!-- Minimal Stats Row -->
        <div class="dw-minimal-header">
            {#if !loading && !error && stats.length > 0}
                <div class="dw-minimal-stats">
                    {#each stats as stat}
                        <div class="dw-minimal-stat" style="--stat-color: {stat.color};">
                            <span class="dw-minimal-stat-value">{stat.value}</span>
                            <span class="dw-minimal-stat-label">{stat.label}</span>
                        </div>
                    {/each}
                </div>
            {/if}
            <div class="dw-minimal-actions">
                <button 
                    class="dw-btn-refresh"
                    on:click={loadAnalytics}
                    disabled={loading}
                    title={i18n.refresh || 'Aktualisieren'}
                >
                    <span class:dw-spinning={loading}>🔄</span>
                </button>
                <button 
                    class="dw-btn-refresh"
                    on:click={toggleMinimalView}
                    title={i18n.expand || 'Erweitern'}
                >
                    📈
                </button>
            </div>
        </div>
        
        <!-- Minimal Chart -->
        <div class="dw-minimal-chart">
            {#if loading}
                <div class="dw-loader dw-loader-small" role="status" aria-label={i18n.loading || 'Lade Daten...'}>
                    <div class="dw-loader-spinner"></div>
                </div>
            {:else if !error}
                <canvas bind:this={chartCanvas}></canvas>
            {/if}
        </div>
    {:else}
        <!-- Normal View: Stats Cards -->
        {#if !loading && !error && stats.length > 0}
            <div class="dw-stats">
                {#each stats as stat, i}
                    <div class="dw-stat" style="--stat-color: {stat.color};">
                        <span class="dw-stat-icon">{stat.icon}</span>
                        <div class="dw-stat-content">
                            <span class="dw-stat-value">{stat.value}</span>
                            <span class="dw-stat-label">{stat.label}</span>
                        </div>
                    </div>
                {/each}
            </div>
        {/if}

        <!-- Chart -->
        <div class="dw-chart-container" class:dw-chart-loading={loading || loadingChartType}>
            {#if loading}
                <div class="dw-chart-loader" role="status" aria-live="polite">
                    <div class="dw-loader">
                        <div class="dw-loader-spinner"></div>
                        <span>{i18n.loading || 'Lade Daten...'}</span>
                    </div>
                </div>
            {:else if error}
                <div class="dw-chart-error">
                    <span class="dw-error-icon">⚠️</span>
                    <p>{error}</p>
                    <button class="dw-btn dw-btn-primary" on:click={loadAnalytics}>
                        🔄 {i18n.retry || 'Erneut versuchen'}
                    </button>
                </div>
            {:else}
                <div class="dw-chart" class:dw-chart-refreshing={loadingChartType}>
                    <canvas bind:this={chartCanvas}></canvas>
                    {#if loadingChartType}
                        <div class="dw-chart-refresh-overlay" role="status" aria-live="polite">
                            <div class="dw-loader dw-loader-small">
                                <div class="dw-loader-spinner"></div>
                                <span>{i18n.chartPreparing || 'Chart wird aufbereitet...'}</span>
                            </div>
                        </div>
                    {/if}
                </div>
            {/if}
        </div>

        <!-- Controls -->
        <div class="dw-controls">
            <div class="dw-control-row">
                <div class="dw-dates">
                    <label class="dw-date-field" for="dw-start-date">
                        <span class="dw-date-label">{i18n.from || 'Von'}</span>
                        <input 
                            id="dw-start-date"
                            type="date" 
                            bind:value={startDate} 
                            on:change={handleDateChange}
                            class="dw-input-date"
                            disabled={loading}
                            aria-label={i18n.from || 'Von'}
                        />
                    </label>
                    <span class="dw-date-sep">–</span>
                    <label class="dw-date-field" for="dw-end-date">
                        <span class="dw-date-label">{i18n.to || 'Bis'}</span>
                        <input 
                            id="dw-end-date"
                            type="date" 
                            bind:value={endDate} 
                            on:change={handleDateChange}
                            class="dw-input-date"
                            disabled={loading}
                            aria-label={i18n.to || 'Bis'}
                        />
                    </label>
                </div>
            </div>
            
            <div class="dw-control-row">
                <div class="dw-chart-types">
                    {#each chartTypes as type}
                        <button 
                            class="dw-chart-type-btn"
                            class:dw-active={chartType === type.value}
                            class:dw-disabled={loadingChartType}
                            on:click={() => handleChartTypeChange(type.value)}
                            title={type.title}
                            type="button"
                            disabled={loading || loadingChartType}
                        >
                            {type.label}
                        </button>
                    {/each}
                </div>

                <input 
                    type="color" 
                    bind:value={chartColor} 
                    on:change={() => {
                        saveWidgetSetting('chartColor', chartColor);
                        updateChart();
                    }}
                    class="dw-color-picker"
                    title={i18n.changeColor || 'Farbe ändern'}
                    disabled={loading || loadingChartType}
                />

                <button 
                    class="dw-btn-refresh"
                    on:click={loadAnalytics}
                    disabled={loading}
                    title={i18n.refresh || 'Aktualisieren'}
                    aria-label={i18n.ariaRefresh || 'Statistiken aktualisieren'}
                    type="button"
                >
                    <span class:dw-spinning={loading}>🔄</span>
                </button>

                <button 
                    class="dw-btn-refresh"
                    on:click={toggleMinimalView}
                    title={i18n.minimize || 'Minimieren'}
                    aria-label={i18n.ariaMinimize || 'Ansicht minimieren'}
                    type="button"
                >
                    <span>➖</span>
                </button>

                <div class="dw-export-wrapper">
                    <button 
                        class="dw-btn dw-btn-export"
                        on:click={toggleExportMenu}
                        disabled={loading || generatingPdf}
                        type="button"
                    >
                        {#if generatingPdf}
                            <span>⏳</span> {i18n.generating || 'Erstelle…'}
                        {:else}
                            <span>📥</span> {i18n.report || 'Report'}
                        {/if}
                    </button>
                    
                    {#if showExportMenu}
                        <div class="dw-export-menu">
                            <button class="dw-export-option" on:click={generatePdfReport} type="button">
                                <span>📄</span>
                                <div>
                                    <strong>{i18n.pdfReport || 'PDF Report'}</strong>
                                    <small>{i18n.fullReport || 'Vollständiger Bericht'}</small>
                                </div>
                            </button>
                            <button class="dw-export-option" on:click={exportChartAsPng} type="button">
                                <span>🖼️</span>
                                <div>
                                    <strong>{i18n.pngImage || 'PNG Bild'}</strong>
                                    <small>{i18n.chartOnly || 'Nur das Diagramm'}</small>
                                </div>
                            </button>
                        </div>
                    {/if}
                </div>
            </div>
        </div>

        <!-- Footer -->
        <div class="dw-footer">
            <a href="admin.php?page=dashlytics" class="dw-settings-link">
                ⚙️ {i18n.settings || 'Einstellungen'}
            </a>
            <span class="dw-powered">
                {i18n.poweredByCompany || 'Powered by'} <strong>Matt Interfaces</strong>
            </span>
        </div>
    {/if}
</div>