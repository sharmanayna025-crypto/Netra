//
//  PasswordAnalyzer.swift
//  Netra
//
//  Created by NAYNA SHARMA on 19/08/26.
//


import Foundation

struct PasswordAnalyzer {
    
    static func analyze(_ password: String) -> PasswordAnalysis {
        
        var score = 0
        var issues: [String] = []
        
        let length = password.count
        
        // MARK: Length
        
        if length >= 16 {
            score += 40
        } else if length >= 12 {
            score += 30
        } else if length >= 8 {
            score += 20
            issues.append("Password could be longer.")
        } else {
            score += 5
            issues.append("Password is too short.")
        }
        
        
        // MARK: Character Diversity
        
        let hasLowercase = password.range(
            of: "[a-z]",
            options: .regularExpression
        ) != nil
        
        let hasUppercase = password.range(
            of: "[A-Z]",
            options: .regularExpression
        ) != nil
        
        let hasNumber = password.range(
            of: "[0-9]",
            options: .regularExpression
        ) != nil
        
        let hasSpecialCharacter = password.range(
            of: "[^A-Za-z0-9]",
            options: .regularExpression
        ) != nil
        
        
        if hasLowercase {
            score += 10
        } else {
            issues.append("Add lowercase letters.")
        }
        
        if hasUppercase {
            score += 10
        } else {
            issues.append("Add uppercase letters.")
        }
        
        if hasNumber {
            score += 10
        } else {
            issues.append("Add numbers.")
        }
        
        if hasSpecialCharacter {
            score += 10
        } else {
            issues.append("Add a special character.")
        }
        
        
        // MARK: Repeated Characters
        
        if hasRepeatedCharacters(password) {
            score -= 10
            issues.append("Avoid excessive repeated characters.")
        }
        
        
        // MARK: Common Patterns
        
        if containsCommonPattern(password) {
            score -= 20
            issues.append("Avoid common password patterns.")
        }
        
        
        score = min(max(score, 0), 100)
        
        let strength: PasswordAnalysis.Strength
        
        switch score {
        case 90...100:
            strength = .excellent
        case 75..<90:
            strength = .strong
        case 50..<75:
            strength = .fair
        default:
            strength = .weak
        }
        
        return PasswordAnalysis(
            score: score,
            strength: strength,
            issues: issues
        )
    }
    
    
    // MARK: - Repeated Characters
    
    private static func hasRepeatedCharacters(
        _ password: String
    ) -> Bool {
        
        var previousCharacter: Character?
        var repeatCount = 0
        
        for character in password {
            
            if character == previousCharacter {
                repeatCount += 1
                
                if repeatCount >= 2 {
                    return true
                }
            } else {
                repeatCount = 0
            }
            
            previousCharacter = character
        }
        
        return false
    }
    
    
    // MARK: - Common Patterns
    
    private static func containsCommonPattern(
        _ password: String
    ) -> Bool {
        
        let lowercased = password.lowercased()
        
        let commonPatterns = [
            "password",
            "123456",
            "qwerty",
            "admin",
            "letmein",
            "welcome"
        ]
        
        return commonPatterns.contains {
            lowercased.contains($0)
        }
    }
}