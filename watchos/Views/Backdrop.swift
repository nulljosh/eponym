import SwiftUI

/// What sits behind a screen: a soft brand-blue wash, and, when there is a matching photo, the photo
/// under a dark veil so the text on top stays readable.
struct Backdrop: View {
    var url: URL? = nil

    var body: some View {
        ZStack {
            LinearGradient(colors: [Theme.accent.opacity(0.38), .black], startPoint: .top, endPoint: .bottom)
            if let url {
                AsyncImage(url: url) { phase in
                    if let image = phase.image { image.resizable().scaledToFill().overlay(Color.black.opacity(0.58)) }
                }
                .transition(.opacity)
            }
        }
        .ignoresSafeArea()
    }
}
