import SwiftUI

/// A word's definitions and its origin, laid out for a 45 mm face. Pure: it only draws what it is given.
struct EntryContent: View {
    let entry: Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(entry.definitions.prefix(3).enumerated()), id: \.offset) { _, group in
                VStack(alignment: .leading, spacing: 4) {
                    Text(group.pos).font(.root(.footnote, .semibold)).foregroundStyle(Theme.accent)
                    ForEach(Array(group.definitions.prefix(3).enumerated()), id: \.offset) { index, text in
                        // A hanging indent, as on the phone: wrapped lines line up with the text.
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(verbatim: "\(index + 1).").monospacedDigit().foregroundStyle(.secondary)
                            Text(text)
                        }
                        .font(.root(.footnote))
                    }
                }
            }
            if !entry.etymology.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Origin").font(.root(.footnote, .semibold)).foregroundStyle(.secondary).padding(.bottom, 6)
                    // The root tree, as on the phone: the word on top, each ancestor a dot further down one line.
                    RailRow(top: true, first: true, last: false) {
                        Text(entry.word).font(.root(.body, .semibold))
                    }
                    ForEach(Array(entry.etymology.enumerated()), id: \.offset) { index, step in
                        RailRow(top: false, first: false, last: index == entry.etymology.count - 1) {
                            VStack(alignment: .leading, spacing: 0) {
                                Text(step.ancestor).font(.root(.body, .semibold))
                                Text("\(step.relation.capitalized) · \(LanguageNames.name(for: step.langCode))")
                                    .font(.root(.caption2)).foregroundStyle(.secondary)
                            }
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// One generation of the tree: a rail with a dot, the content beside it. Rows touch, so the rail is one line.
private struct RailRow<Content: View>: View {
    let top: Bool, first: Bool, last: Bool
    @ViewBuilder let content: Content

    var body: some View {
        HStack(spacing: 8) {
            VStack(spacing: 0) {
                Rectangle().fill(first ? .clear : Theme.accent.opacity(0.45)).frame(width: 2)
                Circle().fill(Theme.accent).frame(width: top ? 10 : 7, height: top ? 10 : 7)
                Rectangle().fill(last ? .clear : Theme.accent.opacity(0.45)).frame(width: 2)
            }
            .frame(width: 10)
            .frame(maxHeight: .infinity)
            content.padding(.vertical, 5).frame(maxWidth: .infinity, alignment: .leading)
        }
        .fixedSize(horizontal: false, vertical: true)   // the rail takes the content's height, so rows meet
    }
}
