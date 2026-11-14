//
//  PrivacyEngine.swift
//  Netra
//
//  Aggregates the per-site scans the extension has stored. It never re-scores
//  a site: the extension's background script is the only scorer, so the popup
//  and the app can never disagree.
//

import Foundation

enum PrivacyEngine {

    /// Scans older than this don't count towards the overall score.
    static let windowDays = 7

    private static var catalog: TrackerCatalog { .shared }

    // MARK: - Recent scans

    /// Most recent scan per site within the window.
    static func recentScans(_ scans: [SiteScan], days: Int = windowDays) -> [SiteScan] {
        let cutoff = Date().addingTimeInterval(-Double(days) * 86_400)
        var latest: [String: SiteScan] = [:]
        for scan in scans where scan.date >= cutoff {
            if let existing = latest[scan.pageHost], existing.date >= scan.date { continue }
            latest[scan.pageHost] = scan
        }
        return latest.values.sorted { $0.date > $1.date }
    }

    // MARK: - Overall score

    /// Average of each recently visited site's score. nil when nothing has
    /// been scanned yet.
    static func overall(from scans: [SiteScan]) -> OverallPrivacy? {
        let recent = recentScans(scans)
        guard !recent.isEmpty else { return nil }

        let total = recent.reduce(0) { $0 + $1.score }
        let score = Int((Double(total) / Double(recent.count)).rounded())
        let companies = Set(recent.flatMap { $0.trackers.map(\.company) })

        return OverallPrivacy(
            score: score,
            label: catalog.label(forScore: score),
            siteCount: recent.count,
            trackerCount: recent.reduce(0) { $0 + $1.trackers.count },
            companyCount: companies.count
        )
    }

    // MARK: - Company exposure

    static func exposures(from scans: [SiteScan]) -> [CompanyExposure] {
        struct Accumulator {
            var name: String
            var categories: Set<String> = []
            var sites: Set<String> = []
            var hosts: Set<String> = []
        }

        var map: [String: Accumulator] = [:]
        for scan in recentScans(scans) {
            for tracker in scan.trackers {
                var entry = map[tracker.company] ?? Accumulator(name: tracker.companyName)
                entry.categories.insert(tracker.category)
                entry.sites.insert(scan.pageHost)
                entry.hosts.insert(tracker.host)
                map[tracker.company] = entry
            }
        }

        return map.map { id, entry in
            let name = catalog.company(id: id)?.name ?? entry.name
            let risk = entry.categories.map { catalog.risk(of: $0) }.max() ?? .low
            return CompanyExposure(
                id: id,
                name: name,
                categories: entry.categories.sorted(),
                sites: entry.sites.sorted(),
                trackerHosts: entry.hosts.sorted(),
                risk: risk
            )
        }
        .sorted {
            if $0.sites.count != $1.sites.count { return $0.sites.count > $1.sites.count }
            return $0.name < $1.name
        }
    }

    /// Number of tracker connections per category across recent sites.
    static func categoryCounts(from scans: [SiteScan]) -> [CategoryCount] {
        var counts: [String: Int] = [:]
        for scan in recentScans(scans) {
            for tracker in scan.trackers { counts[tracker.category, default: 0] += 1 }
        }
        return counts
            .map { CategoryCount(category: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }

    // MARK: - Recommendations

    static func recommendations(from scans: [SiteScan]) -> [PrivacyRecommendation] {
        let recent = recentScans(scans)
        guard !recent.isEmpty else { return [] }

        let exposures = exposures(from: scans)
        var results: [PrivacyRecommendation] = []

        let replayCompanies = exposures.filter { $0.categories.contains("session_replay") }
        if !replayCompanies.isEmpty {
            let names = replayCompanies.prefix(3).map(\.name).joined(separator: ", ")
            results.append(PrivacyRecommendation(
                icon: "record.circle.fill",
                title: "Sites are recording your visits",
                message: "\(names) can replay taps and scrolls. Avoid typing sensitive details on those sites.",
                priority: .high
            ))
        }

        let fingerprinters = exposures.filter { $0.categories.contains("fingerprinting") }
        if !fingerprinters.isEmpty {
            results.append(PrivacyRecommendation(
                icon: "touchid",
                title: "Device fingerprinting detected",
                message: "Some sites try to identify your device without cookies. Keep Safari's fingerprinting protection on.",
                priority: .high
            ))
        }

        let adCompanies = exposures.filter { $0.categories.contains("advertising") }
        if adCompanies.count >= 3 {
            results.append(PrivacyRecommendation(
                icon: "megaphone.fill",
                title: "Ad networks are following you",
                message: "\(adCompanies.count) advertising companies appeared in your recent browsing. Turn on “Hide IP Address from Trackers” in Safari.",
                priority: .medium
            ))
        }

        if let top = exposures.first, top.sites.count >= 3 {
            results.append(PrivacyRecommendation(
                icon: "eye.fill",
                title: "\(top.name) sees a lot of your browsing",
                message: "It appeared on \(top.sites.count) of the sites you visited this week.",
                priority: .medium
            ))
        }

        if results.isEmpty {
            results.append(PrivacyRecommendation(
                icon: "checkmark.shield.fill",
                title: "Your browsing looks clean",
                message: "Few known trackers appeared on the sites you visited recently.",
                priority: .low
            ))
        }

        return results.sorted { $0.priority.rawValue > $1.priority.rawValue }
    }
}
