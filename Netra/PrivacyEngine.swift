import Foundation

struct PrivacyEngine {

    // MARK: - Privacy Score

    static func calculatePrivacyScore(
        trackerCount: Int
    ) -> Int {

        switch trackerCount {

        case 0:
            return 100

        case 1...3:
            return 90

        case 4...6:
            return 80

        case 7...10:
            return 70

        case 11...20:
            return 55

        default:
            return 40
        }
    }

    // MARK: - Privacy Status

    static func privacyStatus(
        trackerCount: Int
    ) -> String {

        let score = calculatePrivacyScore(
            trackerCount: trackerCount
        )

        switch score {

        case 90...100:
            return "Excellent"

        case 75..<90:
            return "Good"

        case 50..<75:
            return "Needs Attention"

        default:
            return "At Risk"
        }
    }

    // MARK: - Privacy Risk

    static func isPrivacyAtRisk(
        trackerCount: Int
    ) -> Bool {

        calculatePrivacyScore(
            trackerCount: trackerCount
        ) < 50
    }

    // MARK: - Recommendations

    static func recommendations(
        trackerCount: Int
    ) -> [PrivacyRecommendation] {

        switch trackerCount {

        case 0:

            return [
                PrivacyRecommendation(
                    icon: "checkmark.shield.fill",
                    title: "Privacy Looks Good",
                    message: "No known trackers were detected.",
                    priority: "Low"
                )
            ]

        case 1...3:

            return [
                PrivacyRecommendation(
                    icon: "eye.slash.fill",
                    title: "Some Tracking Detected",
                    message: "A small amount of tracking activity was detected. Review the trackers when possible.",
                    priority: "Low"
                )
            ]

        case 4...6:

            return [
                PrivacyRecommendation(
                    icon: "hand.raised.fill",
                    title: "Limit Third-Party Tracking",
                    message: "Several trackers were detected. Consider limiting unnecessary third-party tracking.",
                    priority: "Medium"
                ),

                PrivacyRecommendation(
                    icon: "gearshape.fill",
                    title: "Review Privacy Settings",
                    message: "Check your browser and website privacy settings to reduce unwanted tracking.",
                    priority: "Medium"
                )
            ]

        case 7...10:

            return [
                PrivacyRecommendation(
                    icon: "exclamationmark.shield.fill",
                    title: "High Tracking Activity",
                    message: "A significant number of trackers were detected. Review your privacy settings and tracker activity.",
                    priority: "High"
                ),

                PrivacyRecommendation(
                    icon: "hand.raised.fill",
                    title: "Limit Third-Party Tracking",
                    message: "Consider blocking or limiting unnecessary third-party trackers where possible.",
                    priority: "High"
                ),

                PrivacyRecommendation(
                    icon: "safari.fill",
                    title: "Enable Privacy Protection",
                    message: "Consider using browser privacy protections to reduce tracking across websites.",
                    priority: "Medium"
                )
            ]

        default:

            return [
                PrivacyRecommendation(
                    icon: "exclamationmark.triangle.fill",
                    title: "Privacy At Risk",
                    message: "A very high number of trackers were detected. Review your privacy protections.",
                    priority: "High"
                ),

                PrivacyRecommendation(
                    icon: "hand.raised.fill",
                    title: "Reduce Tracking",
                    message: "Limit unnecessary third-party tracking and review website privacy settings.",
                    priority: "High"
                )
            ]
        }
    }
}
