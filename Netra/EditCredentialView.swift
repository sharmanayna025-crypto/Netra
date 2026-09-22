import SwiftUI
import SwiftData

struct EditCredentialView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - Credential

    let credential: CredentialModel

    // MARK: - Existing Credentials

    @Query private var existingCredentials: [CredentialModel]

    // MARK: - Form State

    @State private var serviceName: String
    @State private var username: String
    @State private var password: String
    @State private var hasTwoFactorAuthentication: Bool

    // MARK: - Error State

    @State private var showingError = false
    @State private var errorMessage = ""

    // MARK: - Keychain

    private let keychain = KeychainManager.shared

    // MARK: - Initializer

    init(credential: CredentialModel) {

        self.credential = credential

        _serviceName = State(
            initialValue: credential.serviceName
        )

        _username = State(
            initialValue: credential.username
        )

        _password = State(
            initialValue: ""
        )

        _hasTwoFactorAuthentication = State(
            initialValue: credential.hasTwoFactorAuthentication
        )
    }

    // MARK: - Body

    var body: some View {

        Form {

            // MARK: - Account

            Section("Account") {

                TextField(
                    "Service name",
                    text: $serviceName
                )
                .textInputAutocapitalization(.words)

                TextField(
                    "Username or email",
                    text: $username
                )
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
            }

            // MARK: - Password

            Section("Password") {

                SecureField(
                    "New password",
                    text: $password
                )

                Text(
                    password.isEmpty
                        ? "Leave empty to keep the current password."
                        : "New password length: \(password.count)"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            // MARK: - Security

            Section("Security") {

                Toggle(
                    "Two-factor authentication",
                    isOn: $hasTwoFactorAuthentication
                )
            }

            // MARK: - Save

            Section {

                Button("Save Changes") {

                    saveChanges()
                }
                .frame(maxWidth: .infinity)
                .disabled(
                    serviceName
                        .trimmingCharacters(
                            in: .whitespacesAndNewlines
                        )
                        .isEmpty
                    ||
                    username
                        .trimmingCharacters(
                            in: .whitespacesAndNewlines
                        )
                        .isEmpty
                )
            }
        }
        .navigationTitle("Edit Credential")
        .navigationBarTitleDisplayMode(.inline)
        .alert(
            "Unable to Save",
            isPresented: $showingError
        ) {

            Button("OK") {
                showingError = false
            }

        } message: {

            Text(errorMessage)
        }
    }

    // MARK: - Save Changes

    private func saveChanges() {

        let trimmedServiceName =
            serviceName.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        let trimmedUsername =
            username.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        // Update account information.

        credential.serviceName =
            trimmedServiceName

        credential.username =
            trimmedUsername

        credential.hasTwoFactorAuthentication =
            hasTwoFactorAuthentication

        // MARK: - Update Password

        if !password.isEmpty {

            do {

                try keychain.save(
                    password,
                    for: credential.id.uuidString
                )

                credential.passwordLength =
                    password.count

            } catch {

                errorMessage =
                    error.localizedDescription

                showingError = true

                return
            }
        }

        // MARK: - Recalculate Password Reuse

        SecurityEngine.recalculatePasswordReuse(
            for: existingCredentials
        )

        // MARK: - Save SwiftData

        do {

            try modelContext.save()

            print("✅ Credential updated")

            dismiss()

        } catch {

            errorMessage =
                error.localizedDescription

            showingError = true
        }
    }
}

// MARK: - Preview

#Preview {

    NavigationStack {

        EditCredentialView(
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
