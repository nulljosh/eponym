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
                        Text("\(index + 1). \(text)").font(.root(.footnote))
                    }
                }
            }
            if !entry.etymology.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("ORIGIN").font(.root(.caption2)).foregroundStyle(.secondary)
                    ForEach(Array(entry.etymology.enumerated()), id: \.offset) { _, step in
                        VStack(alignment: .leading, spacing: 0) {
                            Text(step.ancestor).font(.root(.body, .semibold))
                            Text("\(step.relation.capitalized) · \(LanguageNames.name(for: step.langCode))")
                                .font(.root(.caption2)).foregroundStyle(.secondary)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
