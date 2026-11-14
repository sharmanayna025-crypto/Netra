//
//  ScanModels.swift
//  Shared by the Netra app and the Safari extension.
//
//  The extension's background script computes each site's score once; the app
//  stores and aggregates those results and never re-scores them.
//

import Foundation

nonisolated struct ScanTracker: Codable, Hashable, Sendable {
    var host: String
    /// Company id from trackers.json (e.g. "google").
    var company: String
    var companyName: String
    /// Category id from trackers.json (e.g. "advertising").
    var category: String
}

nonisolated struct SiteScan: Codable, Identifiable, Hashable, Sendable {
    var id: UUID
    var date: Date
    var pageHost: String
    var score: Int
    var label: String
    var trackers: [ScanTracker]
    /// Third-party domains that are not in the database (not scored).
    var otherThirdParty: Int
    /// Services owned by the visited site's own company (not scored).
    var firstPartyServices: Int
}

/// Wire format sent by background.js.
nonisolated struct ScanPayload: Decodable, Sendable {
    var pageHost: String
    var score: Int
    var label: String
    var trackers: [ScanTracker]
    var otherThirdParty: Int?
    var firstPartyServices: Int?
    /// Milliseconds since the Unix epoch.
    var scannedAt: Double?

    /// Validates and clamps everything — the payload crosses a process
    /// boundary and is never trusted as-is.
    func makeScan() -> SiteScan? {
        let host = pageHost
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        guard !host.isEmpty, host.count <= 253 else { return nil }

        func clip(_ value: String, _ limit: Int) -> String {
            String(value.prefix(limit))
        }

        let cleaned = trackers.prefix(200).map {
            ScanTracker(
                host: clip($0.host.lowercased(), 253),
                company: clip($0.company, 64),
                companyName: clip($0.companyName, 80),
                category: clip($0.category, 40)
            )
        }

        var date = Date()
        if let scannedAt {
            let candidate = Date(timeIntervalSince1970: scannedAt / 1000)
            let now = Date()
            if candidate <= now.addingTimeInterval(60),
               candidate >= now.addingTimeInterval(-86_400) {
                date = candidate
            }
        }

        return SiteScan(
            id: UUID(),
            date: date,
            pageHost: host,
            score: min(max(score, 0), 100),
            label: clip(label, 40),
            trackers: Array(cleaned),
            otherThirdParty: max(otherThirdParty ?? 0, 0),
            firstPartyServices: max(firstPartyServices ?? 0, 0)
        )
    }
}
