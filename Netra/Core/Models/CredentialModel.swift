//
//  CredentialModel.swift
//  Netra
//
//  Metadata about a saved account. The password itself lives only in the
//  Keychain, keyed by `id`.
//

import Foundation
import SwiftData

@Model
final class CredentialModel {

    var id: UUID
    var serviceName: String
    var username: String

    var passwordLength: Int
    var isReused: Bool
    var hasTwoFactorAuthentication: Bool

    /// 0–100 from `PasswordAnalyzer`; -1 for credentials saved before this
    /// field existed (the engine falls back to length for those).
    var strengthScore: Int = -1

    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init(
        id: UUID = UUID(),
        serviceName: String,
        username: String,
        passwordLength: Int,
        strengthScore: Int = -1,
        isReused: Bool = false,
        hasTwoFactorAuthentication: Bool
    ) {
        self.id = id
        self.serviceName = serviceName
        self.username = username
        self.passwordLength = passwordLength
        self.strengthScore = strengthScore
        self.isReused = isReused
        self.hasTwoFactorAuthentication = hasTwoFactorAuthentication
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
