//
//  TrackerListView.swift
//  Netra
//
//  All tracking companies seen recently, filterable by what they do.
//

import SwiftUI
import Foundation

struct TrackerListView: View {

    let exposures: [CompanyExposure]

    @State private var selectedCategory: String? = nil

    private var categoryIDs: [String] {
        Array(Set(exposures.flatMap(\.categories))).sorted()
    }

    private var filtered: [CompanyExposure] {
        guard let selectedCategory else { return exposures }
        return exposures.filter { $0.categories.contains(selectedCategory) }
    }

    var body: some View {
        NetraScreen {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: NetraTheme.Spacing.s) {
                    filterChip(title: "All", id: nil)
                    ForEach(categoryIDs, id: \.self) { id in
                        filterChip(title: TrackerCatalog.shared.categoryTitle(id), id: id)
                    }
                }
                .padding(.horizontal, 2)
            }

            VStack(spacing: NetraTheme.Spacing.m) {
                ForEach(filtered) { exposure in
                    NavigationLink {
                        CompanyDetailView(exposure: exposure)
                    } label: {
                        NCard {
                            InfoRow(
                                icon: TrackerCatalog.shared.category(id: exposure.categories.first ?? "")?.symbol ?? "eye.fill",
                                tint: NetraTheme.riskColor(exposure.risk),
                                title: exposure.name,
                                detail: "\(exposure.sites.count) site\(exposure.sites.count == 1 ? "" : "s") · \(exposure.trackerHosts.count) domain\(exposure.trackerHosts.count == 1 ? "" : "s")"
                            ) {
                                StatusPill(text: exposure.risk.title, tint: NetraTheme.riskColor(exposure.risk))
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle("All trackers")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func filterChip(title: String, id: String?) -> some View {
        let isSelected = selectedCategory == id
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) { selectedCategory = id }
        } label: {
            Text(title)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .background(
                    isSelected ? AnyShapeStyle(NetraTheme.brandGradient) : AnyShapeStyle(NetraTheme.card),
                    in: Capsule()
                )
                .overlay(Capsule().strokeBorder(NetraTheme.cardStroke, lineWidth: isSelected ? 0 : 1))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
