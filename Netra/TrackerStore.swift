//
//  TrackerStore.swift
//  Netra
//
//  Created by NAYNA SHARMA on 24/08/26.
//


import Foundation

struct TrackerStore {

    private static let key = "netra.detectedTrackers"

    static func saveTrackers(_ trackers: [String]) {
        UserDefaults.standard.set(trackers, forKey: key)
    }

    static func loadTrackers() -> [String] {
        UserDefaults.standard.stringArray(forKey: key) ?? []
    }

    static func clearTrackers() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
