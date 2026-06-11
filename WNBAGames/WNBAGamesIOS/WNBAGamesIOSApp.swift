import SwiftUI

@main
struct WNBAGamesIOSApp: App {
    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
    }
}

struct RootTabView: View {
    var body: some View {
        TabView {
            GamesListView()
                .tabItem { Label("Games", systemImage: "sportscourt") }
            StandingsView()
                .tabItem { Label("Standings", systemImage: "list.number") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
    }
}
