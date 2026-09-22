//
//  IdentityStore.swift
//  Netra
//
//  Created by NAYNA SHARMA on 23/08/26.
//


import Foundation

struct IdentityStore {

    // MARK: - Exposure Data

    static let emailExposure = false

    static let phoneExposure = false

    static let breachCount = 0

    // MARK: - Identity Score

    static var identityScore: Int {

        var score = 100

        if emailExposure {
            score -= 20
        }

        if phoneExposure {
            score -= 20
        }

        score -= min(
            breachCount * 15,
            60
        )

        return max(score, 0)
    }

    // MARK: - Identity Detail

    static var identityDetail: String {

        if breachCount > 0 {
            return "\(breachCount) exposure\(breachCount == 1 ? "" : "s")"
        }

        if emailExposure || phoneExposure {
            return "Needs attention"
        }

        return "No issues"
    }
}