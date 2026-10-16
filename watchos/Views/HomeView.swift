import SwiftUI

struct HomeView: View {
    @State private var query = ""
    @State private var path: [String] = []
    @State private var recents = RecentsStore()

    var body: some View {
        NavigationStack(path: $path) {
            List {
                TextField("Look up a word", text: $query)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .onSubmit(open)
                Section("Word of the day") {
                    NavigationLink(value: WordOfTheDay.word()) {
                        Text(WordOfTheDay.word()).font(.title3.bold())
                    }
                }
                if !recents.words.isEmpty {
                    Section("Recent") {
                        ForEach(recents.words, id: \.self) { word in
                            NavigationLink(value: word) { Text(word) }
                        }
                    }
                }
            }
            .navigationTitle("Wordroot")
            .containerBackground(for: .navigation) { Backdrop() }
            .onAppear {
                // `-openWord volcano` on launch opens that word, so the simulator can be checked without tapping.
                if path.isEmpty, let word = LookupClient.clean(UserDefaults.standard.string(forKey: "openWord") ?? "") { path.append(word) }
            }
            .navigationDestination(for: String.self) { word in
                WordView(word: word).onAppear { recents.add(word) }
            }
        }
    }

    private func open() {
        guard let word = LookupClient.clean(query) else { return }
        query = ""
        path.append(word)
    }
}
