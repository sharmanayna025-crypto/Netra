//
//  PasswordAnalyzer.swift
//  Netra
//
//  Scores a password 0–100 and explains how to improve it. Runs entirely on
//  device; passwords are never sent anywhere.
//

import Foundation

enum PasswordAnalyzer {

    private static let commonPasswords = [
        "password", "123456", "12345678", "qwerty", "admin", "letmein",
        "welcome", "iloveyou", "abc123", "111111", "monkey", "dragon",
        "football", "login", "passw0rd", "changeme"
    ]

    private static let sequences = [
        "abcdefghijklmnopqrstuvwxyz",
        "zyxwvutsrqponmlkjihgfedcba",
        "0123456789",
        "9876543210",
        "qwertyuiop",
        "asdfghjkl",
        "zxcvbnm"
    ]

    static func analyze(_ password: String) -> PasswordAnalysis {
        var score = 0
        var issues: [String] = []
        let length = password.count

        // Length (up to 50 points)
        switch length {
        case 16...:
            score += 50
        case 12..<16:
            score += 35
        case 8..<12:
            score += 20
            issues.append("Use at least 12 characters.")
        default:
            score += 5
            issues.append("This password is too short.")
        }

        // Character variety (10 points each, up to 40) in a single pass.
        var hasLower = false, hasUpper = false, hasDigit = false, hasSymbol = false
        for scalar in password.unicodeScalars {
            if CharacterSet.lowercaseLetters.contains(scalar) {
                hasLower = true
            } else if CharacterSet.uppercaseLetters.contains(scalar) {
                hasUpper = true
            } else if CharacterSet.decimalDigits.contains(scalar) {
                hasDigit = true
            } else {
                hasSymbol = true
            }
        }
        if hasLower { score += 10 } else { issues.append("Add lowercase letters.") }
        if hasUpper { score += 10 } else { issues.append("Add uppercase letters.") }
        if hasDigit { score += 10 } else { issues.append("Add numbers.") }
        if hasSymbol { score += 10 } else { issues.append("Add a symbol.") }

        // Penalties
        if hasRepeatedRun(password) {
            score -= 10
            issues.append("Avoid repeating the same character.")
        }
        if containsCommonPassword(password) {
            score -= 25
            issues.append("Avoid common words like “password”.")
        }
        if containsSequence(password) {
            score -= 10
            issues.append("Avoid sequences like “1234” or “abcd”.")
        }

        score = min(max(score, 0), 100)

        let strength: PasswordAnalysis.Strength
        switch score {
        case 90...: strength = .excellent
        case 75..<90: strength = .strong
        case 50..<75: strength = .fair
        default: strength = .weak
        }

        return PasswordAnalysis(score: score, strength: strength, issues: issues)
    }

    // MARK: - Checks

    /// Three or more identical characters in a row.
    private static func hasRepeatedRun(_ password: String) -> Bool {
        var previous: Character?
        var run = 1
        for character in password {
            if character == previous {
                run += 1
                if run >= 3 { return true }
            } else {
                run = 1
            }
            previous = character
        }
        return false
    }

    private static func containsCommonPassword(_ password: String) -> Bool {
        let lowered = password.lowercased()
        return commonPasswords.contains { lowered.contains($0) }
    }

    /// Four or more consecutive characters from a keyboard or alphabet run.
    private static func containsSequence(_ password: String) -> Bool {
        let lowered = password.lowercased()
        guard lowered.count >= 4 else { return false }
        let chars = Array(lowered)
        for start in 0...(chars.count - 4) {
            let window = String(chars[start..<start + 4])
            if sequences.contains(where: { $0.contains(window) }) { return true }
        }
        return false
    }
}

// MARK: - Generator

enum PasswordGenerator {

    private static let lower = Array("abcdefghijkmnopqrstuvwxyz")
    private static let upper = Array("ABCDEFGHJKLMNPQRSTUVWXYZ")
    private static let digits = Array("23456789")
    private static let symbols = Array("!@#$%^&*-_=+")

    /// Random password that always contains every character class.
    ///
    /// Built by construction (one of each class, the rest from the full set,
    /// then shuffled) so it always finishes immediately. The previous version
    /// looped until the analyzer scored it 90+, which was impossible, so it
    /// froze the app. `SystemRandomNumberGenerator` is cryptographically secure.
    static func generate(length: Int = 20) -> String {
        let length = max(length, 12)
        let all = lower + upper + digits + symbols

        var best = ""
        // Bounded retries: only to avoid a rare repeated run or sequence.
        for _ in 0..<20 {
            var characters: [Character] = [
                lower.randomElement()!,
                upper.randomElement()!,
                digits.randomElement()!,
                symbols.randomElement()!
            ]
            while characters.count < length {
                characters.append(all.randomElement()!)
            }
            characters.shuffle()

            best = String(characters)
            if PasswordAnalyzer.analyze(best).score >= 90 { return best }
        }
        return best
    }
}
