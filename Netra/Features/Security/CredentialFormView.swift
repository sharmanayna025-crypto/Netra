//
//  CredentialFormView.swift
//  Netra
//
//  One form for adding and editing credentials (these used to be two
//  near-identical screens).
//

import SwiftUI
import Foundation
import SwiftData

struct CredentialFormView: View {

    enum Mode {
        case add
        case edit(CredentialModel)
    }

    let mode: Mode

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var allCredentials: [CredentialModel]

    @State private var serviceName = ""
    @State private var username = ""
    @State private var password = ""
    @State private var hasTwoFactor = false
    @State private var showPassword = false
    @State private var errorMessage: String?
    @FocusState private var focused: Field?

    private enum Field { case service, username, password }

    private var editing: CredentialModel? {
        if case .edit(let credential) = mode { return credential }
        return nil
    }

    private var isEditing: Bool { editing != nil }

    private var analysis: PasswordAnalysis? {
        password.isEmpty ? nil : PasswordAnalyzer.analyze(password)
    }

    private var canSave: Bool {
        !serviceName.trimmed.isEmpty
            && !username.trimmed.isEmpty
            && (isEditing || !password.isEmpty)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    TextField("Service (e.g. Netflix)", text: $serviceName)
                        .textInputAutocapitalization(.words)
                        .focused($focused, equals: .service)
                        .submitLabel(.next)
                        .onSubmit { focused = .username }

                    TextField("Username or email", text: $username)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .focused($focused, equals: .username)
                        .submitLabel(.next)
                        .onSubmit { focused = .password }
                }

                Section {
                    HStack {
                        Group {
                            if showPassword {
                                TextField(isEditing ? "New password (optional)" : "Password", text: $password)
                            } else {
                                SecureField(isEditing ? "New password (optional)" : "Password", text: $password)
                            }
                        }
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focused, equals: .password)

                        Button {
                            showPassword.toggle()
                        } label: {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(showPassword ? "Hide password" : "Show password")
                    }

                    Button {
                        password = PasswordGenerator.generate()
                        showPassword = true
                    } label: {
                        Label("Generate strong password", systemImage: "wand.and.stars")
                    }

                    if let analysis {
                        strengthMeter(analysis)
                    }
                } header: {
                    Text("Password")
                } footer: {
                    Text(isEditing
                         ? "Leave blank to keep the current password. Passwords are stored in the iOS Keychain."
                         : "Stored in the iOS Keychain. Netra never sends it anywhere.")
                }

                Section {
                    Toggle("Two-factor authentication", isOn: $hasTwoFactor)
                } footer: {
                    Text("Turn on if you've enabled 2FA for this account.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(NetraTheme.background.ignoresSafeArea())
            .navigationTitle(isEditing ? "Edit credential" : "Add credential")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!canSave)
                        .fontWeight(.semibold)
                }
            }
            .alert("Couldn't save", isPresented: Binding(
                get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
            .onAppear(perform: load)
        }
    }

    // MARK: - Strength meter

    private func strengthMeter(_ analysis: PasswordAnalysis) -> some View {
        let tint = NetraTheme.scoreColor(analysis.score)
        return VStack(alignment: .leading, spacing: NetraTheme.Spacing.s) {
            HStack {
                Text("Strength").font(NetraFont.callout)
                Spacer()
                Text(analysis.strength.rawValue)
                    .font(.system(.callout, design: .rounded).weight(.bold))
                    .foregroundStyle(tint)
            }
            MeterBar(value: Double(analysis.score) / 100, tint: tint)
            ForEach(analysis.issues.prefix(3), id: \.self) { issue in
                Label(issue, systemImage: "exclamationmark.circle")
                    .font(NetraFont.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Actions

    private func load() {
        guard let credential = editing else { return }
        serviceName = credential.serviceName
        username = credential.username
        hasTwoFactor = credential.hasTwoFactorAuthentication
    }

    private func save() {
        do {
            if let credential = editing {
                try CredentialService.update(
                    credential,
                    serviceName: serviceName,
                    username: username,
                    newPassword: password.isEmpty ? nil : password,
                    hasTwoFactor: hasTwoFactor,
                    all: allCredentials,
                    context: modelContext
                )
            } else {
                try CredentialService.add(
                    serviceName: serviceName,
                    username: username,
                    password: password,
                    hasTwoFactor: hasTwoFactor,
                    existing: allCredentials,
                    context: modelContext
                )
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
