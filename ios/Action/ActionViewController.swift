import SwiftUI
import UniformTypeIdentifiers

/// Look Up in Eponym, from the share sheet of any iPhone app: the selected text opens in the
/// whole app view, inside the sheet. Swiping the sheet down closes it.
/// ponytail: settings, saved and recent words live in the extension's own defaults, not the app's;
/// an App Group would share them if that ever matters.
final class ActionViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        RootSans.register()
        Task {
            // The word goes in before the view does, so the sheet opens on it, not on the word of the day.
            if let text = await selectedText() { Inbox.shared.open(text) }
            let host = UIHostingController(rootView: RootView())
            addChild(host)
            host.view.frame = view.bounds
            host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.addSubview(host.view)
            host.didMove(toParent: self)
        }
    }

    private func selectedText() async -> String? {
        let items = extensionContext?.inputItems as? [NSExtensionItem] ?? []
        for provider in items.flatMap({ $0.attachments ?? [] })
        where provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
            if let text = try? await provider.loadItem(forTypeIdentifier: UTType.plainText.identifier) as? String {
                return text
            }
        }
        return items.first?.attributedContentText?.string
    }
}
