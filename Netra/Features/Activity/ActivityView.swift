//
//  ActivityView.swift
//  Netra
//
//  A single timeline of security events (saved in the app) and browsing scans
//  (written by the Safari extension).
//

import SwiftUI
import Foundation
import SwiftData

struct ActivityView: View {

    private enum Filter: String, CaseIterable, Identifiable {
        case all = "All"
        case security = "Security"
        case browsing = "Browsing"
        var id: String { rawValue }
    }

    private struct Item: Identifiable {
        let id: String
        let icon: String
        let tint: Color
        let title: String
        let detail: String
        let date: Date
        let isBrowsing: Bool
    }

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ActivityEventModel.date, order: .reverse) private var events: [ActivityEventModel]
    @EnvironmentObject private var scanRepository: ScanRepository

    @State private var filter: Filter = .all
    @State private var confirmClear = false

    private var items: [Item] {
        var result: [Item] = events.map {
            Item(id: $0.id.uuidString, icon: $0.icon, tint: NetraTheme.violet,
                 title: $0.title, detail: $0.detail, date: $0.date, isBrowsing: false)
        }
        result += scanRepository.scans.prefix(100).map { scan in
            Item(
                id: scan.id.uuidString,
                icon: "globe",
                tint: NetraTheme.scoreColor(scan.score),
                title: scan.pageHost,
                detail: "Privacy score \(scan.score) · \(scan.trackers.count) tracker\(scan.trackers.count == 1 ? "" : "s")",
                date: scan.date,
                isBrowsing: true
            )
        }

        switch filter {
        case .all: break
        case .security: result = result.filter { !$0.isBrowsing }
        case .browsing: result = result.filter { $0.isBrowsing }
        }
        return result.sorted { $0.date > $1.date }
    }

    var body: some View {
        NetraScreen {
            Picker("Filter", selection: $filter) {
                ForEach(Filter.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)

            if items.isEmpty {
                EmptyStateView(
                    icon: "clock.fill",
                    title: "Nothing here yet",
                    message: "Security changes and the sites you browse with the Safari extension will show up here."
                )
            } else {
                VStack(spacing: NetraTheme.Spacing.m) {
                    ForEach(items) { item in
                        NCard {
                            InfoRow(icon: item.icon, tint: item.tint, title: item.title, detail: item.detail) {
                                Text(item.date.relativeDescription)
                                    .font(NetraFont.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Activity")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Clear security activity", role: .destructive) { confirmClear = true }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .disabled(events.isEmpty)
                .accessibilityLabel("More options")
            }
        }
        .confirmationDialog("Clear security activity?", isPresented: $confirmClear, titleVisibility: .visible) {
            Button("Clear", role: .destructive) {
                events.forEach { modelContext.delete($0) }
                try? modelContext.save()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Browsing history is managed in Settings.")
        }
    }
}
