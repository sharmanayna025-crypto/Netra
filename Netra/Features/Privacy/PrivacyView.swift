//
//  PrivacyView.swift
//  Netra
//

import SwiftUI
import Foundation

struct PrivacyView: View {

    @EnvironmentObject private var scanRepository: ScanRepository
    @State private var showingSetup = false

    private var scans: [SiteScan] { scanRepository.scans }
    private var overall: OverallPrivacy? { PrivacyEngine.overall(from: scans) }
    private var exposures: [CompanyExposure] { PrivacyEngine.exposures(from: scans) }
    private var recentSites: [SiteScan] { Array(PrivacyEngine.recentScans(scans).prefix(8)) }
    private var categories: [CategoryCount] { PrivacyEngine.categoryCounts(from: scans) }

    var body: some View {
        NetraScreen {
            if let overall {
                summaryCard(overall)
                exposureSection
                categorySection
                sitesSection
                recommendationsSection
                comingSoonSection
            } else {
                EmptyStateView(
                    icon: "safari.fill",
                    title: "No browsing data yet",
                    message: "Turn on the Netra Safari extension. As you browse, Netra shows who is tracking you and scores every site. Everything stays on this device.",
                    actionTitle: "Set up Safari extension"
                ) { showingSetup = true }

                comingSoonSection
            }
        }
        .navigationTitle("Privacy")
        .sheet(isPresented: $showingSetup) {
            NavigationStack { ExtensionSetupView() }
        }
    }

    // MARK: - Summary

    private func summaryCard(_ overall: OverallPrivacy) -> some View {
        NCard {
            HStack(spacing: NetraTheme.Spacing.l) {
                ScoreRing(score: overall.score, size: 104, lineWidth: 10)

                VStack(alignment: .leading, spacing: NetraTheme.Spacing.xs) {
                    Text(overall.label)
                        .font(NetraFont.title)
                    Text("Based on \(overall.siteCount) site\(overall.siteCount == 1 ? "" : "s") in the last \(PrivacyEngine.windowDays) days.")
                        .font(NetraFont.callout)
                        .foregroundStyle(.secondary)
                    Text("\(overall.trackerCount) tracker connections from \(overall.companyCount) companies.")
                        .font(NetraFont.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Who's following you

    private var exposureSection: some View {
        VStack(spacing: NetraTheme.Spacing.m) {
            SectionTitle(
                title: "Who is following you",
                subtitle: "Companies seen across the sites you visited"
            )

            if exposures.isEmpty {
                NCard {
                    InfoRow(icon: "checkmark.shield.fill", tint: NetraTheme.good,
                            title: "No known trackers",
                            detail: "None of the recent sites contacted a company in Netra's database.")
                }
            } else {
                ForEach(exposures.prefix(5)) { exposure in
                    NavigationLink {
                        CompanyDetailView(exposure: exposure)
                    } label: {
                        NCard { companyRow(exposure) }
                    }
                    .buttonStyle(.plain)
                }

                if exposures.count > 5 {
                    NavigationLink {
                        TrackerListView(exposures: exposures)
                    } label: {
                        Text("See all \(exposures.count) companies")
                            .font(.system(.body, design: .rounded).weight(.semibold))
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
        }
    }

    private func companyRow(_ exposure: CompanyExposure) -> some View {
        InfoRow(
            icon: TrackerCatalog.shared.category(id: exposure.categories.first ?? "")?.symbol ?? "eye.fill",
            tint: NetraTheme.riskColor(exposure.risk),
            title: exposure.name,
            detail: "Seen on \(exposure.sites.count) site\(exposure.sites.count == 1 ? "" : "s")"
        ) {
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: - Categories

    private var categorySection: some View {
        VStack(spacing: NetraTheme.Spacing.m) {
            SectionTitle(title: "What they do")

            NCard {
                VStack(spacing: NetraTheme.Spacing.m) {
                    let maxCount = Double(categories.map(\.count).max() ?? 1)
                    ForEach(categories) { item in
                        let info = TrackerCatalog.shared.category(id: item.category)
                        let tint = NetraTheme.riskColor(TrackerCatalog.shared.risk(of: item.category))
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Label(info?.title ?? item.category, systemImage: info?.symbol ?? "circle")
                                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                Spacer()
                                Text("\(item.count)")
                                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                                    .foregroundStyle(tint)
                            }
                            MeterBar(value: Double(item.count) / maxCount, tint: tint)
                            if let summary = info?.summary {
                                Text(summary)
                                    .font(NetraFont.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Recent sites

    private var sitesSection: some View {
        VStack(spacing: NetraTheme.Spacing.m) {
            SectionTitle(title: "Recent sites")

            ForEach(recentSites) { scan in
                NavigationLink {
                    SiteDetailView(scan: scan)
                } label: {
                    NCard {
                        InfoRow(
                            icon: "globe",
                            tint: NetraTheme.scoreColor(scan.score),
                            title: scan.pageHost,
                            detail: "\(scan.trackers.count) tracker\(scan.trackers.count == 1 ? "" : "s") · \(scan.date.relativeDescription)"
                        ) {
                            ScoreBadge(score: scan.score)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Recommendations

    private var recommendationsSection: some View {
        VStack(spacing: NetraTheme.Spacing.m) {
            SectionTitle(title: "Recommendations")

            ForEach(PrivacyEngine.recommendations(from: scans)) { item in
                NCard {
                    InfoRow(
                        icon: item.icon,
                        tint: item.priority == .high ? NetraTheme.bad
                            : item.priority == .medium ? NetraTheme.warn : NetraTheme.good,
                        title: item.title,
                        detail: item.message
                    )
                }
            }

            NCard {
                InfoRow(
                    icon: "hand.raised.fill",
                    title: "Pair Netra with Safari's protections",
                    detail: "Netra shows who tracks you and why. Safari's Intelligent Tracking Prevention and “Hide IP Address” reduce it. Use both."
                )
            }
        }
    }

    // MARK: - Coming soon

    private var comingSoonSection: some View {
        VStack(spacing: NetraTheme.Spacing.m) {
            SectionTitle(title: "On the roadmap")

            NCard {
                VStack(spacing: NetraTheme.Spacing.l) {
                    InfoRow(icon: "slider.horizontal.3", tint: NetraTheme.violet,
                            title: "Cookie audit", detail: "See cookies and how long they last.") { ComingSoonPill() }
                    Divider()
                    InfoRow(icon: "shield.lefthalf.filled", tint: NetraTheme.violet,
                            title: "Tracker blocking", detail: "Block the worst offenders per site.") { ComingSoonPill() }
                }
            }
        }
    }
}
