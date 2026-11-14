//
//  PasswordAnalysis.swift
//  Netra
//

import Foundation

struct PasswordAnalysis {

    enum Strength: String {
        case weak = "Weak"
        case fair = "Fair"
        case strong = "Strong"
        case excellent = "Excellent"
    }

    let score: Int
    let strength: Strength
    let issues: [String]
}
