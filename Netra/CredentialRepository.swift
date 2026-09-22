//
//  CredentialRepository.swift
//  Netra
//
//  Created by NAYNA SHARMA on 19/08/26.
//


import Foundation

final class CredentialRepository {
    
    private let keychain = KeychainManager.shared
    
    // MARK: - Save Password
    
    func savePassword(
        _ password: String,
        for credentialID: String
    ) throws {
        
        try keychain.save(
            password,
            for: credentialID
        )
    }
    
    // MARK: - Get Password
    
    func getPassword(
        for credentialID: String
    ) throws -> String {
        
        try keychain.read(
            for: credentialID
        )
    }
    
    // MARK: - Delete Password
    
    func deletePassword(
        for credentialID: String
    ) throws {
        
        try keychain.delete(
            for: credentialID
        )
    }
}