import SwiftUI
import SwiftData

struct SecurityView: View {

    @Environment(\.modelContext) private var modelContext

    @Query private var credentials: [CredentialModel]

    @State private var showingAddCredential = false

    // MARK: - Body

    var body: some View {

        List {

            // MARK: - Security Score

            Section {

                VStack(spacing: 12) {

                    if let credentialScore {

                        ScoreRing(score: credentialScore)

                        HStack(spacing: 6) {

                            Image(
                                systemName: atRiskCount > 0
                                    ? "exclamationmark.shield.fill"
                                    : "checkmark.shield.fill"
                            )

                            Text(
                                atRiskCount > 0
                                    ? "\(atRiskCount) credential\(atRiskCount == 1 ? "" : "s") at risk"
                                    : "No credentials at risk"
                            )
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(
                            atRiskCount > 0
                                ? .orange
                                : .secondary
                        )

                    } else {

                        VStack(spacing: 8) {

                            Image(systemName: "key.slash")
                                .font(.largeTitle)

                            Text("No Credentials")
                                .font(.headline)

                            Text(
                                "Add a credential to calculate your security score."
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        }
                        .frame(height: 180)
                    }

                    Text("Credential Security")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    // MARK: Security Status

                    if credentialScore != nil {

                        VStack(spacing: 4) {

                            Text(securityStatus)
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            Text(
                                issueCount == 0
                                    ? "No security issues detected"
                                    : "\(issueCount) security issue\(issueCount == 1 ? "" : "s") detected"
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
            }

            // MARK: - Your Credentials

            Section("Your Credentials") {

                if credentials.isEmpty {

                    VStack(spacing: 8) {

                        Image(systemName: "key.slash")
                            .font(.title2)

                        Text("No credentials yet")
                            .font(.headline)

                        Text("Add an account to start monitoring its security.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)

                } else {

                    ForEach(credentials) { credential in

                        NavigationLink {

                            CredentialDetailView(
                                credential: credential
                            )

                        } label: {

                            CredentialRow(
                                credential: credential
                            )
                        }
                    }
                    .onDelete(perform: deleteCredentials)
                }
            }

            // MARK: - Recommendations

            Section("Recommendations") {

                if credentials.isEmpty {

                    RecommendationRow(
                        icon: "plus.circle.fill",
                        title: "Add your first credential",
                        detail: "Netra will analyze your credential security once you add an account."
                    )

                } else {

                    // Reused password

                    if credentials.contains(where: {
                        SecurityEngine.hasReusedPassword(
                            $0.credential
                        )
                    }) {

                        RecommendationRow(
                            icon: "exclamationmark.triangle.fill",
                            title: "Reused password detected",
                            detail: "Consider using a unique password for each account."
                        )
                    }

                    // Weak password

                    if credentials.contains(where: {
                        SecurityEngine.hasWeakPassword(
                            $0.credential
                        )
                    }) {

                        RecommendationRow(
                            icon: "key.fill",
                            title: "Weak password detected",
                            detail: "Use a password with at least 12 characters for better protection."
                        )
                    }

                    // Two-factor authentication

                    if credentials.contains(where: {
                        SecurityEngine.needsTwoFactorAuthentication(
                            $0.credential
                        )
                    }) {

                        RecommendationRow(
                            icon: "lock.shield.fill",
                            title: "Enable two-factor authentication",
                            detail: "Add another layer of protection to your accounts."
                        )
                    }

                    // Everything looks good

                    if credentials.allSatisfy({
                        SecurityEngine.calculateCredentialScore(
                            for: $0.credential
                        ) >= 75
                    }) {

                        RecommendationRow(
                            icon: "checkmark.shield.fill",
                            title: "Looking good",
                            detail: "Netra hasn't found any immediate credential issues."
                        )
                    }
                }
            }
        }
        .navigationTitle("Security")
        .toolbar {

            ToolbarItem(placement: .topBarTrailing) {

                Button {

                    showingAddCredential = true

                } label: {

                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add credential")
            }
        }
        .sheet(isPresented: $showingAddCredential) {

            AddCredentialView()
        }
    }

    // MARK: - Credential Score

    private var credentialScore: Int? {

        let scores = credentials.map {

            SecurityEngine.calculateCredentialScore(
                for: $0.credential
            )
        }

        guard !scores.isEmpty else {
            return nil
        }

        return scores.reduce(0, +) / scores.count
    }

    // MARK: - At Risk Count

    private var atRiskCount: Int {

        credentials.filter {

            SecurityEngine.isCredentialAtRisk(
                $0.credential
            )

        }.count
    }

    // MARK: - Issue Count

    private var issueCount: Int {

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

    // MARK: - Security Status

    private var securityStatus: String {

        guard let score = credentialScore else {
            return "No credentials"
        }

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

    // MARK: - Delete Credentials

    private func deleteCredentials(
        at offsets: IndexSet
    ) {

        for index in offsets {

            let credential = credentials[index]

            do {

                try KeychainManager.shared.delete(
                    for: credential.id.uuidString
                )

                modelContext.delete(credential)

            } catch {

                print(
                    "❌ Failed to delete credential: \(error)"
                )
            }
        }

        do {

            try modelContext.save()

            print("✅ Credential deleted")

        } catch {

            print(
                "❌ Failed to save deletion: \(error)"
            )
        }
    }
}

// MARK: - Credential Row

struct CredentialRow: View {

    let credential: CredentialModel

    private var score: Int {

        SecurityEngine.calculateCredentialScore(
            for: credential.credential
        )
    }

    private var status: String {

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

    private var statusColor: Color {

        switch score {

        case 90...100:
            return .green

        case 75..<90:
            return .blue

        case 50..<75:
            return .orange

        default:
            return .red
        }
    }

    var body: some View {

        HStack(spacing: 14) {

            Image(systemName: "key.fill")
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

                Text(credential.serviceName)
                    .font(.headline)

                Text(credential.username)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(
                alignment: .trailing,
                spacing: 2
            ) {

                Text("\(score)")
                    .font(.headline)

                Text(status)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(statusColor)
            }
        }
    }
}

// MARK: - Recommendation Row

struct RecommendationRow: View {

    let icon: String
    let title: String
    let detail: String

    var body: some View {

        HStack(
            alignment: .top,
            spacing: 12
        ) {

            Image(systemName: icon)

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
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {

    NavigationStack {

        SecurityView()
    }
}
