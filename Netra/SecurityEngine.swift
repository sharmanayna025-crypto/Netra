import Foundation

struct CredentialScoreBreakdown {

    let baseScore: Int
    let passwordPenalty: Int
    let reusePenalty: Int
    let twoFactorPenalty: Int

    var finalScore: Int {
        max(
            baseScore
            - passwordPenalty
            - reusePenalty
            - twoFactorPenalty,
            0
        )
    }
}

struct SecurityEngine {

    // MARK: - Overall Security Score

    static func calculateOverallScore(
        categories: [SecurityCategory]
    ) -> Int {

        guard !categories.isEmpty else {
            return 0
        }

        let total = categories.reduce(0) {
            $0 + $1.score
        }

        return total / categories.count
    }

    // MARK: - Credential Score

    static func calculateCredentialScore(
        for credential: Credential
    ) -> Int {

        calculateCredentialBreakdown(
            for: credential
        ).finalScore
    }

    // MARK: - Credential Risk

    static func isCredentialAtRisk(
        _ credential: Credential
    ) -> Bool {

        calculateCredentialScore(
            for: credential
        ) < 50
    }

    // MARK: - Reused Password

    static func hasReusedPassword(
        _ credential: Credential
    ) -> Bool {

        credential.isReused
    }

    // MARK: - Two-Factor Authentication

    static func needsTwoFactorAuthentication(
        _ credential: Credential
    ) -> Bool {

        !credential.hasTwoFactorAuthentication
    }

    // MARK: - Weak Password

    static func hasWeakPassword(
        _ credential: Credential
    ) -> Bool {

        credential.passwordLength < 12
    }

    // MARK: - Credential Breakdown

    static func calculateCredentialBreakdown(
        for credential: Credential
    ) -> CredentialScoreBreakdown {

        let passwordPenalty: Int

        if credential.passwordLength < 8 {

            passwordPenalty = 30

        } else if credential.passwordLength < 12 {

            passwordPenalty = 10

        } else {

            passwordPenalty = 0
        }

        let reusePenalty =
            credential.isReused ? 30 : 0

        let twoFactorPenalty =
            credential.hasTwoFactorAuthentication
                ? 0
                : 15

        return CredentialScoreBreakdown(
            baseScore: 100,
            passwordPenalty: passwordPenalty,
            reusePenalty: reusePenalty,
            twoFactorPenalty: twoFactorPenalty
        )
    }

    // MARK: - Password Reuse Detection

    static func isPasswordReused(
        password: String,
        excluding credentialID: UUID,
        credentials: [CredentialModel]
    ) -> Bool {

        for credential in credentials {

            if credential.id == credentialID {
                continue
            }

            do {

                let storedPassword =
                    try KeychainManager.shared.read(
                        for: credential.id.uuidString
                    )

                if storedPassword == password {
                    return true
                }

            } catch {

                // Ignore credentials whose password
                // cannot currently be read.
                continue
            }
        }

        return false
    }
    // MARK: - Recalculate Password Reuse

    static func recalculatePasswordReuse(
        for credentials: [CredentialModel]
    ) {

        for credential in credentials {

            do {

                let password = try KeychainManager.shared.read(
                    for: credential.id.uuidString
                )

                credential.isReused = isPasswordReused(
                    password: password,
                    excluding: credential.id,
                    credentials: credentials
                )

            } catch {

                // If the password cannot be retrieved,
                // leave the current reuse status unchanged.
                continue
            }
        }
    }
}
