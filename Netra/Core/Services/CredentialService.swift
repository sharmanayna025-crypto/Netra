//
//  CredentialService.swift
//  Netra
//
//  The one place credentials are created, changed and removed. Previously the
//  add, edit, detail and list screens each had their own copy of this logic.
//

import Foundation
import SwiftData

@MainActor
enum CredentialService {

    static func add(
        serviceName: String,
        username: String,
        password: String,
        hasTwoFactor: Bool,
        existing: [CredentialModel],
        context: ModelContext
    ) throws {
        let analysis = PasswordAnalyzer.analyze(password)
        let credential = CredentialModel(
            serviceName: serviceName.trimmed,
            username: username.trimmed,
            passwordLength: password.count,
            strengthScore: analysis.score,
            hasTwoFactorAuthentication: hasTwoFactor
        )

        // Keychain first: if it fails nothing has been inserted yet.
        try KeychainManager.shared.save(password, for: credential.id.uuidString)

        context.insert(credential)
        SecurityEngine.recalculateReuse(for: existing + [credential])

        do {
            try context.save()
        } catch {
            // Roll back so no orphaned Keychain item is left behind.
            context.delete(credential)
            try? KeychainManager.shared.delete(for: credential.id.uuidString)
            throw error
        }

        ActivityLog.record(
            in: context,
            icon: "key.fill",
            title: "Credential added",
            detail: "\(credential.serviceName) was added to Netra."
        )
    }

    static func update(
        _ credential: CredentialModel,
        serviceName: String,
        username: String,
        newPassword: String?,
        hasTwoFactor: Bool,
        all: [CredentialModel],
        context: ModelContext
    ) throws {
        if let newPassword, !newPassword.isEmpty {
            try KeychainManager.shared.save(newPassword, for: credential.id.uuidString)
            credential.passwordLength = newPassword.count
            credential.strengthScore = PasswordAnalyzer.analyze(newPassword).score
        }

        credential.serviceName = serviceName.trimmed
        credential.username = username.trimmed
        credential.hasTwoFactorAuthentication = hasTwoFactor
        credential.updatedAt = Date()

        SecurityEngine.recalculateReuse(for: all)
        try context.save()

        ActivityLog.record(
            in: context,
            icon: "pencil",
            title: "Credential updated",
            detail: "\(credential.serviceName) was updated."
        )
    }

    static func delete(
        _ credential: CredentialModel,
        all: [CredentialModel],
        context: ModelContext
    ) throws {
        let name = credential.serviceName
        try KeychainManager.shared.delete(for: credential.id.uuidString)

        context.delete(credential)
        SecurityEngine.recalculateReuse(for: all.filter { $0.id != credential.id })
        try context.save()

        ActivityLog.record(
            in: context,
            icon: "trash.fill",
            title: "Credential removed",
            detail: "\(name) and its saved password were deleted."
        )
    }

    static func password(for credential: CredentialModel) throws -> String {
        try KeychainManager.shared.read(for: credential.id.uuidString)
    }
}

extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
