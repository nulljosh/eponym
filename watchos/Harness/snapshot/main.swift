import SwiftUI
import AppKit

// Draws the word screen the way the watch would, at 45 mm (184 x 224 points), to a PNG.
@MainActor func render(_ entry: Entry, name: String, height: CGFloat?) {
    let content = EntryContent(entry: entry).padding(8).frame(width: 184, alignment: .leading)
    let framed = Group {
        if let height { content.frame(height: height, alignment: .top).clipped() } else { content }
    }
    .background(Color.black).environment(\.colorScheme, .dark)
    let renderer = ImageRenderer(content: framed)
    renderer.scale = 3
    guard let image = renderer.nsImage, let tiff = image.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else { print("render failed"); return }
    try? png.write(to: URL(fileURLWithPath: CommandLine.arguments[1] + "/" + name + ".png"))
}

let volcano = Entry(word: "volcano", definitions: [
    .init(pos: "Noun", definitions: ["A vent or fissure on the surface of a planet with a magma chamber attached to the mantle.", "A kind of firework producing an upward plume of sparks."]),
    .init(pos: "Verb", definitions: ["To erupt; to burst forth."]),
], etymology: [
    .init(relation: "borrowed", langCode: "it", ancestor: "vulcano"),
    .init(relation: "derived", langCode: "la", ancestor: "Vulcānus"),
])
let mother = Entry(word: "water", definitions: [.init(pos: "Noun", definitions: ["A substance (of molecular formula H2O) found at room temperature and pressure as a clear liquid."])], etymology: [
    .init(relation: "inherited", langCode: "enm", ancestor: "water"), .init(relation: "inherited", langCode: "ang", ancestor: "wæter"),
    .init(relation: "inherited", langCode: "gmw-pro", ancestor: "*watar"), .init(relation: "inherited", langCode: "ine-pro", ancestor: "*wódr̥"),
])
render(volcano, name: "watch-volcano", height: 224)
render(mother, name: "watch-water-full", height: nil)
print("rendered")
