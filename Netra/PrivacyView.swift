import SwiftUI

struct PrivacyView: View {
   
    @Environment(\.scenePhase) private var scenePhase
    // MARK: - Privacy Data

    private var trackerCount: Int {
        PrivacyStore.detectedTrackers.count
    }

    private var privacyScore: Int {
        PrivacyEngine.calculatePrivacyScore(
            trackerCount: trackerCount
        )
    }

    private var privacyStatus: String {
        PrivacyEngine.privacyStatus(
            trackerCount: trackerCount
        )
    }

    private var trackingActivityStatus: String {
        switch trackerCount {
        case 0:
            return "Protected"

        case 1...3:
            return "Low Activity"

        case 4...6:
            return "Moderate"

        default:
            return "Needs Attention"
        }
    }

    private var thirdPartyStatus: String {
        if trackerCount == 0 {
            return "No Issues"
        } else if trackerCount <= 3 {
            return "Low Risk"
        } else {
            return "Needs Attention"
        }
    }

    private var privacyChecks: [PrivacyCheck] {
        [
            PrivacyCheck(
                icon: "eye.slash.fill",
                title: "Tracking Protection",
                detail: "Monitor websites for known tracking activity.",
                status: trackerCount == 0
                    ? "Protected"
                    : trackingActivityStatus
            ),

            PrivacyCheck(
                icon: "globe",
                title: "Website Tracking",
                detail: "Understand which websites may use trackers.",
                status: "\(trackerCount) tracker\(trackerCount == 1 ? "" : "s")"
            ),

            PrivacyCheck(
                icon: "person.crop.circle.badge.questionmark",
                title: "Third-Party Data",
                detail: "Learn when third-party services are involved.",
                status: thirdPartyStatus
            )
        ]
    }

    private var recommendations: [PrivacyRecommendation] {
        PrivacyEngine.recommendations(
            trackerCount: trackerCount
        )
    }

    // MARK: - Body

    var body: some View {

        ScrollView {

            VStack(spacing: 24) {

                // MARK: - Header

                VStack(spacing: 8) {

                    Image(systemName: "eye.fill")
                        .font(.system(size: 42))

                    Text("Privacy")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text(
                        "Understand what's happening behind the websites you use."
                    )
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                }

                // MARK: - Privacy Score

                VStack(spacing: 10) {

                    ScoreRing(
                        score: privacyScore
                    )

                    Text("Privacy Score")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Text(privacyStatus)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                }

                // MARK: - Tracker Summary

                NavigationLink {
                    TrackerListView()
                } label: {

                    VStack(
                        alignment: .leading,
                        spacing: 12
                    ) {

                        HStack {

                            Text("Tracking Activity")
                                .font(.headline)

                            Spacer()

                            Image(
                                systemName: "chevron.right"
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }

                        HStack(spacing: 16) {

                            Image(
                                systemName:
                                    "eye.trianglebadge.exclamationmark.fill"
                            )
                            .font(.title2)

                            VStack(
                                alignment: .leading,
                                spacing: 4
                            ) {

                                Text("\(trackerCount)")
                                    .font(.title2)
                                    .fontWeight(.bold)

                                Text(
                                    trackerCount == 1
                                        ? "Tracker detected"
                                        : "Trackers detected"
                                )
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }

                        Text(trackingActivityStatus)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                    }
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 16
                        )
                    )
                }
                .buttonStyle(.plain)

                // MARK: - Privacy Checks

                VStack(
                    alignment: .leading,
                    spacing: 12
                ) {

                    Text("Privacy Checks")
                        .font(.headline)

                    ForEach(privacyChecks) { check in

                        PrivacyCheckRow(
                            check: check
                        )
                    }
                }

                // MARK: - Recommendations

                VStack(
                    alignment: .leading,
                    spacing: 12
                ) {

                    Text("Recommendations")
                        .font(.headline)

                    ForEach(recommendations) { recommendation in

                        PrivacyRecommendationRow(
                            recommendation: recommendation
                        )
                    }
                }

                // MARK: - Safari Protection

                VStack(
                    alignment: .leading,
                    spacing: 10
                ) {

                    Label(
                        "Safari Protection",
                        systemImage: "safari.fill"
                    )
                    .font(.headline)

                    Text(
                        "Netra will be able to analyze websites for tracking activity using a Safari Web Extension."
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    Text("Coming in a future update")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                }
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
                .padding()
                .background(.regularMaterial)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 16
                    )
                )
            }
            .padding()
        }
        .navigationTitle("Privacy")
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                // Refresh the view when returning to the app
            }
        }
    }
}

// MARK: - Privacy Check Model

struct PrivacyCheck: Identifiable {

    let id = UUID()
    let icon: String
    let title: String
    let detail: String
    let status: String
}

// MARK: - Privacy Check Row

struct PrivacyCheckRow: View {

    let check: PrivacyCheck

    var body: some View {

        HStack(spacing: 14) {

            Image(systemName: check.icon)
                .frame(
                    width: 40,
                    height: 40
                )
                .background(.thinMaterial)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 10
                    )
                )

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text(check.title)
                    .font(.headline)

                Text(check.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(check.status)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 16
            )
        )
    }
}

// MARK: - Privacy Recommendation Row

struct PrivacyRecommendationRow: View {

    let recommendation: PrivacyRecommendation

    private var priorityIcon: String {

        switch recommendation.priority {

        case "High":
            return "exclamationmark.triangle.fill"

        case "Medium":
            return "exclamationmark.circle.fill"

        default:
            return "checkmark.circle.fill"
        }
    }

    var body: some View {

        HStack(
            alignment: .top,
            spacing: 14
        ) {

            Image(
                systemName: recommendation.icon
            )
            .font(.title3)
            .frame(
                width: 40,
                height: 40
            )
            .background(.thinMaterial)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 10
                )
            )

            VStack(
                alignment: .leading,
                spacing: 6
            ) {

                HStack {

                    Text(recommendation.title)
                        .font(.headline)

                    Spacer()

                    Image(
                        systemName: priorityIcon
                    )
                    .font(.caption)
                }

                Text(recommendation.message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("\(recommendation.priority) Priority")
                    .font(.caption)
                    .fontWeight(.semibold)
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
            RoundedRectangle(
                cornerRadius: 16
            )
        )
    }
}

// MARK: - Preview

#Preview {

    NavigationStack {
        PrivacyView()
    }
}
