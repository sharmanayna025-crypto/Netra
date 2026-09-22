//
//  PasswordAnalyzerTest.swift
//  Netra
//
//  Created by NAYNA SHARMA on 19/08/26.
//


import Foundation

struct PasswordAnalyzerTest {
    
    static func run() {
        
        let passwords = [
            "123456",
            "password123",
            "NetraDemo123",
            "NetraDemo123!Secure",
            "aaaaaaa"
        ]
        
        for password in passwords {
            
            let result = PasswordAnalyzer.analyze(password)
            
            print("Password: \(password)")
            print("Score: \(result.score)")
            print("Strength: \(result.strength.rawValue)")
            print("Issues: \(result.issues)")
            print("--------------------")
        }
    }
}