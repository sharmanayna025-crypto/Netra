import Foundation

struct PrivacyStore {

    // MARK: - App Group

    private static let appGroup = "group.com.nvs.Netra"

    private static let trackerKey = "detectedTrackers"

    // MARK: - Detected Trackers

    static var detectedTrackers: [PrivacyTracker] {

        guard let defaults = UserDefaults(
            suiteName: appGroup
        ) else {
            return []
        }

        guard let domains = defaults.array(
            forKey: trackerKey
        ) as? [String] else {
            return []
        }

        return domains.map { domain in

            PrivacyTracker(
                name: trackerName(for: domain),
                domain: domain,
                category: trackerCategory(for: domain)
            )
        }
    }

    // MARK: - Tracker Count

    static var trackerCount: Int {
        detectedTrackers.count
    }

    // MARK: - Tracker Categories

    static var analyticsTrackers: [PrivacyTracker] {
        detectedTrackers.filter {
            $0.category == "Analytics"
        }
    }

    static var advertisingTrackers: [PrivacyTracker] {
        detectedTrackers.filter {
            $0.category == "Advertising"
        }
    }

    // MARK: - Tracker Name

    private static func trackerName(for domain: String) -> String {

        switch domain {

        case "google-analytics.com":
            return "Google Analytics"

        case "googletagmanager.com":
            return "Google Tag Manager"

        case "doubleclick.net":
            return "DoubleClick"

        case "facebook.net", "facebook.com":
            return "Meta"

        case "hotjar.com":
            return "Hotjar"

        case "clarity.ms":
            return "Microsoft Clarity"

        case "tiktok.com":
            return "TikTok"

        case "linkedin.com":
            return "LinkedIn"

        case "amazon-adsystem.com":
            return "Amazon Advertising"

        default:
            return domain
        }
    }

    // MARK: - Tracker Category

    private static func trackerCategory(for domain: String) -> String {

        switch domain {

        case "google-analytics.com",
             "googletagmanager.com",
             "hotjar.com",
             "clarity.ms":
            return "Analytics"

        case "doubleclick.net",
             "facebook.net",
             "facebook.com",
             "tiktok.com",
             "linkedin.com",
             "amazon-adsystem.com":
            return "Advertising"

        default:
            return "Other"
        }
    }
}
