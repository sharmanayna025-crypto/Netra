//
//  CompanyDetailView.swift
//  Netra
//

import SwiftUI
import Foundation

struct CompanyDetailView: View {

    let exposure: CompanyExposure

    private var catalog: TrackerCatalog { .shared }
    private var company: TrackerCatalog.Company? { catalog.company(id: exposure.id) }

    var body: some View {
        NetraScreen {
            header
            whatItDoes
            sitesCard
            domainsCard
            adviceCard
        }
        .navigationTitle(exposure.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        NCard {
            VStack(alignment: .leading, spacing: NetraTheme.Spacing.m) {
                HStack {
                    StatusPill(text: exposure.risk.title, tint: NetraTheme.riskColor(exposure.risk))
                    Spacer()
                }
                Text(exposure.name).font(NetraFont.largeTitle)
                if let summary = company?.summary {
                    Text(summary)
                        .font(NetraFont.body)
                        .foregroundStyle(.secondary)
                }
                HStack { ForEach(exposure.categories, id: \.self) { CategoryChip(categoryID: $0) } }
            }
        }
    }

    private var whatItDoes: some View {
        VStack(spacing: NetraTheme.Spacing.m) {
            SectionTitle(title: "What it does")
            ForEach(exposure.categories, id: \.self) { id in
                if let info = catalog.category(id: id) {
                    NCard {
                        InfoRow(
                            icon: info.symbol,
                            tint: NetraTheme.riskColor(catalog.risk(of: id)),
                            title: info.title,
                            detail: info.summary
                        )
                    }
                }
            }
        }
    }

    private var sitesCard: some View {
        VStack(spacing: NetraTheme.Spacing.m) {
            SectionTitle(title: "Seen on", subtitle: "Sites you visited recently")
            NCard {
                VStack(alignment: .leading, spacing: NetraTheme.Spacing.s) {
                    ForEach(exposure.sites, id: \.self) { site in
                        Label(site, systemImage: "globe")
                            .font(NetraFont.callout)
                    }
                }
            }
        }
    }

    private var domainsCard: some View {
        VStack(spacing: NetraTheme.Spacing.m) {
            SectionTitle(title: "Domains contacted")
            NCard {
                VStack(alignment: .leading, spacing: NetraTheme.Spacing.m) {
                    ForEach(exposure.trackerHosts, id: \.self) { host in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(host)
                                .font(.system(.footnote, design: .monospaced))
                                .textSelection(.enabled)
                            if let what = catalog.explanation(forHost: host) {
                                Text(what)
                                    .font(NetraFont.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }

    private var adviceCard: some View {
        VStack(spacing: NetraTheme.Spacing.m) {
            SectionTitle(title: "What you can do")
            ForEach(exposure.categories, id: \.self) { id in
                if let info = catalog.category(id: id) {
                    NCard {
                        InfoRow(icon: "checkmark.shield.fill", tint: NetraTheme.good,
                                title: info.title, detail: info.advice)
                    }
                }
            }
        }
    }
}
