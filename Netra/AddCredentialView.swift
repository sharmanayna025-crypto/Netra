import SwiftUI
import SwiftData

struct AddCredentialView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query private var existingCredentials: [CredentialModel]
    @State private var serviceName = ""
    @State private var username = ""
    @State private var password = ""
    @State private var hasTwoFactorAuthentication = false
    
    @State private var showingError = false
    @State private var errorMessage = ""
    
    private let keychain = KeychainManager.shared
    
    var body: some View {
        
        NavigationStack {
            
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
                        "Password",
                        text: $password
                    )
                    
                    Text(
                        password.isEmpty
                        ? "Enter a password to analyze it."
                        : "Password length: \(password.count)"
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
                    
                    Button("Save Credential") {
                        
                        saveCredential()
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(
                        serviceName.isEmpty ||
                        username.isEmpty ||
                        password.isEmpty
                    )
                }
            }
            .navigationTitle("Add Credential")
            .toolbar {
                
                ToolbarItem(placement: .cancellationAction) {
                    
                    Button("Cancel") {
                        
                        dismiss()
                    }
                }
            }
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
    }
    
    // MARK: - Save Credential

    private func saveCredential() {

        let credentialID = UUID()

        let credential = CredentialModel(
            id: credentialID,
            serviceName: serviceName,
            username: username,
            passwordLength: password.count,
            isReused: false,
            hasTwoFactorAuthentication: hasTwoFactorAuthentication
        )

        do {

            modelContext.insert(credential)

            try keychain.save(
                password,
                for: credentialID.uuidString
            )

            SecurityEngine.recalculatePasswordReuse(
                for: existingCredentials + [credential]
            )

            try modelContext.save()

            ActivityStore.shared.addEvent(
                icon: "key.fill",
                title: "Credential added",
                detail: "\(serviceName) was added to Netra."
            )

            print("✅ Credential saved")

            dismiss()

        } catch {

            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

#Preview {
    AddCredentialView()
}
