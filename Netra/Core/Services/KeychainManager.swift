//
//  KeychainManager.swift
//  Netra
//
//  Stores passwords in the Keychain. Items keep the same lookup shape as
//  earlier versions (generic password + account) so existing credentials keep
//  working; they are upgraded in place to "this device only".
//

import Foundation
import Security

enum KeychainError: LocalizedError {
    case invalidData
    case unableToSave(OSStatus)
    case unableToRead(OSStatus)
    case unableToDelete(OSStatus)

    var errorDescription: String? {
        switch self {
        case .invalidData:
            "The password could not be read."
        case .unableToSave(let status):
            "The password could not be saved (error \(status))."
        case .unableToRead(let status):
            "The password could not be loaded (error \(status))."
        case .unableToDelete(let status):
            "The password could not be removed (error \(status))."
        }
    }
}

final class KeychainManager {

    static let shared = KeychainManager()

    private init() {}

    private func identity(for key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
    }

    // MARK: - Save

    /// Updates an existing item in place; adds one if it doesn't exist yet.
    /// (The old delete-then-add approach could lose a password if the add failed.)
    func save(_ value: String, for key: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.invalidData
        }

        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let updateStatus = SecItemUpdate(
            identity(for: key) as CFDictionary,
            attributes as CFDictionary
        )

        if updateStatus == errSecSuccess { return }

        guard updateStatus == errSecItemNotFound else {
            throw KeychainError.unableToSave(updateStatus)
        }

        var newItem = identity(for: key)
        newItem.merge(attributes) { _, new in new }

        let addStatus = SecItemAdd(newItem as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw KeychainError.unableToSave(addStatus)
        }
    }

    // MARK: - Read

    func read(for key: String) throws -> String {
        var query = identity(for: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            throw KeychainError.unableToRead(status)
        }
        guard let data = result as? Data,
              let value = String(data: data, encoding: .utf8)
        else {
            throw KeychainError.invalidData
        }
        return value
    }

    // MARK: - Delete

    func delete(for key: String) throws {
        let status = SecItemDelete(identity(for: key) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unableToDelete(status)
        }
    }
}
