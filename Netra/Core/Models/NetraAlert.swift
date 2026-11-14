//
//  NetraAlert.swift
//  Netra
//

import Foundation

struct NetraAlert: Identifiable {

    enum Severity: Int, Comparable {
        case safe = 0
        case info
        case warning
        case critical

        static func < (lhs: Severity, rhs: Severity) -> Bool {
            lhs.rawValue < rhs.rawValue
        }

        var title: String {
            switch self {
            case .safe: "All clear"
            case .info: "Suggestion"
            case .warning: "Warning"
            case .critical: "Critical"
            }
        }
    }

    enum Source {
        case security
        case privacy
    }

    let id = UUID()
    let icon: String
    let title: String
    let detail: String
    let severity: Severity
    let source: Source
}
