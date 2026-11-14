//
//  SecurityEngine.swift
//  Netra
//
//  Scores saved credentials. Strength comes from `PasswordAnalyzer` (stored on
//  each credential when it is saved); length is only a fallback for accounts
//  created before strength was recorded.
//

import Foundation
import CryptoKit

struct CredentialScoreBreakdown {
    let baseScore: Int
    let strengthPenalty: Int
    let reusePenalty: Int
    let twoFactorPenalty: Int

    var finalScore: Int {
        max(baseScore - strengthPenalty - reusePenalty - twoFactorPenalty, 0)
    }
}

enum SecurityEngine {

    // MARK: - Per credential

    static func isWeak(_ credential: CredentialModel) -> Bool {
        if credential.strengthScore >= 0 {
            return credential.strengthScore < 65
        }
        return credential.passwordLength < 12
    }

    static func breakdown(for credential: CredentialModel) -> CredentialScoreBreakdown {
        let strengthPenalty: Int
        if credential.strengthScore >= 0 {
            switch credential.strengthScore {
            case ..<40: strengthPenalty = 30
            case 40..<65: strengthPenalty = 15
            default: strengthPenalty = 0
            }
        } else {
            switch credential.passwordLength {
            case ..<8: strengthPenalty = 30
            case 8..<12: strengthPenalty = 10
            default: strengthPenalty = 0
            }
        }

        return CredentialScoreBreakdown(
            baseScore: 100,
            strengthPenalty: strengthPenalty,
            reusePenalty: credential.isReused ? 30 : 0,
            twoFactorPenalty: credential.hasTwoFactorAuthentication ? 0 : 15
        )
    }

    static func score(for credential: CredentialModel) -> Int {
        breakdown(for: credential).finalScore
    }

    // MARK: - Aggregate

    /// nil when there are no credentials — an empty vault has no score
    /// (the old code reported 0 or an invented value).
    static func averageScore(_ credentials: [CredentialModel]) -> Int? {
        guard !credentials.isEmpty else { return nil }
        let total = credentials.reduce(0) { $0 + score(for: $1) }
        return total / credentials.count
    }

    static func weakCount(_ credentials: [CredentialModel]) -> Int {
        credentials.filter { isWeak($0) }.count
    }

    static func reusedCount(_ credentials: [CredentialModel]) -> Int {
        credentials.filter { $0.isReused }.count
    }

    static func withoutTwoFactorCount(_ credentials: [CredentialModel]) -> Int {
        credentials.filter { !$0.hasTwoFactorAuthentication }.count
    }

    // MARK: - Reuse detection

    /// Reads each password once and groups them by hash, instead of the old
    /// O(n²) approach that re-read the Keychain for every pair.
    static func recalculateReuse(for credentials: [CredentialModel]) {
        var groups: [Data: [CredentialModel]] = [:]

        for credential in credentials {
            guard let password = try? KeychainManager.shared.read(for: credential.id.uuidString) else {
                continue // leave unreadable credentials unchanged
            }
            let digest = Data(SHA256.hash(data: Data(password.utf8)))
            groups[digest, default: []].append(credential)
        }

        for members in groups.values {
            let reused = members.count > 1
            for credential in members where credential.isReused != reused {
                credential.isReused = reused
            }
        }
    }
}
