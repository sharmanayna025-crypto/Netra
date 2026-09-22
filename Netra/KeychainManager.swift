//
//  KeychainManager.swift
//  Netra
//
//  Created by NAYNA SHARMA on 19/08/26.
//


import Foundation
import Security

final class KeychainManager {
    
    static let shared = KeychainManager()
    
    private init() {}
    
    // MARK: - Save
    
    func save(
        _ value: String,
        for key: String
    ) throws {
        
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.invalidData
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        // Remove an existing value first.
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(
            query as CFDictionary,
            nil
        )
        
        guard status == errSecSuccess else {
            throw KeychainError.unableToSave(status)
        }
    }
    
    // MARK: - Read
    
    func read(
        for key: String
    ) throws -> String {
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        
        let status = SecItemCopyMatching(
            query as CFDictionary,
            &result
        )
        
        guard status == errSecSuccess else {
            throw KeychainError.unableToRead(status)
        }
        
        guard
            let data = result as? Data,
            let value = String(data: data, encoding: .utf8)
        else {
            throw KeychainError.invalidData
        }
        
        return value
    }
    
    // MARK: - Delete
    
    func delete(
        for key: String
    ) throws {
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(
            query as CFDictionary
        )
        
        guard status == errSecSuccess ||
              status == errSecItemNotFound else {
            throw KeychainError.unableToDelete(status)
        }
    }
}


// MARK: - Keychain Errors

enum KeychainError: Error {
    case invalidData
    case unableToSave(OSStatus)
    case unableToRead(OSStatus)
    case unableToDelete(OSStatus)
}
