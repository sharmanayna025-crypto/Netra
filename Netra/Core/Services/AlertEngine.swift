//
//  AlertEngine.swift
//  Netra
//
//  Builds the alert list from real data only: saved credentials and recent
//  browsing scans. Nothing is invented.
//

import Foundation

enum AlertEngine {

    static func alerts(credentials: [CredentialModel], scans: [SiteScan]) -> [NetraAlert] {
        var alerts: [NetraAlert] = []

        for credential in credentials {
            let weak = SecurityEngine.isWeak(credential)
            let reused = credential.isReused
            let noTwoFactor = !credential.hasTwoFactorAuthentication

            if reused && (weak || noTwoFactor) {
                alerts.append(NetraAlert(
                    icon: "exclamationmark.octagon.fill",
                    title: "\(credential.serviceName): reused password",
                    detail: "This password is used on other accounts and the account has extra weaknesses. Change it first.",
                    severity: .critical,
                    source: .security
                ))
            } else if reused {
                alerts.append(NetraAlert(
                    icon: "arrow.triangle.2.circlepath",
                    title: "\(credential.serviceName): reused password",
                    detail: "Use a unique password for every account.",
                    severity: .warning,
                    source: .security
                ))
            }

            if weak {
                alerts.append(NetraAlert(
                    icon: "key.fill",
                    title: "\(credential.serviceName): weak password",
                    detail: "Use a longer password with letters, numbers and symbols.",
                    severity: .warning,
                    source: .security
                ))
            }

            if noTwoFactor {
                alerts.append(NetraAlert(
                    icon: "lock.shield.fill",
                    title: "\(credential.serviceName): no two-factor authentication",
                    detail: "Turn on two-factor authentication if the service supports it.",
                    severity: .info,
                    source: .security
                ))
            }
        }

        for recommendation in PrivacyEngine.recommendations(from: scans)
        where recommendation.priority == .high {
            alerts.append(NetraAlert(
                icon: recommendation.icon,
                title: recommendation.title,
                detail: recommendation.message,
                severity: .warning,
                source: .privacy
            ))
        }

        return alerts.sorted { $0.severity > $1.severity }
    }
}
