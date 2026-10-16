# Architecture

Wordroot is a dictionary with etymology. Look up a word, follow its roots back through Latin, Greek and Old English to Proto-Indo-European. It runs on web, iOS, macOS, Android and desktop (Kotlin) and in a terminal. Every surface reads Wiktionary live. There is no database and no account.

12 interface languages, 30 word languages. One catalog, `i18n/strings.json`, generates the strings for every surface.

## How it runs

**Web.** The root page is the app: static HTML and JS at wordroot.jaybulb.com. It opens on "word" and, left alone for 10 seconds, types through 120 words until someone touches it. The marketing page lives at `/about`, and `/app` redirects to the root. A lookup fetches definitions from `{edition}.wiktionary.org/api/rest_v1/page/definition/{word}` (your own edition and English together, yours wins) and the wikitext from en.wiktionary.org, which is parsed for `{{inh}}`, `{{der}}` and `{{bor}}` templates. Each ancestor is looked up in turn until a root or the depth limit. Details in [API.md](API.md).

**iOS and macOS.** SwiftUI, one `WindowGroup`. Interface and word language live in `UserDefaults`. Network calls go straight to Wiktionary. Arabic flips the layout.

**Android and desktop.** Compose Multiplatform over a shared Kotlin core that mirrors the JS parsing. Desktop packages as DEB, MSI or DMG.

**Terminal.** A SwiftPM executable: `wordroot-tui etymology` prints the chain.

**Server surface.** Cloudflare Pages Functions expose the same lookup as read-only REST and MCP. Both call one function, `callTool()`, so they cannot disagree.

**Agents in the page.** `web/webmcp.js` registers the lookup tools through WebMCP so an agent on the page can use them.

## Files

### Shared logic
| File | What it owns |
|---|---|
| `src/lib/tools.js` | `callTool()`: Wiktionary lookup, etymology template parsing, language code to section mapping, input validation (100 characters, no newlines or pipes), a 10 ancestor chain limit |
| `functions/api/[[route]].js` | REST routes, thin wrappers over `callTool()` |
| `functions/mcp.js` | Stateless MCP over HTTP, JSON-RPC in and out |
| `test/tools.test.mjs` | Tests for `callTool()` and the tool surface |
| `pipeline/parse.py` | Offline Wiktionary parser to SQLite. Python stdlib only. `test_parse.py` covers it |

### Web and landing
| File | What it owns |
|---|---|
| `web/index.html` | The app: word input, two language pickers, definition and etymology panels |
| `web/webmcp.js` | WebMCP tool registration |
| `web/sw.js`, `web/manifest.webmanifest` | Offline app shell and install metadata |
| `web/privacy.html` | Privacy policy |
| `web/i18n.js`, `landing/i18n.js` | Generated from the catalog. Never hand edit |
| `landing/index.html` | Marketing page at the site root |
| `scripts/build-site.sh` | Builds `dist/`: landing at `/`, app at `/app`. Refuses to build on stale i18n |
| `scripts/gen-i18n.py` | Generates `web/i18n.js`, `landing/i18n.js` and `ios/Sources/Localized.swift` |
| `scripts/test-web.mjs` | Web app and landing tests: i18n and lookup |
| `wrangler.toml` | Pages project config. Deploy `dist/` with `wrangler pages deploy` |

### iOS and macOS
| File | What it owns |
|---|---|
| `ios/project.yml` | xcodegen spec for the iOS and macOS targets. No checked in xcodeproj |
| `ios/Sources/WordrootApp.swift` | App entry, settings, layout direction |
| `ios/Sources/Localized.swift` | Generated string tables. Never hand edit |
| `ios/Tests/EtymologyParserTests.swift` | Parser tests: template parsing and no cycles |
| `Wordroot.icon/` | Icon Composer source for the app icon. `icon.svg` is the flat copy |
| `ios/ExportOptions.plist`, `ios/Wordroot.entitlements` | Signing and export |
| `metadata/` | App Store listing text pulled with `asc` |
| `.asc/workflow.json` | `asc workflow run ship-ios` and `ship-mac`: bump, archive, export, upload, submit |

### Kotlin and terminal
| File | What it owns |
|---|---|
| `kmp/shared/` | Shared network, parsing and word languages. `WiktionaryTest.kt` covers it |
| `kmp/composeApp/` | Compose UI (`AppScreen.kt`) with Android and desktop entry points |
| `tui/main.swift`, `Package.swift` | The terminal client |
| `watchos/` | Apple Watch app: lookup, word of the day, photo backdrop. `test.sh` checks the models against the live API |

### Repo and project
| File | What it owns |
|---|---|
| `.github/workflows/test.yml` | Runs the tests on every push and pull request |
| `.github/workflows/native-release.yml` | Builds the Windows, Linux and Android binaries from `kmp/` on a `native-v*` tag |
| `launch/` | Post drafts for Product Hunt, Hacker News, Reddit and X, plus a hero image |
| `brand/` | Brand kit and design system: tokens, mark, icon, rules |
| `docs/MONEY.md`, `roadmap.md` | Pricing, and open work. `roadmap.md` and `CLAUDE.md` stay in the root because the tooling looks for them there |
| `docs/WHITEPAPER.md`, `docs/API.md` | The data pipeline, and the HTTP, MCP and WebMCP surfaces |
| `docs/CONTRIBUTING.md`, `docs/SECURITY.md`, `LICENSE` | Contributing, security contact, MIT |
| `architecture.svg`, `progress.svg` | The README diagrams |
