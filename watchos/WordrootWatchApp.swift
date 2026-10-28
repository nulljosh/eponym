import SwiftUI

@main
struct WordrootWatchApp: App {
    init() { RootSans.register() }

    var body: some Scene {
        WindowGroup {
            HomeView().font(.root(.body)).tint(Theme.accent)
        }
    }
}
