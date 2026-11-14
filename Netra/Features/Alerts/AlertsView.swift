//
//  AlertsView.swift
//  Netra
//

import SwiftUI
import Foundation
import SwiftData

struct AlertsView: View {

    @Query private var credentials: [CredentialModel]
    @EnvironmentObject private var scanRepository: ScanRepository

    private var alerts: [NetraAlert] {
        AlertEngine.alerts(credentials: credentials, scans: scanRepository.scans)
    }

    private func count(_ severity: NetraAlert.Severity) -> Int {
        alerts.filter { $0.severity == severity }.count
    }

    var body: some View {
        NetraScreen {
            if alerts.isEmpty {
                EmptyStateView(
                    icon: "checkmark.shield.fill",
                    title: "All clear",
                    message: "Nothing needs your attention right now. Netra keeps watching your credentials and browsing."
                )
            } else {
                NCard {
                    HStack {
                        summaryStat("Critical", count(.critical), NetraTheme.bad)
                        summaryStat("Warnings", count(.warning), NetraTheme.warn)
                        summaryStat("Tips", count(.info), NetraTheme.brand)
                    }
                }

                VStack(spacing: NetraTheme.Spacing.m) {
                    ForEach(alerts) { alert in
                        NCard {
                            InfoRow(
                                icon: alert.icon,
                                tint: NetraTheme.severityColor(alert.severity),
                                title: alert.title,
                                detail: alert.detail
                            ) {
                                StatusPill(
                                    text: alert.severity.title,
                                    tint: NetraTheme.severityColor(alert.severity)
                                )
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Alerts")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func summaryStat(_ title: String, _ value: Int, _ tint: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(value)").font(NetraFont.number(28)).foregroundStyle(value == 0 ? Color.secondary : tint)
            Text(title).font(NetraFont.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}
