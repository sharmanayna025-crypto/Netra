//
//  AlertStore.swift
//  Netra
//

import Foundation
import SwiftData

struct AlertStore {

    // MARK: - Generate Alerts

    static func generateAlerts(
        from credentials: [CredentialModel]
    ) -> [NetraAlert] {

        var results: [NetraAlert] = []

        for credential in credentials {

            let item = credential.credential

            // Weak Password
            if SecurityEngine.hasWeakPassword(item) {

                results.append(
                    NetraAlert(
                        icon: "key.fill",
                        title: "Weak password",
                        detail: "\(credential.serviceName) is using a password that could be stronger.",
                        severity: .warning
                    )
                )
            }

            // Reused Password
            if SecurityEngine.hasReusedPassword(item) {

                results.append(
                    NetraAlert(
                        icon: "arrow.triangle.2.circlepath",
                        title: "Reused password",
                        detail: "\(credential.serviceName) appears to use a reused password.",
                        severity: .warning
                    )
                )
            }

            // Two-Factor Authentication
            if SecurityEngine.needsTwoFactorAuthentication(item) {

                results.append(
                    NetraAlert(
                        icon: "lock.shield.fill",
                        title: "2FA not enabled",
                        detail: "Consider enabling two-factor authentication for \(credential.serviceName).",
                        severity: .warning
                    )
                )
            }
        }

        // No alerts
        if results.isEmpty {

            results.append(
                NetraAlert(
                    icon: "checkmark.shield.fill",
                    title: "No security alerts",
                    detail: "Netra has not detected any immediate credential issues.",
                    severity: .safe
                )
            )
        }

        return results
    }

    // MARK: - Alert Score

    static func calculateAlertScore(
        from credentials: [CredentialModel]
    ) -> Int {

        let alerts = generateAlerts(
            from: credentials
        )

        if alerts.contains(where: {
            $0.severity == .critical
        }) {
            return 40
        }

        if alerts.contains(where: {
            $0.severity == .warning
        }) {
            return 70
        }

        return 96
    }

    // MARK: - Alert Status

    static func alertStatus(
        from credentials: [CredentialModel]
    ) -> String {

        let score = calculateAlertScore(
            from: credentials
        )

        switch score {

        case 90...100:
            return "All Clear"

        case 75..<90:
            return "Good"

        case 50..<75:
            return "Needs Attention"

        default:
            return "Critical"
        }
    }
}
