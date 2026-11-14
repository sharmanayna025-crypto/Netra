//
//  PrivacyModels.swift
//  Netra
//

import Foundation

/// Ordered so the highest risk sorts last (`max()` gives the worst).
nonisolated enum TrackerRisk: Int, Comparable {
    case low = 0
    case medium
    case high

    static func < (lhs: TrackerRisk, rhs: TrackerRisk) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    init(_ raw: String) {
        switch raw {
        case "high": self = .high
        case "medium": self = .medium
        default: self = .low
        }
    }

    var title: String {
        switch self {
        case .low: "Low risk"
        case .medium: "Medium risk"
        case .high: "High risk"
        }
    }
}

/// One tracking company as seen across the user's recent browsing.
struct CompanyExposure: Identifiable, Hashable {
    let id: String
    let name: String
    let categories: [String]
    let sites: [String]
    let trackerHosts: [String]
    let risk: TrackerRisk
}

struct OverallPrivacy {
    let score: Int
    let label: String
    let siteCount: Int
    let trackerCount: Int
    let companyCount: Int
}

struct PrivacyRecommendation: Identifiable {

    enum Priority: Int {
        case low = 0, medium, high

        var title: String {
            switch self {
            case .low: "Low"
            case .medium: "Medium"
            case .high: "High"
            }
        }
    }

    let id = UUID()
    let icon: String
    let title: String
    let message: String
    let priority: Priority
}

struct CategoryCount: Identifiable {
    let category: String
    let count: Int
    var id: String { category }
}

struct SiteTrackerGroup: Identifiable {
    let company: String
    let name: String
    let trackers: [ScanTracker]
    var id: String { company }
}
