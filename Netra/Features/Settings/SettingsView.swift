//
//  SettingsView.swift
//  Netra
//

import SwiftUI
import Foundation
import SwiftData

struct SettingsView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var scanRepository: ScanRepository
    @EnvironmentObject private var appLock: AppLockManager

    @State private var retentionDays = SharedConfig.retentionDays
    @State private var confirmClearHistory = false
    @State private var lockError = false

    private var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    NavigationLink {
                        ExtensionSetupView()
                    } label: {
                        Label("Safari extension setup", systemImage: "safari.fill")
                    }
                    LabeledContent("Scans received", value: "\(scanRepository.scans.count)")
                } header: {
                    Text("Safari extension")
                }

                Section {
                    Picker("Keep browsing history", selection: $retentionDays) {
                        ForEach(SharedConfig.allowedRetentionDays, id: \.self) {
                            Text("\($0) days").tag($0)
                        }
                    }
                    .onChange(of: retentionDays) { _, newValue in
                        SharedConfig.retentionDays = newValue
                        ScanStore.shared.pruneExpired()
                        scanRepository.reload()
                    }

                    Button("Clear browsing history", role: .destructive) {
                        confirmClearHistory = true
                    }
                    .disabled(!scanRepository.hasData)
                } header: {
                    Text("Privacy")
                } footer: {
                    Text("Netra stores the site name and the trackers found — never full addresses or page content. Everything stays on this device. You can also pause saving from the extension's popup.")
                }

                Section {
                    Toggle("Require Face ID or passcode", isOn: Binding(
                        get: { appLock.isEnabled },
                        set: { newValue in
                            Task {
                                if !(await appLock.setEnabled(newValue)) { lockError = true }
                            }
                        }
                    ))
                    .disabled(!Biometrics.isAvailable)
                } header: {
                    Text("Security")
                } footer: {
                    Text(Biometrics.isAvailable
                         ? "Lock Netra whenever it leaves the foreground. Revealing or copying a password always asks for authentication."
                         : "Set a device passcode in iOS Settings to use this.")
                }

                Section("Coming soon") {
                    HStack {
                        Label("Breach monitoring", systemImage: "person.badge.shield.checkmark.fill")
                        Spacer()
                        ComingSoonPill()
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: version)
                    LabeledContent("Tracker database", value: "v\(TrackerCatalog.shared.version) · \(TrackerCatalog.shared.companies.count) companies")
                }
            }
            .scrollContentBackground(.hidden)
            .background(NetraTheme.background.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.fontWeight(.semibold)
                }
            }
            .confirmationDialog("Clear browsing history?", isPresented: $confirmClearHistory, titleVisibility: .visible) {
                Button("Clear history", role: .destructive) {
                    try? scanRepository.clear()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("All saved site scans will be deleted from this device.")
            }
            .alert("Couldn't change lock setting", isPresented: $lockError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Authentication didn't complete.")
            }
        }
    }
}
