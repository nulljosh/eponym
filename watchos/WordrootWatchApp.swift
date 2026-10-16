import SwiftUI

@main
struct WordrootWatchApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView().tint(Theme.accent)
        }
    }
}
