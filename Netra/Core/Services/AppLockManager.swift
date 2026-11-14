//
//  AppLockManager.swift
//  Netra
//
//  Optional Face ID / Touch ID / passcode lock for the whole app, plus a
//  helper used to protect revealing and copying passwords.
//

import Foundation
import LocalAuthentication
import Combine

enum Biometrics {

    /// True when the device has a passcode or biometrics set up.
    static var isAvailable: Bool {
        var error: NSError?
        return LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
    }

    static func authenticate(reason: String) async -> Bool {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            return false
        }
        do {
            return try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )
        } catch {
            return false
        }
    }
}

@MainActor
final class AppLockManager: ObservableObject {

    private static let key = "netra.appLockEnabled"

    @Published private(set) var isEnabled: Bool
    @Published private(set) var isLocked: Bool

    init() {
        let enabled = UserDefaults.standard.bool(forKey: Self.key)
        isEnabled = enabled
        isLocked = enabled
    }

    /// Turning the lock on or off requires authenticating first.
    func setEnabled(_ enabled: Bool) async -> Bool {
        guard await Biometrics.authenticate(
            reason: enabled ? "Turn on Netra lock" : "Turn off Netra lock"
        ) else { return false }

        UserDefaults.standard.set(enabled, forKey: Self.key)
        isEnabled = enabled
        isLocked = false
        return true
    }

    func lockIfNeeded() {
        if isEnabled { isLocked = true }
    }

    func unlock() async {
        guard isLocked else { return }
        if await Biometrics.authenticate(reason: "Unlock Netra") {
            isLocked = false
        }
    }
}
