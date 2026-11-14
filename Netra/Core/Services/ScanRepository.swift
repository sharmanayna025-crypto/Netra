//
//  ScanRepository.swift
//  Netra
//
//  Observable view of the browsing scans written by the Safari extension.
//  Replaces the old PrivacyStore/TrackerStore, which were read once and never
//  refreshed.
//

import Foundation
import Combine

@MainActor
final class ScanRepository: ObservableObject {

    @Published private(set) var scans: [SiteScan] = []

    private var observer: DarwinNotificationObserver?

    init() {
        ScanStore.shared.pruneExpired()
        reload()

        observer = DarwinNotificationObserver(
            name: SharedConfig.scansUpdatedNotification
        ) { [weak self] in
            Task { @MainActor [weak self] in self?.reload() }
        }
    }

    var hasData: Bool { !scans.isEmpty }

    func reload() {
        scans = ScanStore.shared.load().sorted { $0.date > $1.date }
    }

    func clear() throws {
        try ScanStore.shared.clear()
        reload()
    }
}
