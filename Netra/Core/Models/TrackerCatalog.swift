//
//  TrackerCatalog.swift
//  Netra
//
//  Reads trackers.json — the same file the Safari extension uses — so
//  company names, categories and explanations never drift apart.
//

import Foundation

nonisolated struct TrackerCatalog: Decodable {

    nonisolated struct Scoring: Decodable {
        let base: Int
        let categoryPenalty: [String: Int]
        let bands: [Band]
    }

    nonisolated struct Band: Decodable {
        let min: Int
        let label: String
    }

    nonisolated struct Category: Decodable {
        let title: String
        let risk: String
        let symbol: String
        let summary: String
        let advice: String
    }

    nonisolated struct Company: Decodable {
        let id: String
        let name: String
        let summary: String
        let trackers: [Entry]
    }

    nonisolated struct Entry: Decodable {
        let domain: String
        let category: String
        let what: String?
    }

    let version: Int
    let scoring: Scoring
    let categories: [String: Category]
    let companies: [Company]

    // MARK: - Shared instance

    static let shared: TrackerCatalog = {
        guard let url = Bundle.main.url(forResource: "trackers", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let catalog = try? JSONDecoder().decode(TrackerCatalog.self, from: data)
        else {
            assertionFailure("trackers.json is missing or invalid")
            return TrackerCatalog.empty
        }
        return catalog
    }()

    private static let empty = TrackerCatalog(
        version: 0,
        scoring: Scoring(base: 100, categoryPenalty: [:], bands: [Band(min: 0, label: "Unknown")]),
        categories: [:],
        companies: []
    )

    // MARK: - Lookups

    func company(id: String) -> Company? {
        companies.first { $0.id == id }
    }

    func category(id: String) -> Category? {
        categories[id]
    }

    func categoryTitle(_ id: String) -> String {
        categories[id]?.title ?? id.capitalized
    }

    func risk(of categoryID: String) -> TrackerRisk {
        TrackerRisk(categories[categoryID]?.risk ?? "low")
    }

    /// Plain-language description of what a specific tracker domain does.
    func explanation(forHost host: String) -> String? {
        for company in companies {
            if let entry = company.trackers.first(where: {
                host == $0.domain || host.hasSuffix("." + $0.domain)
            }) {
                return entry.what
            }
        }
        return nil
    }

    /// Band label for a score, using the same bands the extension uses.
    func label(forScore score: Int) -> String {
        scoring.bands
            .sorted { $0.min > $1.min }
            .first { score >= $0.min }?
            .label ?? "Unknown"
    }
}
