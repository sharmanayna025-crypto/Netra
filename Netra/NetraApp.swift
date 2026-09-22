//
//  NetraApp.swift
//  Netra
//
//  Created by NAYNA SHARMA on 18/08/26.
//

import SwiftUI
import SwiftData

@main
struct NetraApp: App {
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: CredentialModel.self)
    }
}
