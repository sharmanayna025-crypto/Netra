import SwiftUI

struct ActivityView: View {

    // MARK: - Activity Data

    @StateObject private var activityStore = ActivityStore.shared

    // MARK: - Body

    var body: some View {

        ScrollView {

            VStack(spacing: 24) {

                // MARK: - Header

                VStack(spacing: 8) {

                    Image(
                        systemName: "clock.arrow.circlepath"
                    )
                    .font(.system(size: 42))

                    Text("Activity")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text(
                        "Review your recent security and privacy activity."
                    )
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                }

                // MARK: - Activity List

                VStack(
                    alignment: .leading,
                    spacing: 12
                ) {

                    Text("Recent Activity")
                        .font(.headline)

                    if activityStore.events.isEmpty {

                        VStack(spacing: 12) {

                            Image(
                                systemName: "clock"
                            )
                            .font(.system(size: 36))
                            .foregroundStyle(.secondary)

                            Text("No Recent Activity")
                                .font(.headline)

                            Text(
                                "Your recent security and privacy events will appear here."
                            )
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                        }
                        .frame(
                            maxWidth: .infinity
                        )
                        .padding(.vertical, 32)
                        .padding(.horizontal)
                        .background(.regularMaterial)
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 16
                            )
                        )

                    } else {

                        ForEach(activityStore.events) { event in
                            ActivityRow(
                                event: event
                            )
                        }
                    }
                }

                // MARK: - Monitoring

                VStack(
                    alignment: .leading,
                    spacing: 10
                ) {

                    Label(
                        "Activity Monitoring",
                        systemImage: "waveform.path.ecg"
                    )
                    .font(.headline)

                    Text(
                        "Netra keeps a local record of important security actions performed in the app."
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
                .padding()
                .background(.regularMaterial)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 16
                    )
                )
            }
            .padding()
        }
        .navigationTitle("Activity")
    }
}

// MARK: - Activity Row

struct ActivityRow: View {

    let event: ActivityEvent

    var body: some View {

        HStack(
            alignment: .top,
            spacing: 14
        ) {

            Image(
                systemName: event.icon
            )
            .font(.title3)
            .frame(
                width: 42,
                height: 42
            )
            .background(.thinMaterial)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 12
                )
            )

            VStack(
                alignment: .leading,
                spacing: 5
            ) {

                Text(event.title)
                    .font(.headline)

                Text(event.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(
                    event.date.formatted(
                        date: .abbreviated,
                        time: .shortened
                    )
                )
                .font(.caption2)
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 16
            )
        )
    }
}

// MARK: - Preview

#Preview {

    NavigationStack {
        ActivityView()
    }
}
