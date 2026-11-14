//
//  ScanStore.swift
//  Shared by the Netra app and the Safari extension.
//
//  A small JSON file in the App Group container. Access is coordinated with
//  NSFileCoordinator so the extension process and the app never corrupt it,
//  and a Darwin notification tells the app when new data has arrived.
//

import Foundation

nonisolated enum ScanStoreError: Error {
    case appGroupUnavailable
    case coordinationFailed
}

nonisolated final class ScanStore: @unchecked Sendable {

    static let shared = ScanStore()

    private let maxRecords = 1_000
    /// Repeat scans of the same site within this window replace each other.
    private let mergeWindow: TimeInterval = 30 * 60

    private var fileURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: SharedConfig.appGroupID)?
            .appendingPathComponent(SharedConfig.scansFileName)
    }

    // MARK: - Read

    func load() -> [SiteScan] {
        guard let url = fileURL else { return [] }
        let scans = (try? coordinate(url, writing: false) { Self.read($0) }) ?? []
        let cutoff = Self.cutoffDate()
        return scans.filter { $0.date >= cutoff }
    }

    // MARK: - Write

    func record(_ scan: SiteScan) throws {
        guard let url = fileURL else { throw ScanStoreError.appGroupUnavailable }

        try coordinate(url, writing: true) { fileURL in
            let cutoff = Self.cutoffDate()
            var scans = Self.read(fileURL).filter { $0.date >= cutoff }

            if let index = scans.lastIndex(where: {
                $0.pageHost == scan.pageHost
                    && scan.date.timeIntervalSince($0.date) < self.mergeWindow
            }) {
                var replacement = scan
                replacement.id = scans[index].id
                scans[index] = replacement
            } else {
                scans.append(scan)
            }

            if scans.count > self.maxRecords {
                scans.removeFirst(scans.count - self.maxRecords)
            }
            try Self.write(scans, to: fileURL)
        }
        Self.postUpdateNotification()
    }

    /// Deletes all stored browsing scans.
    func clear() throws {
        guard let url = fileURL else { throw ScanStoreError.appGroupUnavailable }
        try coordinate(url, writing: true) { try Self.write([], to: $0) }
        Self.postUpdateNotification()
    }

    /// Removes scans older than the retention window.
    func pruneExpired() {
        guard let url = fileURL else { return }
        _ = try? coordinate(url, writing: true) { fileURL in
            let cutoff = Self.cutoffDate()
            let all = Self.read(fileURL)
            let kept = all.filter { $0.date >= cutoff }
            if kept.count != all.count { try Self.write(kept, to: fileURL) }
        }
    }

    // MARK: - Helpers

    private static func cutoffDate() -> Date {
        Date().addingTimeInterval(-Double(SharedConfig.retentionDays) * 86_400)
    }

    private static func read(_ url: URL) -> [SiteScan] {
        guard let data = try? Data(contentsOf: url), !data.isEmpty else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([SiteScan].self, from: data)) ?? []
    }

    private static func write(_ scans: [SiteScan], to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(scans)
        try data.write(
            to: url,
            options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication]
        )
    }

    private func coordinate<T>(
        _ url: URL,
        writing: Bool,
        _ body: @escaping (URL) throws -> T
    ) throws -> T {
        let coordinator = NSFileCoordinator(filePresenter: nil)
        var coordinationError: NSError?
        var outcome: Result<T, Error>?

        let accessor: (URL) -> Void = { accessURL in
            outcome = Result { try body(accessURL) }
        }

        if writing {
            coordinator.coordinate(
                writingItemAt: url,
                options: [],
                error: &coordinationError,
                byAccessor: accessor
            )
        } else {
            coordinator.coordinate(
                readingItemAt: url,
                options: [],
                error: &coordinationError,
                byAccessor: accessor
            )
        }

        if let coordinationError { throw coordinationError }
        guard let outcome else { throw ScanStoreError.coordinationFailed }
        return try outcome.get()
    }

    private static func postUpdateNotification() {
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(SharedConfig.scansUpdatedNotification as CFString),
            nil,
            nil,
            true
        )
    }
}
