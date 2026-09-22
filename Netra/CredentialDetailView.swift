import SwiftUI
import SwiftData

struct CredentialDetailView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var showingDeleteConfirmation = false
    @State private var showingPassword = false
    @State private var password = ""
    @State private var showingPasswordError = false
    @State private var passwordErrorMessage = ""

    private let keychain = KeychainManager.shared

    let credential: CredentialModel

    private var score: Int {
        SecurityEngine.calculateCredentialScore(
            for: credential.credential
        )
    }

    private var breakdown: CredentialScoreBreakdown {
        SecurityEngine.calculateCredentialBreakdown(
            for: credential.credential
        )
    }

    var body: some View {

        ScrollView {

            VStack(spacing: 24) {

                // MARK: - Score

                VStack(spacing: 10) {

                    ScoreRing(score: score)

                    Text("Credential Security")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }

                // MARK: - Score Breakdown

                VStack(alignment: .leading, spacing: 12) {

                    Text("Score Breakdown")
                        .font(.headline)

                    ScoreBreakdownRow(
                        title: "Base score",
                        value: breakdown.baseScore,
                        isPenalty: false
                    )

                    ScoreBreakdownRow(
                        title: "Password strength",
                        value: breakdown.passwordPenalty,
                        isPenalty: true
                    )

                    ScoreBreakdownRow(
                        title: "Reused password",
                        value: breakdown.reusePenalty,
                        isPenalty: true
                    )

                    ScoreBreakdownRow(
                        title: "Two-factor authentication",
                        value: breakdown.twoFactorPenalty,
                        isPenalty: true
                    )

                    Divider()

                    HStack {

                        Text("Final score")
                            .fontWeight(.semibold)

                        Spacer()

                        Text("\(breakdown.finalScore)")
                            .fontWeight(.bold)
                    }
                }
                .padding()
                .background(.regularMaterial)
                .clipShape(
                    RoundedRectangle(cornerRadius: 16)
                )

                // MARK: - Account

                VStack(alignment: .leading, spacing: 12) {

                    Text("Account")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 6) {

                        Text(credential.serviceName)
                            .font(.title3)
                            .fontWeight(.semibold)

                        Text(credential.username)
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
                }

                // MARK: - Password

                VStack(alignment: .leading, spacing: 12) {

                    Text("Password")
                        .font(.headline)

                    HStack {

                        if showingPassword {

                            Text(password.isEmpty ? "Unable to load password" : password)
                                .font(.body)
                                .textSelection(.enabled)

                        } else {

                            Text(password.isEmpty ? "••••••••••••" : "••••••••••••")
                                .font(.body)
                        }

                        Spacer()

                        Button {

                            if password.isEmpty {
                                loadPassword()
                            }

                            showingPassword.toggle()

                        } label: {

                            Image(
                                systemName: showingPassword
                                    ? "eye.slash.fill"
                                    : "eye.fill"
                            )
                        }
                        .accessibilityLabel(
                            showingPassword
                                ? "Hide password"
                                : "Show password"
                        )
                    }
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 16)
                    )
                }

                // MARK: - Security Checks

                VStack(alignment: .leading, spacing: 12) {

                    Text("Security Checks")
                        .font(.headline)

                    SecurityCheckRow(
                        title: "Password strength",
                        passed: credential.passwordLength >= 12
                    )

                    SecurityCheckRow(
                        title: "Unique password",
                        passed: !credential.isReused
                    )

                    SecurityCheckRow(
                        title: "Two-factor authentication",
                        passed: credential.hasTwoFactorAuthentication
                    )
                }

                // MARK: - Recommendations

                VStack(alignment: .leading, spacing: 12) {

                    Text("Recommendations")
                        .font(.headline)

                    recommendations
                }
            }
            .padding()
        }
        .navigationTitle(credential.serviceName)
        .navigationBarTitleDisplayMode(.inline)

        // MARK: - Toolbar

        .toolbar {

            ToolbarItemGroup(placement: .topBarTrailing) {

                NavigationLink {

                    EditCredentialView(
                        credential: credential
                    )

                } label: {

                    Image(systemName: "pencil")
                }

                Button(role: .destructive) {

                    showingDeleteConfirmation = true

                } label: {

                    Image(systemName: "trash")
                }
            }
        }

        // MARK: - Delete Confirmation

        .alert(
            "Delete Credential?",
            isPresented: $showingDeleteConfirmation
        ) {

            Button("Delete", role: .destructive) {
                deleteCredential()
            }

            Button("Cancel", role: .cancel) {
            }

        } message: {

            Text(
                "This will permanently remove \(credential.serviceName) and its saved password from Netra."
            )
        }

        // MARK: - Password Error

        .alert(
            "Unable to Retrieve Password",
            isPresented: $showingPasswordError
        ) {

            Button("OK") {
                showingPasswordError = false
            }

        } message: {

            Text(passwordErrorMessage)
        }
    }

    // MARK: - Recommendations

    @ViewBuilder
    private var recommendations: some View {

        if credential.passwordLength < 12 {

            RecommendationRow(
                icon: "lock.open.fill",
                title: "Use a stronger password",
                detail: "Consider using a password with at least 12 characters."
            )
        }

        if credential.isReused {

            RecommendationRow(
                icon: "arrow.triangle.2.circlepath",
                title: "Password appears to be reused",
                detail: "Use a unique password for this account."
            )
        }

        if !credential.hasTwoFactorAuthentication {

            RecommendationRow(
                icon: "lock.shield.fill",
                title: "Enable two-factor authentication",
                detail: "This adds another layer of protection to your account."
            )
        }

        if credential.passwordLength >= 12 &&
            !credential.isReused &&
            credential.hasTwoFactorAuthentication {

            RecommendationRow(
                icon: "checkmark.shield.fill",
                title: "No immediate issues",
                detail: "This credential currently meets Netra's security checks."
            )
        }
    }

    // MARK: - Load Password

    private func loadPassword() {

        do {

            password = try keychain.read(
                for: credential.id.uuidString
            )

        } catch {

            passwordErrorMessage = error.localizedDescription
            showingPasswordError = true
        }
    }

    // MARK: - Delete Credential

    private func deleteCredential() {

        do {

            // Delete the actual password from Keychain first.
            try keychain.delete(
                for: credential.id.uuidString
            )

            // Then delete the credential metadata.
            modelContext.delete(credential)

            try modelContext.save()

            print("✅ Credential and Keychain password deleted")

            dismiss()

        } catch {

            print("❌ Failed to delete credential: \(error)")

            passwordErrorMessage = error.localizedDescription
            showingPasswordError = true
        }
    }
}

// MARK: - Score Breakdown Row

struct ScoreBreakdownRow: View {

    let title: String
    let value: Int
    let isPenalty: Bool

    var body: some View {

        HStack {

            Text(title)

            Spacer()

            if isPenalty && value > 0 {

                Text("-\(value)")
                    .fontWeight(.semibold)

            } else {

                Text("\(value)")
                    .fontWeight(.semibold)
            }
        }
    }
}

// MARK: - Security Check Row

struct SecurityCheckRow: View {

    let title: String
    let passed: Bool

    var body: some View {

        HStack(spacing: 12) {

            Image(
                systemName: passed
                    ? "checkmark.circle.fill"
                    : "xmark.circle.fill"
            )
            .font(.title3)

            Text(title)
                .font(.body)

            Spacer()
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(
            RoundedRectangle(cornerRadius: 14)
        )
    }
}

// MARK: - Preview

#Preview {

    NavigationStack {

        CredentialDetailView(
            credential: CredentialModel(
                serviceName: "GitHub",
                username: "test@example.com",
                passwordLength: 16,
                isReused: false,
                hasTwoFactorAuthentication: true
            )
        )
    }
}
