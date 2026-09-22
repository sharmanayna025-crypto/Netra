//
//  CredentialModel.swift
//  Netra
//
//  Created by NAYNA SHARMA on 19/08/26.
//


import Foundation
import SwiftData

@Model
final class CredentialModel {
    
    var id: UUID
    var serviceName: String
    var username: String
    
    var passwordLength: Int
    var isReused: Bool
    var hasTwoFactorAuthentication: Bool
    
    init(
        id: UUID = UUID(),
        serviceName: String,
        username: String,
        passwordLength: Int,
        isReused: Bool,
        hasTwoFactorAuthentication: Bool
    ) {
        self.id = id
        self.serviceName = serviceName
        self.username = username
        self.passwordLength = passwordLength
        self.isReused = isReused
        self.hasTwoFactorAuthentication = hasTwoFactorAuthentication
    }
}
extension CredentialModel {
    
    var credential: Credential {
        Credential(
            id: id,
            serviceName: serviceName,
            username: username,
            passwordLength: passwordLength,
            isReused: isReused,
            hasTwoFactorAuthentication: hasTwoFactorAuthentication
        )
    }
}
