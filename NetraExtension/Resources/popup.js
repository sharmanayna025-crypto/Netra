/*
 * Netra popup — render only.
 * All classification and scoring happen in background.js. Text is always set
 * with textContent (never innerHTML) because hostnames come from web pages.
 */
"use strict";

const api = typeof browser !== "undefined" ? browser : chrome;
const $ = id => document.getElementById(id);

function el(tag, className, text) {
    const node = document.createElement(tag);
    if (className) { node.className = className; }
    if (text !== undefined) { node.textContent = text; }
    return node;
}

function scoreColor(score) {
    if (score >= 90) { return "var(--good)"; }
    if (score >= 75) { return "var(--ok)"; }
    if (score >= 50) { return "var(--warn)"; }
    return "var(--bad)";
}

function showState(title, message) {
    $("result").hidden = true;
    $("state").hidden = false;
    $("stateTitle").textContent = title;
    $("stateMessage").textContent = message;
}

function summaryText(report) {
    const n = report.companies.length;
    if (n === 0) { return "No known trackers found on this page."; }
    return `${n} tracking ${n === 1 ? "company" : "companies"} found, across ${report.trackers.length} connection${report.trackers.length === 1 ? "" : "s"}.`;
}

function renderCompany(company) {
    const details = el("details", "card company");
    const summary = el("summary");

    const grow = el("div", "grow");
    grow.appendChild(el("div", "name", company.name));
    const chips = el("div", "chips");
    company.categories.forEach(category => chips.appendChild(el("span", `chip ${category.risk}`, category.title)));
    grow.appendChild(chips);

    summary.appendChild(grow);
    summary.appendChild(el("div", "penalty", `−${company.penalty}`));
    details.appendChild(summary);

    const body = el("div", "body");
    body.appendChild(el("p", "", company.summary));
    company.hosts.forEach(entry => {
        const row = el("div", "host");
        row.appendChild(el("code", "", entry.host));
        if (entry.what) { row.appendChild(el("span", "", entry.what)); }
        body.appendChild(row);
    });
    details.appendChild(body);
    return details;
}

function render(report) {
    $("state").hidden = true;
    $("result").hidden = false;
    $("siteHost").textContent = report.pageHost;

    $("score").textContent = String(report.score);
    const ring = $("ring");
    ring.style.setProperty("--p", String(report.score));
    ring.style.setProperty("--c", scoreColor(report.score));
    ring.setAttribute("aria-label", `Privacy score ${report.score} out of 100`);
    $("label").textContent = report.label;
    $("summary").textContent = summaryText(report);

    const list = $("companies");
    list.replaceChildren();
    if (report.companies.length === 0) {
        list.appendChild(el("div", "card clean muted", "Nothing in Netra's tracker database was found here."));
    } else {
        report.companies.forEach(company => list.appendChild(renderCompany(company)));
    }

    const notes = [];
    if (report.otherThirdParty > 0) {
        notes.push(`${report.otherThirdParty} other third-party domain${report.otherThirdParty === 1 ? "" : "s"} contacted but not in Netra's database, so not scored.`);
    }
    if (report.firstPartyServices > 0) {
        notes.push(`${report.firstPartyServices} service${report.firstPartyServices === 1 ? "" : "s"} owned by this site's own company counted as first party.`);
    }
    notes.push("A high score means no known trackers, not a guarantee of privacy.");
    $("coverage").textContent = notes.join(" ");
}

async function scan() {
    $("siteHost").textContent = "Scanning…";
    showState("Scanning…", "Looking at what this page connects to.");
    try {
        const [tab] = await api.tabs.query({ active: true, currentWindow: true });
        const response = await api.runtime.sendMessage({
            type: "getReport",
            tabId: tab && typeof tab.id === "number" ? tab.id : null
        });
        if (response && response.ok) {
            render(response.report);
            return;
        }
        if (response && response.reason === "unavailable") {
            showState("Can't scan this page", "Reload the page and try again. Netra can't run on some pages, such as the Start Page or settings.");
        } else {
            showState("Something went wrong", "Please try scanning again.");
        }
    } catch (_) {
        showState("Something went wrong", "Please try scanning again.");
    }
    $("siteHost").textContent = "Netra";
}

async function setupToggle() {
    const box = $("record");
    try {
        const stored = await api.storage.local.get({ record: true });
        box.checked = stored.record !== false;
    } catch (_) { box.checked = true; }
    box.addEventListener("change", () => {
        api.storage.local.set({ record: box.checked }).catch(() => {});
    });
}

$("rescan").addEventListener("click", scan);
setupToggle();
scan();
