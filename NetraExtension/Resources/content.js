/*
 * Netra content script — a thin collector.
 *
 * It only gathers the hostnames a page talks to and hands them to the
 * background script. All classification (tracker database, first-party
 * detection) and scoring live in background.js so there is exactly one
 * implementation of each.
 *
 * Privacy: only hostnames leave the page context. No URLs, paths, query
 * strings, cookies, form data or page content are read or sent.
 */
(() => {
    "use strict";

    // Top frame only (manifest does not set all_frames).
    if (window.top !== window) { return; }

    const api = typeof browser !== "undefined" ? browser : chrome;

    const MAX_REPORTS_PER_PAGE = 6;
    const SETTLE_DELAY_MS = 2000;
    const MAX_HOSTS = 500;

    const hosts = new Set();
    let reportsSent = 0;
    let lastSignature = "";
    let timer = null;

    function addUrl(value) {
        if (!value || hosts.size >= MAX_HOSTS) { return; }
        try {
            const url = new URL(value, location.href);
            if (url.protocol !== "http:" && url.protocol !== "https:") { return; }
            if (url.hostname) { hosts.add(url.hostname.toLowerCase()); }
        } catch (_) { /* ignore malformed URLs */ }
    }

    function scanDocument() {
        document
            .querySelectorAll("script[src], iframe[src], img[src], link[href], embed[src], object[data]")
            .forEach(node => addUrl(node.src || node.href || node.data));
    }

    function snapshot() {
        return { pageHost: location.hostname.toLowerCase(), hosts: Array.from(hosts) };
    }

    function signature() {
        return Array.from(hosts).sort().join("|");
    }

    function report() {
        timer = null;
        if (reportsSent >= MAX_REPORTS_PER_PAGE) { return; }
        scanDocument();
        const sig = signature();
        if (sig === lastSignature) { return; }
        lastSignature = sig;
        reportsSent += 1;
        api.runtime.sendMessage({ type: "pageHosts", ...snapshot() }).catch(() => {});
    }

    function schedule() {
        if (timer !== null || reportsSent >= MAX_REPORTS_PER_PAGE) { return; }
        timer = setTimeout(report, SETTLE_DELAY_MS);
    }

    // Resource Timing buffer defaults to 250 entries; the observer below keeps
    // receiving entries even when the buffer is full.
    try { performance.setResourceTimingBufferSize(1000); } catch (_) {}

    performance.getEntriesByType("resource").forEach(entry => addUrl(entry.name));

    try {
        const observer = new PerformanceObserver(list => {
            list.getEntries().forEach(entry => addUrl(entry.name));
            schedule();
        });
        observer.observe({ type: "resource", buffered: true });
    } catch (_) {
        try {
            new PerformanceObserver(list => {
                list.getEntries().forEach(entry => addUrl(entry.name));
                schedule();
            }).observe({ entryTypes: ["resource"] });
        } catch (_) { /* Resource Timing unavailable */ }
    }

    // Answer the popup's on-demand request with a fresh snapshot.
    api.runtime.onMessage.addListener(request => {
        if (request && request.type === "collect") {
            scanDocument();
            return Promise.resolve(snapshot());
        }
    });

    schedule();
})();
