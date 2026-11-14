//
//  ExtensionSetupView.swift
//  Netra
//

import SwiftUI
import UIKit
import Foundation

struct ExtensionSetupView: View {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var scanRepository: ScanRepository

    private let steps: [(title: String, detail: String)] = [
        ("Open Settings", "On iOS 18 and later go to Apps → Safari → Extensions. On iOS 17 go to Safari → Extensions."),
        ("Turn on Netra", "Tap Netra and switch on “Allow Extension”."),
        ("Allow websites", "Choose “All Websites” (or allow each site as you visit it) so Netra can see which trackers a page contacts."),
        ("Browse as usual", "Open any website in Safari. Tap the page menu (aA) → Netra to see its privacy score.")
    ]

    var body: some View {
        NetraScreen {
            NCard {
                VStack(spacing: NetraTheme.Spacing.m) {
                    IconBadge(systemName: "safari.fill", tint: NetraTheme.ok, size: 64)
                    Text("Set up the Safari extension")
                        .font(NetraFont.title)
                        .multilineTextAlignment(.center)
                    Text("Netra's scanner is part of this app. Switch it on once and it works in the background.")
                        .font(NetraFont.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    if scanRepository.hasData {
                        StatusPill(text: "Working — scans received", tint: NetraTheme.good)
                    }
                }
                .frame(maxWidth: .infinity)
            }

            VStack(spacing: NetraTheme.Spacing.m) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    NCard {
                        HStack(alignment: .top, spacing: NetraTheme.Spacing.m) {
                            Text("\(index + 1)")
                                .font(NetraFont.number(16))
                                .foregroundStyle(.white)
                                .frame(width: 32, height: 32)
                                .background(NetraTheme.brandGradient, in: Circle())
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(step.title).font(NetraFont.headline)
                                Text(step.detail)
                                    .font(NetraFont.callout)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Step \(index + 1): \(step.title). \(step.detail)")
                }
            }

            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(PrimaryButtonStyle())

            NCard {
                InfoRow(
                    icon: "lock.fill",
                    tint: NetraTheme.good,
                    title: "Private by design",
                    detail: "Pages are scanned on your device. Netra saves only the site name and which trackers it found — never full addresses, page content or anything you type."
                )
            }
        }
        .navigationTitle("Safari setup")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
    }
}
