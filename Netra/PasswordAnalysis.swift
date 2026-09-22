//
//  PasswordAnalysis.swift
//  Netra
//
//  Created by NAYNA SHARMA on 19/08/26.
//


import Foundation

struct PasswordAnalysis {
    let score: Int
    let strength: Strength
    let issues: [String]
    
    enum Strength: String {
        case weak = "Weak"
        case fair = "Fair"
        case strong = "Strong"
        case excellent = "Excellent"
    }
}