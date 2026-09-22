import SwiftUI
import SwiftData

struct HomeView: View {

    // MARK: - Stored Credentials

    @Query private var credentials: [CredentialModel]

    // MARK: - Privacy Data

    private var trackerCount: Int {
        PrivacyStore.detectedTrackers.count
    }

    private var privacyScore: Int {

        PrivacyEngine.calculatePrivacyScore(
            trackerCount: trackerCount
        )
    }

    // MARK: - Identity Data

    private var identityScore: Int {
        IdentityStore.identityScore
    }

    private var identityDetail: String {
        IdentityStore.identityDetail
    }

    private var breachCount: Int {
        IdentityStore.breachCount
    }
    
    // MARK: - Alert Data

    private var alertScore: Int {
        AlertStore.calculateAlertScore(
            from: credentials
        )
    }

    private var alertStatus: String {
        AlertStore.alertStatus(
            from: credentials
        )
    }
    
    // MARK: - Security Categories

    private var securityCategories: [SecurityCategory] {

        [
            SecurityCategory(
                icon: "key.fill",
                title: "Credentials",
                score: credentialScore,
                detail: credentialDetail
            ),

            SecurityCategory(
                icon: "eye.fill",
                title: "Privacy",
                score: privacyScore,
                detail: "\(trackerCount) trackers"
            ),

            SecurityCategory(
                icon: "person.fill",
                title: "Identity",
                score: identityScore,
                detail: identityDetail
            ),

            SecurityCategory(
                icon: "bell.fill",
                title: "Alerts",
                score: alertScore,
                detail: alertStatus
            )
        ]
    }

    // MARK: - Credential Score

    private var credentialScore: Int {

        guard !credentials.isEmpty else {
            return 0
        }

        let scores = credentials.map {

            SecurityEngine.calculateCredentialScore(
                for: $0.credential
            )
        }

        return scores.reduce(0, +) / scores.count
    }

    // MARK: - Credential Issue Count

    private var credentialIssueCount: Int {

        credentials.reduce(0) { total, credential in

            var issues = 0

            if SecurityEngine.hasWeakPassword(
                credential.credential
            ) {
                issues += 1
            }

            if SecurityEngine.hasReusedPassword(
                credential.credential
            ) {
                issues += 1
            }

            if SecurityEngine.needsTwoFactorAuthentication(
                credential.credential
            ) {
                issues += 1
            }

            return total + issues
        }
    }

    // MARK: - Credential Detail

    private var credentialDetail: String {

        guard !credentials.isEmpty else {
            return "No credentials"
        }

        if credentialIssueCount == 0 {
            return "No issues"
        }

        return "\(credentialIssueCount) issue\(credentialIssueCount == 1 ? "" : "s")"
    }

    // MARK: - Overall Security Score

    private var overallScore: Int {

        SecurityEngine.calculateOverallScore(
            categories: securityCategories
        )
    }

    // MARK: - Security Status

    private var securityStatus: String {

        switch overallScore {

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

    // MARK: - Security Status Icon

    private var securityStatusIcon: String {

        switch overallScore {

        case 90...100:
            return "checkmark.shield.fill"

        case 75..<90:
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

                VStack(spacing: 6) {

                    Text("NETRA")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("See Beyond the Surface.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // MARK: - Security Score

                VStack(spacing: 10) {

                    ScoreRing(
                        score: overallScore
                    )

                    Text("Security Score")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }

                // MARK: - Security Status

                HStack(spacing: 12) {

                    Image(systemName: securityStatusIcon)
                        .font(.title2)

                    VStack(
                        alignment: .leading,
                        spacing: 3
                    ) {

                        Text(securityStatus)
                            .font(.headline)

                        Text(
                            credentials.isEmpty
                                ? "Add credentials to improve your security analysis."
                                : "\(credentials.count) credential\(credentials.count == 1 ? "" : "s") analyzed by Netra."
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

                // MARK: - Security Overview

                VStack(
                    alignment: .leading,
                    spacing: 12
                ) {

                    Text("Security Overview")
                        .font(.headline)

                    // Credentials

                    NavigationLink {

                        SecurityView()

                    } label: {

                        SecurityCard(
                            icon: "key.fill",
                            title: "Credentials",
                            score: credentialScore,
                            detail: credentialDetail
                        )
                    }
                    .buttonStyle(.plain)

                    // Privacy

                    NavigationLink {

                        PrivacyView()

                    } label: {

                        SecurityCard(
                            icon: "eye.fill",
                            title: "Privacy",
                            score: privacyScore,
                            detail: "\(trackerCount) trackers"
                        )
                    }
                    .buttonStyle(.plain)

                    // Identity

                    NavigationLink {

                        IdentityView()

                    } label: {

                        SecurityCard(
                            icon: "person.fill",
                            title: "Identity",
                            score: identityScore,
                            detail: identityDetail
                        )
                    }
                    .buttonStyle(.plain)

                    // Alerts

                    NavigationLink {
                        AlertsView()
                    } label: {
                        SecurityCard(
                            icon: "bell.fill",
                            title: "Alerts",
                            score: alertScore,
                            detail: alertStatus
                        )
                    }
                    .buttonStyle(.plain)
                }
                // MARK: - Quick Actions

                VStack(
                    alignment: .leading,
                    spacing: 12
                ) {

                    Text("Quick Actions")
                        .font(.headline)

                    // Credentials

                    NavigationLink {

                        SecurityView()

                    } label: {

                        HomeActionRow(
                            icon: "key.fill",
                            title: "Review Credentials",
                            detail: credentials.isEmpty
                                ? "Add your first credential"
                                : "\(credentials.count) credential\(credentials.count == 1 ? "" : "s") stored"
                        )
                    }

                    // Privacy

                    NavigationLink {

                        PrivacyView()

                    } label: {

                        HomeActionRow(
                            icon: "eye.fill",
                            title: "Review Privacy",
                            detail: "\(trackerCount) trackers detected"
                        )
                    }

                    // Identity

                    NavigationLink {

                        IdentityView()

                    } label: {

                        HomeActionRow(
                            icon: "person.fill",
                            title: "Review Identity",
                            detail: breachCount == 0
                                ? "No known exposures"
                                : "\(breachCount) exposure\(breachCount == 1 ? "" : "s")"
                        )
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Home")
    }
}

// MARK: - Home Action Row

struct HomeActionRow: View {

    let icon: String
    let title: String
    let detail: String

    var body: some View {

        HStack(spacing: 14) {

            Image(systemName: icon)
                .font(.title3)
                .frame(
                    width: 42,
                    height: 42
                )
                .background(.thinMaterial)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 12
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

            Image(systemName: "chevron.right")
                .font(.caption)
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

// MARK: - Preview

#Preview {

    NavigationStack {

        HomeView()
    }
}
