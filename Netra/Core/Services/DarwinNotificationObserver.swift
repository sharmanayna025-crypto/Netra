//
//  DarwinNotificationObserver.swift
//  Netra
//
//  Lets the app react the moment the Safari extension saves a scan.
//

import Foundation

nonisolated final class DarwinNotificationObserver: @unchecked Sendable {

    private let name: String
    private let handler: @Sendable () -> Void

    init(name: String, handler: @escaping @Sendable () -> Void) {
        self.name = name
        self.handler = handler

        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            Unmanaged.passUnretained(self).toOpaque(),
            { _, observer, _, _, _ in
                guard let observer else { return }
                let instance = Unmanaged<DarwinNotificationObserver>
                    .fromOpaque(observer)
                    .takeUnretainedValue()
                DispatchQueue.main.async { instance.handler() }
            },
            name as CFString,
            nil,
            .deliverImmediately
        )
    }

    deinit {
        CFNotificationCenterRemoveObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            Unmanaged.passUnretained(self).toOpaque(),
            CFNotificationName(name as CFString),
            nil
        )
    }
}
