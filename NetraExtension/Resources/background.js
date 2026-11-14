/*
 * Netra background script — the single place where pages are classified and
 * scored.
 *
 *   content.js  -> collects hostnames            (no logic)
 *   background  -> classify + first-party + score (this file)
 *   popup.js    -> renders the report             (no logic)
 *   Swift app   -> stores/aggregates the report   (no re-scoring)
 *
 * The tracker database is trackers.json, the same file the iOS app bundles.
 */
"use strict";

const api = typeof browser !== "undefined"
    ? browser
    : (typeof chrome !== "undefined" ? chrome : null);

const NATIVE_APP_ID = "com.nvs.Netra"; // Safari ignores the id; the handler is fixed.
const MAX_HOSTS = 500;

// Common two-part public suffixes. A full Public Suffix List is a future
// improvement; this covers the cases that matter most for first-party checks.
const MULTI_PART_SUFFIXES = new Set([
    "co.uk", "org.uk", "ac.uk", "gov.uk", "me.uk",
    "com.au", "net.au", "org.au", "edu.au", "gov.au",
    "co.in", "net.in", "org.in", "gov.in", "ac.in", "edu.in",
    "co.jp", "ne.jp", "or.jp", "ac.jp",
    "co.nz", "org.nz", "co.za", "org.za",
    "com.br", "com.ar", "com.mx", "com.co", "com.pe",
    "com.cn", "net.cn", "org.cn", "com.hk", "com.tw", "com.sg", "com.my",
    "co.kr", "or.kr", "com.tr", "com.pk", "com.ng", "com.eg", "co.id", "co.th", "com.ph", "com.vn"
]);

function registrableDomain(host) {
    const clean = String(host).toLowerCase().replace(/\.$/, "");
    if (/^\d{1,3}(\.\d{1,3}){3}$/.test(clean) || clean.includes(":")) { return clean; }
    const parts = clean.split(".");
    if (parts.length <= 2) { return clean; }
    const lastTwo = parts.slice(-2).join(".");
    return MULTI_PART_SUFFIXES.has(lastTwo) ? parts.slice(-3).join(".") : lastTwo;
}

// ---------------------------------------------------------------------------
// Tracker database
// ---------------------------------------------------------------------------

function buildIndex(raw) {
    const byDomain = new Map();
    const owners = new Map();
    const companies = new Map();

    for (const company of raw.companies) {
        companies.set(company.id, company);
        for (const owned of company.owns || []) {
            owners.set(registrableDomain(owned), company.id);
        }
        for (const tracker of company.trackers) {
            const domain = tracker.domain.toLowerCase();
            byDomain.set(domain, {
                domain,
                category: tracker.category,
                what: tracker.what || "",
                companyId: company.id
            });
        }
    }
    return { raw, byDomain, owners, companies };
}

let databasePromise = null;

function loadDatabase() {
    if (!databasePromise) {
        databasePromise = fetch(api.runtime.getURL("trackers.json"))
            .then(response => response.json())
            .then(buildIndex)
            .catch(error => { databasePromise = null; throw error; });
    }
    return databasePromise;
}

// Longest-suffix match: "connect.facebook.net" -> "facebook.net".
function classifyHost(db, host) {
    const labels = host.split(".");
    for (let i = 0; i < labels.length - 1; i += 1) {
        const hit = db.byDomain.get(labels.slice(i).join("."));
        if (hit) { return hit; }
    }
    return null;
}

// ---------------------------------------------------------------------------
// Scoring (the only implementation)
// ---------------------------------------------------------------------------

function labelForScore(db, score) {
    const bands = [...db.raw.scoring.bands].sort((a, b) => b.min - a.min);
    for (const band of bands) {
        if (score >= band.min) { return band.label; }
    }
    return bands[bands.length - 1].label;
}

function buildReport(db, pageHost, rawHosts) {
    const page = String(pageHost || "").toLowerCase();
    const pageRegistrable = registrableDomain(page);
    const pageCompany = db.owners.get(pageRegistrable) || null;
    const penalties = db.raw.scoring.categoryPenalty;

    const hosts = Array.from(new Set(rawHosts.map(h => String(h).toLowerCase()))).slice(0, MAX_HOSTS);

    const trackers = [];
    const companies = new Map();
    const scoredPairs = new Set();
    let otherThirdParty = 0;
    let firstPartyServices = 0;
    let totalPenalty = 0;

    for (const host of hosts) {
        // 1. Same registrable domain as the page: first party, never a tracker.
        if (registrableDomain(host) === pageRegistrable) { continue; }

        // 2. Unknown third-party hosts are counted but never scored.
        const hit = classifyHost(db, host);
        if (!hit) { otherThirdParty += 1; continue; }

        // 3. A company's own services on its own sites (e.g. Google on
        //    youtube.com) are first party, not tracking you from outside.
        if (pageCompany && hit.companyId === pageCompany) { firstPartyServices += 1; continue; }

        const company = db.companies.get(hit.companyId);
        const category = db.raw.categories[hit.category];

        trackers.push({
            host,
            company: company.id,
            companyName: company.name,
            category: hit.category
        });

        let entry = companies.get(company.id);
        if (!entry) {
            entry = {
                id: company.id,
                name: company.name,
                summary: company.summary,
                penalty: 0,
                categories: [],
                hosts: []
            };
            companies.set(company.id, entry);
        }
        entry.hosts.push({ host, what: hit.what, category: hit.category });

        const pair = `${company.id}|${hit.category}`;
        if (!scoredPairs.has(pair)) {
            scoredPairs.add(pair);
            const penalty = penalties[hit.category] ?? 0;
            entry.penalty += penalty;
            totalPenalty += penalty;
            entry.categories.push({ id: hit.category, title: category.title, risk: category.risk });
        }
    }

    const score = Math.max(0, db.raw.scoring.base - totalPenalty);

    return {
        pageHost: page,
        score,
        label: labelForScore(db, score),
        scannedHosts: hosts.length,
        otherThirdParty,
        firstPartyServices,
        trackers,
        companies: Array.from(companies.values()).sort((a, b) => b.penalty - a.penalty || a.name.localeCompare(b.name)),
        databaseVersion: db.raw.version
    };
}

// ---------------------------------------------------------------------------
// Native sync
// ---------------------------------------------------------------------------

async function recordingEnabled() {
    try {
        const stored = await api.storage.local.get({ record: true });
        return stored.record !== false;
    } catch (_) {
        return true;
    }
}

async function sendToApp(report, tab) {
    if (!(await recordingEnabled())) { return { skipped: "paused" }; }
    if (tab && tab.incognito) { return { skipped: "private" }; }

    const scan = {
        pageHost: report.pageHost,
        score: report.score,
        label: report.label,
        trackers: report.trackers,
        otherThirdParty: report.otherThirdParty,
        firstPartyServices: report.firstPartyServices,
        scannedAt: Date.now()
    };

    try {
        return await api.runtime.sendNativeMessage(NATIVE_APP_ID, { type: "siteScan", scan });
    } catch (error) {
        return { error: String(error) };
    }
}

// ---------------------------------------------------------------------------
// Messaging
// ---------------------------------------------------------------------------

function validHosts(value) {
    return Array.isArray(value) && value.every(item => typeof item === "string") ? value.slice(0, MAX_HOSTS) : null;
}

async function handlePageHosts(request, sender) {
    const hosts = validHosts(request.hosts);
    if (!hosts || typeof request.pageHost !== "string" || !request.pageHost) { return { ok: false }; }
    const db = await loadDatabase();
    const report = buildReport(db, request.pageHost, hosts);
    const result = await sendToApp(report, sender && sender.tab);
    return { ok: true, result };
}

async function handleGetReport(request) {
    try {
        // The popup resolves the active tab itself ("current window" is
        // ambiguous from a background page); query only as a fallback.
        let tabId = request && typeof request.tabId === "number" ? request.tabId : null;
        if (tabId === null) {
            const [tab] = await api.tabs.query({ active: true, currentWindow: true });
            tabId = tab && typeof tab.id === "number" ? tab.id : null;
        }
        if (tabId === null) { return { ok: false, reason: "no_tab" }; }

        let snapshot;
        try {
            snapshot = await api.tabs.sendMessage(tabId, { type: "collect" });
        } catch (_) {
            return { ok: false, reason: "unavailable" };
        }

        const hosts = snapshot && validHosts(snapshot.hosts);
        if (!hosts || !snapshot.pageHost) { return { ok: false, reason: "unavailable" }; }

        const db = await loadDatabase();
        return { ok: true, report: buildReport(db, snapshot.pageHost, hosts) };
    } catch (error) {
        return { ok: false, reason: "error", message: String(error) };
    }
}

if (api) {
    api.runtime.onMessage.addListener((request, sender) => {
        if (!request || typeof request.type !== "string") { return; }
        if (sender && sender.id && sender.id !== api.runtime.id) { return; }
        if (request.type === "pageHosts") { return handlePageHosts(request, sender); }
        if (request.type === "getReport") { return handleGetReport(request); }
    });
}

// Exposed for the Node test suite only; Safari has no `module`.
if (typeof module !== "undefined") {
    module.exports = { registrableDomain, buildIndex, classifyHost, buildReport, labelForScore };
}
