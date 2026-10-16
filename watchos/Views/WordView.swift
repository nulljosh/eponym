import SwiftUI

struct WordView: View {
    let word: String
    var client = LookupClient()

    private enum Phase { case loading, loaded(Entry), failed(LookupError) }
    @State private var phase: Phase = .loading
    @State private var photo: URL?

    var body: some View {
        Group {
            switch phase {
            case .loading:
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            case .loaded(let entry):
                ScrollView { EntryContent(entry: entry).padding(.horizontal, 4) }
            case .failed(let error):
                FailureView(error: error, word: word) { Task { await load() } }
            }
        }
        .navigationTitle(word)
        .containerBackground(for: .navigation) { Backdrop(url: photo).animation(.easeInOut(duration: 0.6), value: photo) }
        .task(id: word) { await load() }
    }

    private func load() async {
        phase = .loading
        photo = nil
        do {
            let entry = try await client.lookup(word)
            phase = .loaded(entry)
            photo = await PhotoFinder().url(for: word, definitions: entry.glossText)
        }
        catch let error as LookupError { phase = .failed(error) }
        catch { phase = .failed(.server) }
    }
}

private struct FailureView: View {
    let error: LookupError
    let word: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Text(message).font(.footnote).multilineTextAlignment(.center)
            if error == .offline || error == .server { Button("Try again", action: retry) }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var message: String {
        switch error {
        case .notFound: "No entry for \u{201C}\(word)\u{201D}."
        case .invalidWord: "That doesn\u{2019}t look like a word."
        case .offline: "You\u{2019}re offline."
        case .server: "Something went wrong."
        }
    }
}
