# Wordroot brand kit and design system

One idea: a word is the top of a tree, and its roots are underneath. Everything here serves that. Plain, quiet, Apple-clean, and the word is always the biggest thing on the screen.

## The mark
A dot that splits into two branches that end in two dots. It reads as a word and its ancestors. Refreshed 2026-10-28: thicker branches and bigger dots, so it holds at 16 px.

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
Root Sans, our own face. It is Inter 4.1 renamed (SIL Open Font License, the license ships in `fonts/OFL.txt`), the open typeface closest to San Francisco: proportionally spaced, sans serif, built for screens. Full Latin, Greek and Cyrillic, because roots arrive in all three. Four weights: Regular, Medium, Semibold, Bold. `scripts/gen_font.py` builds it and `--check` proves it.

- Web stack: `"Root Sans", -apple-system, BlinkMacSystemFont, "SF Pro Text", "Helvetica Neue", Helvetica, Arial, sans-serif`. The system font shows while Root Sans loads.
- Apps: `Font.root(.body)` and friends in `ios/Sources/RootSans.swift`, shared by iPhone, Mac and watch. Sizes come from the system text styles, so Dynamic Type still works.
- Words and headings: bold, tight tracking, large. Definitions: regular. Labels: small, uppercase, secondary text color.
- No monospace anywhere in the interface.

## Layout
Built like an Apple app, from constraints, not by eye.

- **The 8 point grid.** Every gap is 4, 8, 12, 16, 24, 32 or 48. Side margins 20, the reading column 680. Respect the safe areas on a phone.
- **Controls are 48 points tall**, capsules, the search field and the pickers alike. Focus is a 4 point ring of the accent at 30 percent, never a thin colored border.
- **One set of radii.** Cards 28, inset grouped lists 20, controls fully round, the icon 22 percent.
- **Type scale** is San Francisco's: 34 for the word, 22 for the app name, 17 for definitions, 15 for labels and the tagline, 13 for captions. Line height is always a step of 4.
- **Lists are inset grouped**, as in Settings: rows 12 by 16, a hairline between them inset 16 from the start edge, no outer borders on the rows.
- One column. The word is the largest thing on the screen.

## Material
Liquid glass: the result card, the search field and the pickers are semi-transparent, blurred and brightened behind, with a bright 1 point top edge and a soft shadow. The word's photo shows through. A soft scrim at the top keeps the header readable on any photo. The photo loads only if it relates to the definition (Nice the city is not "nice"); otherwise the flat per-word tint stays. No gradients on the page, only in the icon.

## Motion
The tint eases over a second when the word changes, the photo fades in over 0.6 seconds, and focus eases in over 0.2. Nothing else moves. Reduced motion turns all of it off.

## Changing it
Change `tokens.css` first, then the Swift and Kotlin values to match. Never invent a new color in a single screen.
