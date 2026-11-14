//
//  SecurityView.swift
//  Netra
//

import SwiftUI
import Foundation
import SwiftData

struct SecurityView: View {

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CredentialModel.serviceName) private var credentials: [CredentialModel]

    @State private var showingAdd = false
    @State private var pendingDelete: CredentialModel?
    @State private var errorMessage: String?

    private var score: Int? { SecurityEngine.averageScore(credentials) }

    var body: some View {
        Group {
            if credentials.isEmpty {
                NetraScreen {
                    EmptyStateView(
                        icon: "key.fill",
                        title: "No credentials yet",
                        message: "Add an account to check its password strength, find reused passwords and track two-factor protection. Passwords are stored in the iOS Keychain, never in Netra's database.",
                        actionTitle: "Add credential"
                    ) { showingAdd = true }
                }
            } else {
                list
            }
        }
        .navigationTitle("Security")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingAdd = true } label: { Image(systemName: "plus") }
                    .accessibilityLabel("Add credential")
            }
        }
        .sheet(isPresented: $showingAdd) { CredentialFormView(mode: .add) }
        .alert(
            "Delete credential?",
            isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
            presenting: pendingDelete
        ) { credential in
            Button("Delete", role: .destructive) { delete(credential) }
            Button("Cancel", role: .cancel) {}
        } message: { credential in
            Text("\(credential.serviceName) and its saved password will be removed from this device.")
        }
        .alert("Something went wrong", isPresented: Binding(
            get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: - List

    private var list: some View {
        List {
            Section {
                summaryCard
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 12, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }

            Section {
                ForEach(credentials) { credential in
                    NavigationLink {
                        CredentialDetailView(credential: credential)
                    } label: {
                        row(credential)
                    }
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) { pendingDelete = credential } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            } header: {
                SectionTitle(title: "Accounts", subtitle: "\(credentials.count) saved")
                    .textCase(nil)
                    .foregroundStyle(.primary)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(NetraTheme.background.ignoresSafeArea())
    }

    private var summaryCard: some View {
        NCard {
            VStack(spacing: NetraTheme.Spacing.l) {
                HStack(spacing: NetraTheme.Spacing.l) {
                    ScoreRing(score: score, size: 96, lineWidth: 10)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(score.map { TrackerCatalog.shared.label(forScore: $0) } ?? "No score")
                            .font(NetraFont.title)
                        Text("Average across \(credentials.count) account\(credentials.count == 1 ? "" : "s")")
                            .font(NetraFont.callout)
                            .foregroundStyle(.secondary)
                    }
                }
                Divider()
                HStack {
                    stat("Weak", SecurityEngine.weakCount(credentials), icon: "key.fill")
                    stat("Reused", SecurityEngine.reusedCount(credentials), icon: "arrow.triangle.2.circlepath")
                    stat("No 2FA", SecurityEngine.withoutTwoFactorCount(credentials), icon: "lock.open.fill")
                }
            }
        }
    }

    private func stat(_ title: String, _ count: Int, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(count == 0 ? NetraTheme.good : NetraTheme.warn)
            Text("\(count)").font(NetraFont.number(22))
            Text(title).font(NetraFont.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private func row(_ credential: CredentialModel) -> some View {
        NCard {
            InfoRow(
                icon: "person.crop.circle.fill",
                tint: NetraTheme.scoreColor(SecurityEngine.score(for: credential)),
                title: credential.serviceName,
                detail: credential.username
            ) {
                ScoreBadge(score: SecurityEngine.score(for: credential))
            }
        }
    }

    // MARK: - Actions

    private func delete(_ credential: CredentialModel) {
        do {
            try CredentialService.delete(credential, all: credentials, context: modelContext)
        } catch {
            errorMessage = error.localizedDescription
        }
        pendingDelete = nil
    }
}
