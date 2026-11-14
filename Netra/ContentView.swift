//
//  ContentView.swift
//  Netra
//

import SwiftUI
import Foundation

enum AppTab: Hashable {
    case home, privacy, security, activity
}

struct ContentView: View {

    @EnvironmentObject private var appLock: AppLockManager
    @Environment(\.scenePhase) private var scenePhase
    @State private var selection: AppTab = .home

    var body: some View {
        ZStack {
            TabView(selection: $selection) {
                NavigationStack {
                    HomeView(selectTab: { selection = $0 })
                }
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(AppTab.home)

                NavigationStack {
                    PrivacyView()
                }
                .tabItem { Label("Privacy", systemImage: "eye.fill") }
                .tag(AppTab.privacy)

                NavigationStack {
                    SecurityView()
                }
                .tabItem { Label("Security", systemImage: "key.fill") }
                .tag(AppTab.security)

                NavigationStack {
                    ActivityView()
                }
                .tabItem { Label("Activity", systemImage: "clock.fill") }
                .tag(AppTab.activity)
            }

            // Hide content in the app switcher and until the user unlocks.
            if appLock.isEnabled && (appLock.isLocked || scenePhase != .active) {
                LockScreen()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: appLock.isLocked)
    }
}

struct LockScreen: View {

    @EnvironmentObject private var appLock: AppLockManager

    var body: some View {
        ZStack {
            NetraTheme.brandGradient.ignoresSafeArea()

            VStack(spacing: NetraTheme.Spacing.xl) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.white)
                    .accessibilityHidden(true)

                Text("Netra is locked")
                    .font(NetraFont.title)
                    .foregroundStyle(.white)

                Button("Unlock") {
                    Task { await appLock.unlock() }
                }
                .buttonStyle(SecondaryButtonStyle(onGradient: true))
            }
        }
    }
}
