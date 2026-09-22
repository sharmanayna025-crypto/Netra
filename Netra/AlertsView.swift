import SwiftUI
import SwiftData

struct AlertsView: View {

    // MARK: - Stored Credentials

    @Query private var credentials: [CredentialModel]

    // MARK: - Alerts

    private var alerts: [NetraAlert] {
        AlertStore.generateAlerts(from: credentials)
    }

    // MARK: - Alert Score

    private var alertScore: Int {
        AlertStore.calculateAlertScore(from: credentials)
    }

    // MARK: - Alert Status

    private var alertStatus: String {
        AlertStore.alertStatus(from: credentials)
    }

    // MARK: - Body

    var body: some View {

        ScrollView {

            VStack(spacing: 24) {

                // MARK: - Header

                VStack(spacing: 8) {

                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 42))

                    Text("Alerts")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text(
                        "Stay informed about important security events."
                    )
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                }

                // MARK: - Alert Score

                VStack(spacing: 10) {

                    ScoreRing(
                        score: alertScore
                    )

                    Text("Alert Status")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }

                // MARK: - Status

                HStack(spacing: 12) {

                    Image(
                        systemName: alertScore >= 90
                            ? "checkmark.shield.fill"
                            : "exclamationmark.shield.fill"
                    )
                    .font(.title2)

                    VStack(
                        alignment: .leading,
                        spacing: 3
                    ) {

                        Text(alertStatus)
                            .font(.headline)

                        Text(
                            alerts.count == 1
                                ? "1 security event detected."
                                : "\(alerts.count) security events detected."
                        )
                        .font(.caption)
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

                // MARK: - Current Alerts

                VStack(
                    alignment: .leading,
                    spacing: 12
                ) {

                    Text("Current Alerts")
                        .font(.headline)

                    ForEach(alerts) { alert in

                        AlertRow(
                            alert: alert
                        )
                    }
                }

                // MARK: - Monitoring

                VStack(
                    alignment: .leading,
                    spacing: 10
                ) {

                    Label(
                        "Continuous Monitoring",
                        systemImage: "waveform.path.ecg"
                    )
                    .font(.headline)

                    Text(
                        "Netra analyzes your stored security information and highlights important changes here."
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    Text(
                        "More monitoring coming in future updates"
                    )
                    .font(.caption)
                    .fontWeight(.semibold)
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
        .navigationTitle("Alerts")
    }
}

// MARK: - Alert Model

struct NetraAlert: Identifiable {

    let id = UUID()

    let icon: String
    let title: String
    let detail: String
    let severity: AlertSeverity
}

// MARK: - Alert Severity

enum AlertSeverity {

    case safe
    case warning
    case critical
}

// MARK: - Alert Row

struct AlertRow: View {

    let alert: NetraAlert

    private var iconColor: Color {

        switch alert.severity {

        case .safe:
            return .green

        case .warning:
            return .orange

        case .critical:
            return .red
        }
    }

    var body: some View {

        HStack(
            alignment: .top,
            spacing: 14
        ) {

            Image(systemName: alert.icon)
                .font(.title3)
                .foregroundStyle(iconColor)
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

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text(alert.title)
                    .font(.headline)

                Text(alert.detail)
                    .font(.caption)
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

        AlertsView()
    }
}
