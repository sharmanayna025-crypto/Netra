//
//  SiteDetailView.swift
//  Netra
//

import SwiftUI
import Foundation

struct SiteDetailView: View {

    let scan: SiteScan

    private var grouped: [SiteTrackerGroup] {
        let groups = Dictionary(grouping: scan.trackers, by: \.company)
        return groups
            .map { SiteTrackerGroup(company: $0.key, name: $0.value.first?.companyName ?? $0.key, trackers: $0.value) }
            .sorted { $0.name < $1.name }
    }

    var body: some View {
        NetraScreen {
            NCard {
                HStack(spacing: NetraTheme.Spacing.l) {
                    ScoreRing(score: scan.score, size: 96, lineWidth: 10)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(scan.label).font(NetraFont.title)
                        Text("Scanned \(scan.date.relativeDescription)")
                            .font(NetraFont.callout)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if scan.trackers.isEmpty {
                NCard {
                    InfoRow(icon: "checkmark.shield.fill", tint: NetraTheme.good,
                            title: "No known trackers",
                            detail: "Nothing in Netra's database was found on this site.")
                }
            } else {
                VStack(spacing: NetraTheme.Spacing.m) {
                    SectionTitle(title: "Trackers on this site")
                    ForEach(grouped) { group in
                        NCard {
                            VStack(alignment: .leading, spacing: NetraTheme.Spacing.s) {
                                Text(group.name).font(NetraFont.headline)
                                ForEach(group.trackers, id: \.self) { tracker in
                                    HStack {
                                        Text(tracker.host)
                                            .font(.system(.footnote, design: .monospaced))
                                        Spacer()
                                        CategoryChip(categoryID: tracker.category)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            NCard {
                VStack(alignment: .leading, spacing: NetraTheme.Spacing.s) {
                    if scan.otherThirdParty > 0 {
                        Label("\(scan.otherThirdParty) other third-party domains weren't recognised, so they aren't scored.",
                              systemImage: "questionmark.circle")
                    }
                    if scan.firstPartyServices > 0 {
                        Label("\(scan.firstPartyServices) services owned by this site's own company were treated as first party.",
                              systemImage: "building.2")
                    }
                    Label("A high score means no known trackers, not a guarantee of privacy.",
                          systemImage: "info.circle")
                }
                .font(NetraFont.caption)
                .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(scan.pageHost)
        .navigationBarTitleDisplayMode(.inline)
    }
}
