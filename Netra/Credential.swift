//
//  Credential.swift
//  Netra
//
//  Created by NAYNA SHARMA on 19/08/26.
//

import Foundation

struct Credential: Identifiable {
    
    let id: UUID
    
    let serviceName: String
    let username: String
    
    let passwordLength: Int
    let isReused: Bool
    let hasTwoFactorAuthentication: Bool
    
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
