//
//  NetraApp.swift
//  Netra
//

import SwiftUI
import Foundation
import SwiftData

@main
struct NetraApp: App {

    @StateObject private var scanRepository = ScanRepository()
    @StateObject private var appLock = AppLockManager()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(scanRepository)
                .environmentObject(appLock)
                .tint(NetraTheme.brand)
        }
        .modelContainer(for: [CredentialModel.self, ActivityEventModel.self])
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .background:
                appLock.lockIfNeeded()
            case .active:
                scanRepository.reload()
                if appLock.isLocked {
                    Task { await appLock.unlock() }
                }
            default:
                break
            }
        }
    }
}
