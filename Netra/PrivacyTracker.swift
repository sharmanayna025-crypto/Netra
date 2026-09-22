import Foundation

struct PrivacyTracker: Identifiable {

    let id = UUID()
    let name: String
    let domain: String
    let category: String

    var riskLevel: String {
        switch category {
        case "Advertising":
            return "High"

        case "Analytics":
            return "Medium"

        default:
            return "Low"
        }
    }
}
