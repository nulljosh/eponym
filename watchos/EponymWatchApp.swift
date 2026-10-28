import SwiftUI

@main
struct EponymWatchApp: App {
    init() { RootSans.register() }

    var body: some Scene {
        WindowGroup {
            HomeView().font(.root(.body)).tint(Theme.accent)
        }
    }
}
