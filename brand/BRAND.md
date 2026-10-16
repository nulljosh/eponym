# Wordroot brand kit and design system

One idea: a word is the top of a tree, and its roots are underneath. Everything here serves that. Plain, quiet, Apple-clean, built with the care of something you hold, and the word is always the biggest thing on the screen.

## The mark
A dot that splits into two branches that end in two dots. It reads as a word and its ancestors.

- `icon.svg`: the app icon. White mark on a blue gradient tile.
- `mark.svg`: the mark alone, `currentColor`, for anywhere you need it on your own background.
- The source of truth for the app icon is `Wordroot.icon` (Icon Composer). The SVGs are flat copies.

**Use it like this**
- Clear space on every side equal to the width of one end dot.
- Smallest size: 16 px for the mark, 29 px for the full tile.
- White on the blue gradient, or `currentColor` on a flat surface. Nothing else.

**Don't**
- No text in the icon.
- No brown, beige or cream. No purple, no teal.
- No extra branches, no outlines, no shadows, no stretching.
- Don't round the tile yourself. The App Store masks the iOS icon; the Mac icon ships with its own shape.

## Color
Defined in `tokens.css`. Light first, dark follows the system.

| Role | Light | Dark |
|---|---|---|
| Accent | `#0a62d8` | `#0a62d8` |
| Icon gradient | `#4da3ff` to `#0a5fd6` | same |
| Link | `#0a58c2` | `#5aa9ff` |
| Background | `#ffffff` | `#111111` |
| Surface (cards, inputs) | `#f5f5f5` | `#1a1a1a` |
| Text | `#252a49` | `#e8e8f0` |
| Secondary text | `#666666` | 60% of text |
| Border | `#e8e8e8` | 10% of text |

The ink is a navy, never pure black. Blue is the only accent and appears on actions and links, nowhere else. Each word also gets one flat tint behind it, a single hue picked from the word. When a photo of the word exists it replaces the tint. No gradients on the page, only in the icon.

## Type
**Wordroot Sans**, our own typeface. A rounded, single-weight-stroke, proportionally spaced sans-serif. Two weights, Regular and Bold, drawn from one skeleton so they stay one family. Nothing to license, about 9 KB a weight.

- Files: `fonts/WordrootSans-Regular` and `-Bold`, as `.ttf` and `.woff2`. The source is `font/build.py`, a script that draws every glyph from a few centerline strokes. Run it to rebuild.
- Covers the Latin alphabet, digits, punctuation, and the accents and macrons the etymology text uses (ā ē ī ō ū, grave, acute, circumflex, tilde, diaeresis, ring, caron, cedilla).
- Everything else, Cyrillic, Arabic, Japanese and so on, falls through to the system font behind it in the stack: San Francisco, then Segoe UI.
- Words and headings in Bold with tight tracking. Definitions in Regular. Labels small, uppercase, in the secondary text color. No monospace anywhere in the interface.

## Shape and space
- Inputs 10 px, cards 12 px, small controls 8 px. One border, 1 px, in the border color.
- Generous space at the top of the page, tight inside a card. The reading column is 640 px.
- One column. The result is a card; the roots sit inside it, one per line: the ancestor, then `relation · language` beneath.

## Motion
The background tint eases over a second when the word changes. The photo fades in over 0.6 seconds. Nothing else moves. Reduced motion turns both off.

## Voice
Short sentences, plain words, no hedging. Say what the thing does for a person.

- Yes: "Where did that word come from?" "A dictionary with the roots showing."
- No: "leverage", "seamlessly", "powerful", exclamation marks, emoji, em dashes.

Never write a sentence by joining translated pieces. Word order differs across the twelve interface languages and Arabic runs right to left.

## Platforms
| | Today |
|---|---|
| Web and landing | `tokens.css` values, used directly |
| iOS and macOS | System fonts and the system accent. The icon comes from `Wordroot.icon`. The background tint is a SwiftUI color from the word's hue |
| Android and desktop | Not aligned yet. The Compose app still uses the Material default scheme. Set `primary` to `#0a62d8` to bring it in line |
| Docs | `architecture.svg` uses the accent and surface colors above on white |

## Changing it
Change `tokens.css` first, then the Swift and Kotlin values to match. Never invent a new color in a single screen.
