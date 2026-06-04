import SwiftUI

@main
struct WNBAGamesApp: App {
    var body: some Scene {
        MenuBarExtra("WNBA", systemImage: "basketball.fill") {
            MenuBarPopoverView()
        }
        .menuBarExtraStyle(.window)
    }
}
