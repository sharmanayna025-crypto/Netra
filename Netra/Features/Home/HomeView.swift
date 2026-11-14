//
//  HomeView.swift
//  Netra
//

import SwiftUI
import Foundation
import SwiftData

struct HomeView: View {

    let selectTab: (AppTab) -> Void

    @Query private var credentials: [CredentialModel]
    @EnvironmentObject private var scanRepository: ScanRepository

    @State private var showingSettings = false
    @State private var showingAddCredential = false
    @State private var showingSetup = false

    // MARK: - Derived data

    private var privacy: OverallPrivacy? {
        PrivacyEngine.overall(from: scanRepository.scans)
    }

    private var credentialScore: Int? {
        SecurityEngine.averageScore(credentials)
    }

    /// Average of the parts that actually have data. Identity is excluded
    /// until real breach checks exist.
    private var protectionScore: Int? {
        let parts = [privacy?.score, credentialScore].compactMap { $0 }
        guard !parts.isEmpty else { return nil }
        return Int((Double(parts.reduce(0, +)) / Double(parts.count)).rounded())
    }

    private var alerts: [NetraAlert] {
        AlertEngine.alerts(credentials: credentials, scans: scanRepository.scans)
    }

    private var topExposure: CompanyExposure? {
        PrivacyEngine.exposures(from: scanRepository.scans).first
    }

    // MARK: - Body

    var body: some View {
        NetraScreen {
            hero
            overview
            insight
            quickActions
        }
        .navigationTitle("Netra")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                }
                .accessibilityLabel("Settings")
            }
        }
        .sheet(isPresented: $showingSettings) { SettingsView() }
        .sheet(isPresented: $showingAddCredential) { CredentialFormView(mode: .add) }
        .sheet(isPresented: $showingSetup) {
            NavigationStack { ExtensionSetupView() }
        }
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(spacing: NetraTheme.Spacing.l) {
            if let score = protectionScore {
                ScoreRing(score: score, size: 148, lineWidth: 14, onGradient: true)
                VStack(spacing: 4) {
                    Text(TrackerCatalog.shared.label(forScore: score))
                        .font(NetraFont.title)
                        .foregroundStyle(.white)
                    Text("Your protection score")
                        .font(NetraFont.callout)
                        .foregroundStyle(.white.opacity(0.8))
                }
            } else {
                Image(systemName: "eye.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.white)
                    .accessibilityHidden(true)
                VStack(spacing: 4) {
                    Text("See beyond the surface")
                        .font(NetraFont.title)
                        .foregroundStyle(.white)
                    Text("Add a credential or turn on the Safari extension to get your first score.")
                        .font(NetraFont.callout)
                        .foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                }
                HStack(spacing: NetraTheme.Spacing.m) {
                    Button("Add credential") { showingAddCredential = true }
                        .buttonStyle(SecondaryButtonStyle(onGradient: true))
                    Button("Set up Safari") { showingSetup = true }
                        .buttonStyle(SecondaryButtonStyle(onGradient: true))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, NetraTheme.Spacing.xl)
        .padding(.horizontal, NetraTheme.Spacing.l)
        .background(
            NetraTheme.brandGradient,
            in: RoundedRectangle(cornerRadius: 28, style: .continuous)
        )
    }

    // MARK: - Overview

    private var overview: some View {
        VStack(spacing: NetraTheme.Spacing.m) {
            SectionTitle(title: "Overview")

            Button { selectTab(.privacy) } label: {
                NCard {
                    InfoRow(
                        icon: "eye.fill",
                        tint: NetraTheme.brand,
                        title: "Browsing privacy",
                        detail: privacy.map {
                            "\($0.siteCount) sites · \($0.companyCount) tracking companies"
                        } ?? "Turn on the Safari extension to start"
                    ) {
                        scoreOrDash(privacy?.score)
                    }
                }
            }
            .buttonStyle(.plain)

            Button { selectTab(.security) } label: {
                NCard {
                    InfoRow(
                        icon: "key.fill",
                        tint: NetraTheme.violet,
                        title: "Credentials",
                        detail: credentialDetail
                    ) {
                        scoreOrDash(credentialScore)
                    }
                }
            }
            .buttonStyle(.plain)

            NavigationLink {
                IdentityView()
            } label: {
                NCard {
                    InfoRow(
                        icon: "person.fill",
                        tint: NetraTheme.ok,
                        title: "Identity",
                        detail: "Breach monitoring is on the way"
                    ) {
                        ComingSoonPill()
                    }
                }
            }
            .buttonStyle(.plain)

            NavigationLink {
                AlertsView()
            } label: {
                NCard {
                    InfoRow(
                        icon: "bell.fill",
                        tint: alerts.isEmpty ? NetraTheme.good : NetraTheme.warn,
                        title: "Alerts",
                        detail: alerts.isEmpty
                            ? "Nothing needs your attention"
                            : "\(alerts.count) item\(alerts.count == 1 ? "" : "s") to review"
                    ) {
                        if !alerts.isEmpty {
                            StatusPill(text: "\(alerts.count)", tint: NetraTheme.warn)
                        }
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var credentialDetail: String {
        if credentials.isEmpty { return "Add an account to start monitoring" }
        let issues = SecurityEngine.weakCount(credentials)
            + SecurityEngine.reusedCount(credentials)
        return issues == 0
            ? "\(credentials.count) accounts · no issues"
            : "\(credentials.count) accounts · \(issues) issue\(issues == 1 ? "" : "s")"
    }

    @ViewBuilder
    private func scoreOrDash(_ score: Int?) -> some View {
        if let score {
            ScoreBadge(score: score)
        } else {
            Text("–").font(NetraFont.number(18)).foregroundStyle(.secondary)
        }
    }

    // MARK: - Insight

    @ViewBuilder
    private var insight: some View {
        if let top = topExposure, top.sites.count >= 2 {
            NCard {
                InfoRow(
                    icon: "lightbulb.fill",
                    tint: NetraTheme.warn,
                    title: "\(top.name) saw the most",
                    detail: "It appeared on \(top.sites.count) sites you visited this week."
                )
            }
        }
    }

    // MARK: - Quick actions

    private var quickActions: some View {
        VStack(spacing: NetraTheme.Spacing.m) {
            SectionTitle(title: "Quick actions")

            Button { showingAddCredential = true } label: {
                NCard {
                    InfoRow(icon: "plus.circle.fill", title: "Add a credential",
                            detail: "Check a password and its 2FA status") {
                        chevron
                    }
                }
            }
            .buttonStyle(.plain)

            Button { showingSetup = true } label: {
                NCard {
                    InfoRow(icon: "safari.fill", tint: NetraTheme.ok, title: "Safari extension",
                            detail: "How to turn on tracker scanning") {
                        chevron
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var chevron: some View {
        Image(systemName: "chevron.right")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.tertiary)
    }
}
