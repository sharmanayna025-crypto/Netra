import SwiftUI

struct TrackerListView: View {

    // MARK: - Tracker Data

    private let trackers = PrivacyStore.detectedTrackers

    @State private var selectedCategory = "All"

    private var filteredTrackers: [PrivacyTracker] {

        if selectedCategory == "All" {
            return trackers
        }

        return trackers.filter {
            $0.category == selectedCategory
        }
    }

    private var categories: [String] {
        [
            "All",
            "Analytics",
            "Advertising"
        ]
    }

    private var analyticsCount: Int {
        trackers.filter {
            $0.category == "Analytics"
        }.count
    }

    private var advertisingCount: Int {
        trackers.filter {
            $0.category == "Advertising"
        }.count
    }

    // MARK: - Body

    var body: some View {

        List {

            // MARK: - Summary

            Section {

                VStack(spacing: 8) {

                    Image(
                        systemName:
                            "eye.trianglebadge.exclamationmark.fill"
                    )
                    .font(.system(size: 36))

                    Text("\(filteredTrackers.count)")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text(
                        selectedCategory == "All"
                            ? "Trackers detected"
                            : "\(selectedCategory) trackers"
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                }
                .frame(
                    maxWidth: .infinity
                )
                .padding(.vertical, 16)

            }

            // MARK: - Category Summary

            Section("Category Summary") {

                HStack(spacing: 12) {

                    TrackerSummaryCard(
                        title: "Analytics",
                        count: analyticsCount,
                        icon: "chart.bar.fill"
                    )

                    TrackerSummaryCard(
                        title: "Advertising",
                        count: advertisingCount,
                        icon: "megaphone.fill"
                    )

                }
                .listRowInsets(
                    EdgeInsets(
                        top: 8,
                        leading: 16,
                        bottom: 8,
                        trailing: 16
                    )
                )

            }

            // MARK: - Filter

            Section("Filter") {

                Picker(
                    "Category",
                    selection: $selectedCategory
                ) {

                    ForEach(
                        categories,
                        id: \.self
                    ) { category in

                        Text(category)
                            .tag(category)

                    }

                }
                .pickerStyle(.segmented)

            }

            // MARK: - Trackers

            Section("Detected Trackers") {

                if filteredTrackers.isEmpty {

                    ContentUnavailableView(
                        "No Trackers",
                        systemImage:
                            "checkmark.shield.fill",
                        description: Text(
                            "No trackers were detected in this category."
                        )
                    )

                } else {

                    ForEach(
                        filteredTrackers
                    ) { tracker in

                        NavigationLink {

                            TrackerDetailView(
                                tracker: tracker
                            )

                        } label: {

                            TrackerRow(
                                tracker: tracker
                            )

                        }

                    }

                }

            }

        }
        .navigationTitle("Trackers")
        .navigationBarTitleDisplayMode(.inline)

    }
}

// MARK: - Tracker Summary Card

struct TrackerSummaryCard: View {

    let title: String
    let count: Int
    let icon: String

    var body: some View {

        VStack(spacing: 8) {

            Image(systemName: icon)
                .font(.title3)

            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

        }
        .frame(
            maxWidth: .infinity
        )
        .padding(.vertical, 12)
        .background(.regularMaterial)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 14
            )
        )

    }
}

// MARK: - Tracker Row

struct TrackerRow: View {

    let tracker: PrivacyTracker

    private var icon: String {
        switch tracker.category {
        case "Advertising":
            return "megaphone.fill"
        case "Analytics":
            return "chart.bar.fill"
        default:
            return "eye.fill"
        }
    }

    private var riskIcon: String {
        switch tracker.riskLevel {
        case "High":
            return "exclamationmark.triangle.fill"
        case "Medium":
            return "exclamationmark.circle.fill"
        default:
            return "checkmark.circle.fill"
        }
    }

    var body: some View {
        HStack(spacing: 14) {

            // Tracker Icon
            Image(systemName: icon)
                .frame(
                    width: 40,
                    height: 40
                )
                .background(.thinMaterial)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 10
                    )
                )

            // Tracker Information
            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text(tracker.name)
                    .font(.headline)

                Text(tracker.domain)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(tracker.category)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Risk Level
            VStack(
                alignment: .trailing,
                spacing: 4
            ) {

                Image(systemName: riskIcon)
                    .font(.caption)

                Text(tracker.riskLevel)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
// MARK: - Preview

#Preview {

    NavigationStack {

        TrackerListView()

    }

}
