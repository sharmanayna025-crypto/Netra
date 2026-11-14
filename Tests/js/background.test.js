// Run with: node Tests/js/background.test.js   (no dependencies)
const assert = require("assert");
const fs = require("fs");
const path = require("path");
const engine = require("../../NetraExtension/Resources/background.js");

const raw = JSON.parse(fs.readFileSync(path.join(__dirname, "../../Shared/trackers.json"), "utf8"));
const db = engine.buildIndex(raw);
const report = (page, hosts) => engine.buildReport(db, page, hosts);
let passed = 0;
const test = (name, fn) => { fn(); passed += 1; console.log("  ✓", name); };

test("registrableDomain handles multi-part suffixes and IPs", () => {
    assert.strictEqual(engine.registrableDomain("cdn.example.com"), "example.com");
    assert.strictEqual(engine.registrableDomain("static.bbc.co.uk"), "bbc.co.uk");
    assert.strictEqual(engine.registrableDomain("www.flipkart.com"), "flipkart.com");
    assert.strictEqual(engine.registrableDomain("shop.example.co.in"), "example.co.in");
    assert.strictEqual(engine.registrableDomain("127.0.0.1"), "127.0.0.1");
});

test("clean page scores 100 / Excellent", () => {
    const r = report("example.com", ["example.com", "cdn.example.com"]);
    assert.strictEqual(r.score, 100);
    assert.strictEqual(r.label, "Excellent");
    assert.strictEqual(r.trackers.length, 0);
});

test("subdomains of the page are first party (old bug)", () => {
    const r = report("www.example.com", ["cdn.example.com", "api.example.com"]);
    assert.strictEqual(r.otherThirdParty, 0);
    assert.strictEqual(r.trackers.length, 0);
});

test("visiting a tracker's own site is not penalised (old bug)", () => {
    const r = report("www.facebook.com", ["connect.facebook.net", "www.facebook.com"]);
    assert.strictEqual(r.score, 100);
    assert.strictEqual(r.firstPartyServices, 1);
});

test("company-owned services on its own site are first party", () => {
    const r = report("www.youtube.com", ["www.googletagmanager.com", "stats.g.doubleclick.net", "i.ytimg.com"]);
    assert.strictEqual(r.trackers.length, 0);
    assert.strictEqual(r.firstPartyServices, 2);
    assert.strictEqual(r.otherThirdParty, 1);
});

test("third-party trackers are scored once per company+category", () => {
    const r = report("news.example.org", [
        "www.google-analytics.com", "region1.google-analytics.com",   // Google analytics x2 -> -4 once
        "securepubads.g.doubleclick.net",                            // Google advertising -10
        "static.hotjar.com",                                         // session replay -12
        "connect.facebook.net"                                       // social -8
    ]);
    assert.strictEqual(r.score, 100 - 4 - 10 - 12 - 8);
    assert.strictEqual(r.companies[0].name, "Google");   // 14 > Hotjar 12
    assert.strictEqual(r.companies[1].name, "Hotjar");
    assert.strictEqual(r.companies.find(c => c.id === "google").penalty, 14);
});

test("unknown third parties are counted but never scored", () => {
    const r = report("example.com", ["some-cdn.example.net", "fonts.gstatic.com"]);
    assert.strictEqual(r.score, 100);
    assert.strictEqual(r.otherThirdParty, 2);
});

test("score floors at 0 and bands apply", () => {
    const hosts = ["doubleclick.net", "facebook.net", "clarity.ms", "hotjar.com", "fingerprint.com",
                   "criteo.com", "taboola.com", "outbrain.com", "adsrvr.org", "adnxs.com", "linkedin.com"];
    const r = report("example.com", hosts);
    assert.strictEqual(r.score, 0);
    assert.strictEqual(r.label, "At Risk");
    assert.strictEqual(engine.labelForScore(db, 90), "Excellent");
    assert.strictEqual(engine.labelForScore(db, 89), "Good");
    assert.strictEqual(engine.labelForScore(db, 74), "Needs Attention");
});

test("bare TLD-like hosts never match", () => {
    assert.strictEqual(engine.classifyHost(db, "net"), null);
    assert.strictEqual(engine.classifyHost(db, "notfacebook.net"), null);
});

console.log(`\n${passed} tests passed`);
