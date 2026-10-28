import AppIntents
import SwiftUI
#if os(macOS)
import AppKit
#endif

/// Hands a word from outside the app (Shortcuts, Siri, Spotlight, the Mac Services menu) to the open window.
@MainActor
final class Inbox: ObservableObject {
    static let shared = Inbox()
    @Published var word: String?

    func open(_ text: String) {
        let word = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !word.isEmpty { self.word = word }
    }
}

struct LookUpIntent: AppIntent {
    static let title: LocalizedStringResource = "Look Up in Wordroot"
    static let description = IntentDescription("Opens a word's definitions and where it comes from.")
    static let openAppWhenRun = true

    @Parameter(title: "Word") var word: String

    @MainActor
    func perform() async throws -> some IntentResult {
        Inbox.shared.open(word)
        return .result()
    }
}

struct WordrootShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: LookUpIntent(), phrases: ["Look up a word in \(.applicationName)"],
                    shortTitle: "Look Up", systemImageName: "text.magnifyingglass")
    }
}

#if os(macOS)
/// Services > Look Up in Wordroot, for text selected in any Mac app. The menu item is declared in Info.plist (NSServices).
final class LookUpService: NSObject {
    static let shared = LookUpService()

    @objc func lookUp(_ pboard: NSPasteboard, userData: String?, error: AutoreleasingUnsafeMutablePointer<NSString>?) {
        guard let text = pboard.string(forType: .string) else { return }
        Task { @MainActor in
            Inbox.shared.open(text)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
#endif
