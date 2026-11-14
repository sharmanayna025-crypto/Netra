//
//  SharedConfig.swift
//  Shared by the Netra app and the Safari extension.
//

import Foundation

nonisolated enum SharedConfig {

    /// Must match the App Group in both targets' entitlements.
    static let appGroupID = "group.com.nvs.Netra"

    static let scansFileName = "scans.json"

    /// Darwin notification posted by the extension after every saved scan.
    static let scansUpdatedNotification = "com.nvs.Netra.scansUpdated"

    // MARK: - Retention

    static let allowedRetentionDays = [7, 30, 90]
    static let defaultRetentionDays = 30
    private static let retentionKey = "netra.retentionDays"

    static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    /// How long browsing scans are kept. Stored in the App Group so the
    /// extension and the app always agree.
    static var retentionDays: Int {
        get {
            let stored = sharedDefaults?.integer(forKey: retentionKey) ?? 0
            return allowedRetentionDays.contains(stored) ? stored : defaultRetentionDays
        }
        set {
            sharedDefaults?.set(newValue, forKey: retentionKey)
        }
    }
}
