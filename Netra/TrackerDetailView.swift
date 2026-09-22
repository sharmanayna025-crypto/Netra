import SwiftUI

struct TrackerDetailView: View {

    let tracker: PrivacyTracker

    // MARK: - Icon

    private var icon: String {
        switch tracker.category {
        case "Advertising":
            return "megaphone.fill"
        case "Analytics":
            return "chart.bar.fill"
        default:
            return "eye.fill"
        }
    }

    // MARK: - Risk Icon

    private var riskIcon: String {
        switch tracker.riskLevel {
        case "High":
            return "exclamationmark.triangle.fill"
        case "Medium":
            return "exclamationmark.circle.fill"
        default:
            return "checkmark.circle.fill"
        }
    }

    // MARK: - What It Does

    private var impactText: String {
        switch tracker.category {
        case "Advertising":
            return "This tracker may be used to understand your activity for advertising and personalization."

        case "Analytics":
            return "This tracker may collect information about how you interact with websites and services."

        default:
            return "This tracker may collect information about your browsing activity."
        }
    }

    // MARK: - Recommendation

    private var recommendationText: String {
        switch tracker.category {
        case "Advertising":
            return "Consider limiting tracking and personalized advertising when possible."

        case "Analytics":
            return "Review website privacy settings and consider limiting unnecessary analytics tracking."

        default:
            return "Review the website's privacy policy to understand how your information is used."
        }
    }

    // MARK: - Body

    var body: some View {

        ScrollView {

            VStack(spacing: 24) {

                // MARK: - Header

                VStack(spacing: 12) {

                    Image(systemName: icon)
                        .font(.system(size: 48))

                    Text(tracker.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text(tracker.domain)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(tracker.category)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.thinMaterial)
                        .clipShape(Capsule())
                }

                // MARK: - Privacy Risk

                VStack(alignment: .leading, spacing: 12) {

                    Text("Privacy Risk")
                        .font(.headline)

                    HStack(spacing: 14) {

                        Image(systemName: riskIcon)
                            .font(.title2)

                        VStack(
                            alignment: .leading,
                            spacing: 4
                        ) {

                            Text("\(tracker.riskLevel) Risk")
                                .font(.headline)

                            Text(riskDescription)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                }
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
                .padding()
                .background(.regularMaterial)
                .clipShape(
                    RoundedRectangle(cornerRadius: 16)
                )

                // MARK: - What It Does

                VStack(alignment: .leading, spacing: 12) {

                    Text("What It Does")
                        .font(.headline)

                    Text(impactText)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
                .padding()
                .background(.regularMaterial)
                .clipShape(
                    RoundedRectangle(cornerRadius: 16)
                )

                // MARK: - Privacy Impact

                VStack(alignment: .leading, spacing: 12) {

                    Text("Privacy Impact")
                        .font(.headline)

                    HStack(spacing: 12) {

                        Image(
                            systemName:
                                "exclamationmark.shield.fill"
                        )
                        .font(.title2)

                        Text(
                            "Third-party tracking can reduce your privacy by allowing services to observe activity across websites or services."
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                }
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
                .padding()
                .background(.regularMaterial)
                .clipShape(
                    RoundedRectangle(cornerRadius: 16)
                )

                // MARK: - Recommendation

                VStack(alignment: .leading, spacing: 12) {

                    Text("Recommendation")
                        .font(.headline)

                    HStack(spacing: 12) {

                        Image(
                            systemName:
                                "checkmark.shield.fill"
                        )
                        .font(.title2)

                        Text(recommendationText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
                .padding()
                .background(.regularMaterial)
                .clipShape(
                    RoundedRectangle(cornerRadius: 16)
                )
            }
            .padding()
        }
        .navigationTitle("Tracker Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Risk Description

    private var riskDescription: String {

        switch tracker.riskLevel {

        case "High":
            return "This tracker may have a significant impact on your privacy."

        case "Medium":
            return "This tracker may collect information about your activity."

        default:
            return "This tracker has a lower potential privacy impact."
        }
    }
}

// MARK: - Preview

#Preview {

    NavigationStack {

        TrackerDetailView(
            tracker: PrivacyTracker(
                name: "Google Analytics",
                domain: "google-analytics.com",
                category: "Analytics"
            )
        )
    }
}
