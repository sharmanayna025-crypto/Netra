import SwiftUI

struct ContentView: View {

    var body: some View {

        TabView {

            // MARK: - Home

            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label(
                    "Home",
                    systemImage: "house.fill"
                )
            }

            // MARK: - Privacy

            NavigationStack {
                PrivacyView()
            }
            .tabItem {
                Label(
                    "Privacy",
                    systemImage: "eye.fill"
                )
            }

            // MARK: - Security

            NavigationStack {
                SecurityView()
            }
            .tabItem {
                Label(
                    "Security",
                    systemImage: "shield.fill"
                )
            }

            // MARK: - Activity

            NavigationStack {
                ActivityView()
            }
            .tabItem {
                Label(
                    "Activity",
                    systemImage: "clock.arrow.circlepath"
                )
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
