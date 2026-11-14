//
//  CredentialDetailView.swift
//  Netra
//

import SwiftUI
import UIKit
import Foundation
import SwiftData
import UniformTypeIdentifiers

struct CredentialDetailView: View {

    let credential: CredentialModel

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var allCredentials: [CredentialModel]

    @State private var revealedPassword: String?
    @State private var showingEdit = false
    @State private var showingDeleteConfirm = false
    @State private var copiedMessage: String?
    @State private var errorMessage: String?
    /// Set before deleting so the view never reads an invalidated model.
    @State private var isDeleted = false

    private var breakdown: CredentialScoreBreakdown {
        SecurityEngine.breakdown(for: credential)
    }

    var body: some View {
        if isDeleted {
            Color.clear
        } else {
            content
        }
    }

    private var content: some View {
        NetraScreen {
            scoreCard
            accountCard
            passwordCard
            checksCard
            if !recommendations.isEmpty { recommendationsCard }
        }
        .navigationTitle(credential.serviceName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showingEdit = true } label: { Label("Edit", systemImage: "pencil") }
                    Button(role: .destructive) { showingDeleteConfirm = true } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("More options")
            }
        }
        .sheet(isPresented: $showingEdit) {
            CredentialFormView(mode: .edit(credential))
        }
        .alert("Delete credential?", isPresented: $showingDeleteConfirm) {
            Button("Delete", role: .destructive, action: delete)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("\(credential.serviceName) and its saved password will be removed from this device.")
        }
        .alert("Something went wrong", isPresented: Binding(
            get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
        .onChange(of: showingEdit) { _, isShowing in
            // The password may have changed; never keep a stale copy on screen.
            if !isShowing { revealedPassword = nil }
        }
        .onDisappear { revealedPassword = nil }
    }

    // MARK: - Cards

    private var scoreCard: some View {
        NCard {
            HStack(spacing: NetraTheme.Spacing.l) {
                ScoreRing(score: breakdown.finalScore, size: 96, lineWidth: 10)
                VStack(alignment: .leading, spacing: 4) {
                    Text(TrackerCatalog.shared.label(forScore: breakdown.finalScore))
                        .font(NetraFont.title)
                    Text("Account security score")
                        .font(NetraFont.callout)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var accountCard: some View {
        NCard {
            VStack(spacing: NetraTheme.Spacing.l) {
                InfoRow(icon: "person.fill", title: "Username", detail: credential.username) {
                    Button { copy(credential.username, label: "Username") } label: {
                        Image(systemName: "doc.on.doc")
                    }
                    .accessibilityLabel("Copy username")
                }
                if let copiedMessage {
                    Text(copiedMessage)
                        .font(NetraFont.caption)
                        .foregroundStyle(NetraTheme.good)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var passwordCard: some View {
        NCard {
            VStack(alignment: .leading, spacing: NetraTheme.Spacing.m) {
                InfoRow(
                    icon: "key.fill",
                    tint: NetraTheme.violet,
                    title: "Password",
                    detail: revealedPassword ?? String(repeating: "•", count: min(max(credential.passwordLength, 6), 24))
                )

                HStack(spacing: NetraTheme.Spacing.m) {
                    Button(revealedPassword == nil ? "Reveal" : "Hide") {
                        if revealedPassword == nil {
                            Task { await reveal() }
                        } else {
                            revealedPassword = nil
                        }
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    Button("Copy") { Task { await copyPassword() } }
                        .buttonStyle(SecondaryButtonStyle())
                }

                Text("Copied passwords are removed from the clipboard after 60 seconds.")
                    .font(NetraFont.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var checksCard: some View {
        NCard {
            VStack(spacing: NetraTheme.Spacing.l) {
                checkRow("Password strength",
                         ok: !SecurityEngine.isWeak(credential),
                         good: "Strong enough", bad: "Weak — consider changing it")
                Divider()
                checkRow("Unique password",
                         ok: !credential.isReused,
                         good: "Not used on other accounts", bad: "Reused on another account")
                Divider()
                checkRow("Two-factor authentication",
                         ok: credential.hasTwoFactorAuthentication,
                         good: "Enabled", bad: "Not enabled")
            }
        }
    }

    private func checkRow(_ title: String, ok: Bool, good: String, bad: String) -> some View {
        InfoRow(
            icon: ok ? "checkmark.circle.fill" : "exclamationmark.triangle.fill",
            tint: ok ? NetraTheme.good : NetraTheme.warn,
            title: title,
            detail: ok ? good : bad
        )
    }

    private var recommendations: [String] {
        var items: [String] = []
        if SecurityEngine.isWeak(credential) {
            items.append("Use a longer password with letters, numbers and symbols. Netra can generate one for you.")
        }
        if credential.isReused {
            items.append("Choose a password that isn't used anywhere else.")
        }
        if !credential.hasTwoFactorAuthentication {
            items.append("Turn on two-factor authentication on \(credential.serviceName) if it's available.")
        }
        return items
    }

    private var recommendationsCard: some View {
        VStack(spacing: NetraTheme.Spacing.m) {
            SectionTitle(title: "How to improve")
            ForEach(recommendations, id: \.self) { text in
                NCard {
                    InfoRow(icon: "lightbulb.fill", tint: NetraTheme.warn, title: text)
                }
            }
        }
    }

    // MARK: - Actions

    private func reveal() async {
        guard await authorise("Reveal password for \(credential.serviceName)") else { return }
        do {
            revealedPassword = try CredentialService.password(for: credential)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func copyPassword() async {
        guard await authorise("Copy password for \(credential.serviceName)") else { return }
        do {
            let password = try CredentialService.password(for: credential)
            copy(password, label: "Password", sensitive: true)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Requires Face ID / passcode when the device has one set.
    private func authorise(_ reason: String) async -> Bool {
        guard Biometrics.isAvailable else { return true }
        return await Biometrics.authenticate(reason: reason)
    }

    private func copy(_ value: String, label: String, sensitive: Bool = false) {
        if sensitive {
            UIPasteboard.general.setItems(
                [[UTType.utf8PlainText.identifier: value]],
                options: [
                    .expirationDate: Date().addingTimeInterval(60),
                    .localOnly: true
                ]
            )
        } else {
            UIPasteboard.general.string = value
        }
        copiedMessage = "\(label) copied"
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            copiedMessage = nil
        }
    }

    private func delete() {
        let others = allCredentials
        isDeleted = true
        do {
            try CredentialService.delete(credential, all: others, context: modelContext)
            dismiss()
        } catch {
            isDeleted = false
            errorMessage = error.localizedDescription
        }
    }
}
