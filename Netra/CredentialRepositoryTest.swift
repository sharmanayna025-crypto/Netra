//
//  CredentialRepositoryTest.swift
//  Netra
//
//  Created by NAYNA SHARMA on 19/08/26.
//


import Foundation

struct CredentialRepositoryTest {
    
    static func run() {
        
        let repository = CredentialRepository()
        
        let credentialID = UUID().uuidString
        
        do {
            try repository.savePassword(
                "NetraDummyPassword123!",
                for: credentialID
            )
            
            print("✅ Credential password saved")
            
            let password = try repository.getPassword(
                for: credentialID
            )
            
            print("✅ Credential password retrieved: \(password)")
            
            try repository.deletePassword(
                for: credentialID
            )
            
            print("✅ Credential password deleted")
            
        } catch {
            print("❌ Repository error: \(error)")
        }
    }
}