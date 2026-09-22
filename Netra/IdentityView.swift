import SwiftUI

struct IdentityView: View {

    // MARK: - Identity Data

    private var emailExposure: Bool {
        IdentityStore.emailExposure
    }

    private var phoneExposure: Bool {
        IdentityStore.phoneExposure
    }

    private var breachCount: Int {
        IdentityStore.breachCount
    }

    private var identityScore: Int {
        IdentityStore.identityScore
    }

    private var identityStatus: String {
        switch identityScore {
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

    private var statusIcon: String {
        switch identityScore {
        case 75...100:
            return "checkmark.shield.fill"
        case 50..<75:
            return "exclamationmark.shield.fill"
        default:
            return "exclamationmark.triangle.fill"
        }
    }

    // MARK: - Body

    var body: some View {

        ScrollView {

            VStack(spacing: 24) {

                // MARK: - Header

                VStack(spacing: 8) {

                    Image(
                        systemName: "person.crop.circle.fill"
                    )
                    .font(.system(size: 42))

                    Text("Identity")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text(
                        "Understand and protect your digital identity."
                    )
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                }

                // MARK: - Identity Score

                VStack(spacing: 10) {

                    ScoreRing(
                        score: identityScore
                    )

                    Text("Identity Protection")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Text(identityStatus)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                }

                // MARK: - Status

                HStack(spacing: 12) {

                    Image(systemName: statusIcon)
                        .font(.title2)

                    VStack(
                        alignment: .leading,
                        spacing: 3
                    ) {

                        Text(identityStatus)
                            .font(.headline)

                        Text(
                            "Netra is monitoring your identity security."
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .padding()
                .background(.regularMaterial)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 16
                    )
                )

                // MARK: - Identity Checks

                VStack(
                    alignment: .leading,
                    spacing: 12
                ) {

                    Text("Identity Checks")
                        .font(.headline)

                    IdentityCheckRow(
                        icon: "envelope.fill",
                        title: "Email Exposure",
                        detail: emailExposure
                            ? "Your email may appear in a known exposure."
                            : "No email exposure is currently recorded.",
                        passed: !emailExposure
                    )

                    IdentityCheckRow(
                        icon: "phone.fill",
                        title: "Phone Exposure",
                        detail: phoneExposure
                            ? "Your phone number may appear in a known exposure."
                            : "No phone exposure is currently recorded.",
                        passed: !phoneExposure
                    )

                    IdentityCheckRow(
                        icon: "person.crop.circle.badge.checkmark",
                        title: "Identity Status",
                        detail: breachCount == 0
                            ? "No identity issues are currently recorded."
                            : "\(breachCount) known exposure\(breachCount == 1 ? "" : "s") detected.",
                        passed: breachCount == 0
                    )
                }

                // MARK: - Breach Monitoring

                VStack(
                    alignment: .leading,
                    spacing: 12
                ) {

                    Text("Breach Monitoring")
                        .font(.headline)

                    HStack(spacing: 16) {

                        Image(
                            systemName: "shield.lefthalf.filled"
                        )
                        .font(.title2)

                        VStack(
                            alignment: .leading,
                            spacing: 4
                        ) {

                            Text("\(breachCount)")
                                .font(.title2)
                                .fontWeight(.bold)

                            Text(
                                breachCount == 0
                                    ? "Known exposures"
                                    : "Known exposures detected"
                            )
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 16
                        )
                    )
                }

                // MARK: - Recommendations

                VStack(
                    alignment: .leading,
                    spacing: 12
                ) {

                    Text("Recommendations")
                        .font(.headline)

                    if emailExposure {

                        IdentityRecommendationRow(
                            icon: "envelope.badge.fill",
                            title: "Review email exposure",
                            detail: "Consider securing accounts associated with an exposed email."
                        )
                    }

                    if phoneExposure {

                        IdentityRecommendationRow(
                            icon: "phone.badge.fill",
                            title: "Review phone exposure",
                            detail: "Consider reviewing accounts connected to your phone number."
                        )
                    }

                    if breachCount > 0 {

                        IdentityRecommendationRow(
                            icon: "exclamationmark.triangle.fill",
                            title: "Review exposed accounts",
                            detail: "Change affected passwords and enable two-factor authentication."
                        )
                    }

                    if !emailExposure &&
                        !phoneExposure &&
                        breachCount == 0 {

                        IdentityRecommendationRow(
                            icon: "checkmark.shield.fill",
                            title: "No immediate issues",
                            detail: "Netra has not recorded any identity exposure."
                        )
                    }
                }

                // MARK: - Coming Soon

                VStack(
                    alignment: .leading,
                    spacing: 10
                ) {

                    Label(
                        "Breach Database Monitoring",
                        systemImage: "antenna.radiowaves.left.and.right"
                    )
                    .font(.headline)

                    Text(
                        "Netra will be able to check supported breach databases and notify you when your identity appears in a known exposure."
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
        .navigationTitle("Identity")
    }
}

// MARK: - Identity Check Row

struct IdentityCheckRow: View {

    let icon: String
    let title: String
    let detail: String
    let passed: Bool

    var body: some View {

        HStack(
            alignment: .top,
            spacing: 14
        ) {

            Image(systemName: icon)
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
                spacing: 4
            ) {

                Text(title)
                    .font(.headline)

                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(
                systemName: passed
                    ? "checkmark.circle.fill"
                    : "xmark.circle.fill"
            )
            .font(.title3)
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

// MARK: - Identity Recommendation Row

struct IdentityRecommendationRow: View {

    let icon: String
    let title: String
    let detail: String

    var body: some View {

        HStack(
            alignment: .top,
            spacing: 12
        ) {

            Image(systemName: icon)
                .font(.title3)

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text(title)
                    .font(.headline)

                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
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
        IdentityView()
    }
}
