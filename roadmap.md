# Wordroot Roadmap

## Shipping 2026-08-27, 1.0.1 (build 7)
Carries the 2026-08-19 code pass: Wiktionary XSS fix, CC BY-SA attribution, network-error state, first test target.
Both **submitted for review 2026-08-27**, build 7 attached, `asc validate` clean on both:
- iOS version `80723e06-c65e-4cb3-b3c6-0348694a3cba`, submission `cef226ca-9d6a-4d9b-84db-3ead8bb1b86d`
- macOS version `f2db9266-ea8f-4b41-ad5d-97fa64520bba`, submission `b9e6fdfe-5110-4873-b464-89dac0b50c33`

Note: `asc xcode export` cannot export a macOS archive (it insists on a `.ipa` path and then errors when
xcodebuild produces a `.pkg`). Use raw `xcodebuild -exportArchive` with the plist asc leaves behind, then
`asc builds upload --pkg` with explicit `--version` and `--build-number`.

## LIVE 2026-08-27
iOS 1.0 and macOS 1.0 are both READY_FOR_SALE on the App Store (id 6794988021).
Next version picks up the 2026-08-19 code pass (XSS fix, attribution, network errors, tests), needs a version bump.

App Store record: **Wordroot** (app id 6794988021, bundle `com.heyitsmejosh.etyma`, Apple-locked, keeps the old name)
Repo: `nulljosh/wordroot` · folder `~/Documents/Code/wordroot` (renamed from etyma 2026-08-11)
Web: https://wordroot.heyitsmejosh.com (Cloudflare Pages project renamed from `etyma` to `wordroot` 2026-08-28)

## Done 2026-08-19, code pass (no version bump)

Read the whole codebase; four real defects, all fixed and pushed (`e47ff05`), web deployed.

- **XSS in `web/index.html` (the one that mattered).** `Nothing found for "${word}"` took raw
  user input into `innerHTML`, and `strip` was a single-pass regex, so a definition containing
  `<<img>img src=x onerror=y>` came out as a live tag. Wiktionary is publicly editable, which
  made that stored XSS, not just self-XSS. Definitions now go through `DOMParser`
  (inert, decodes entities too) and every interpolation is escaped.
- **Wiktionary attribution added to the app.** CC BY-SA 4.0 requires it and App Review flags
  uncredited third-party content. The web page always had it; the app never did.
- **Network failure was invisible.** It rendered as "Nothing found.", and on launch, where the
  query is empty, as a *completely blank list*. `Wiktionary.entry` now throws on transport
  failure with its own view branch. Note for future edits: do **not** use `try?` there, it
  flattens `Entry??` and re-merges the two cases.
- **User-Agent set on native requests.** Wikimedia may throttle or 403 generic agents. Browsers
  forbid setting it on `fetch`, so the web app cannot comply, commented in place.

Also: extracted the parser into a pure `Wiktionary.chain(fromWikitext:)` and added the repo's
**first test target** (`ios/Tests/`, 4 offline cases, `xcodebuild test` green on macOS; iOS and
macOS both still build). xcodegen emits an iOS-shaped `TEST_HOST`, so the target pins
`$(BUILT_PRODUCTS_DIR)/Wordroot.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/Wordroot` to work on both.
Deleted `web/data.json` and `web/.vercel/` (both dead), synced the three language tables.

Version and build numbers untouched on purpose, iOS 1.0 is in review, macOS 1.0 staged behind it.
These land in the next version.

## Done 2026-08-18, freeze lifted
- iOS 1.0 **submitted** 18:36 UTC (review submission `a114741b-2723-4774-838f-26e522be1dd9`, WAITING_FOR_REVIEW).
- macOS 1.0 (`c1fced5e-70bc-435d-8c4f-de4de91229bb`) is `asc validate` clean, 0 errors, 0 warnings,
  0 blocking, with build `6` attached. Held for the iOS verdict, never submitted as a batch.

## Ship state 2026-08-17 (build 4, name mismatch fixed)
iOS 1.0 is **submission-ready and now carries the right app name**. `asc validate` returns 0 errors /
0 warnings / 1 info (the known unverifiable App-Privacy advisory).

**Caught this pass:** the attached build was build 1, uploaded 2026-07-29, *before* the 08-11
Etyma→Wordroot rename (`e10d481`). The target has no `CFBundleDisplayName` override and
`PRODUCT_NAME = $(TARGET_NAME)`, so that binary installed on the home screen as **"Etyma"** while the
App Store listing says **"Wordroot"**. Submitting it risked a name-mismatch rejection, a bad bet on an
account already under a 5.6 Code of Conduct suspension.

Fixed: bumped `CURRENT_PROJECT_VERSION` 3 → 4, regenerated with xcodegen, archived + uploaded
**build 4** (`f10786f8-b4a5-41d1-9441-a6b4c4fcd516`, `CFBundleName = Wordroot`), verified
`COMPLETE`/`VALID`/exempt via `asc builds uploads list`, and attached it to version 1.0.
Version state: `PREPARE_FOR_SUBMISSION`, no pending submission.

### Ship state 2026-08-11 (superseded above)
Done that pass:
- content rights, copyright, categories (REFERENCE / EDUCATION), age rating (all NONE + profanity INFREQUENT_OR_MILD, a dictionary surfaces vulgar entries)
- en-US description / keywords / support + marketing URL / subtitle / privacy URL
- review details (no demo account), build 037486c9 attached, encryption compliance = exempt
- screenshots: iPhone 6.5" ×3, iPad Pro 12.9" ×2
- pricing schedule (free) + availability in all territories
- App Privacy published as DATA_NOT_COLLECTED
- full Etyma → Wordroot rename (app target, sources, site, docs, repo, folder, portfolio link)

### macOS 1.0, SUBMITTED 2026-08-24 (Waiting for Review)
Build 6 uploaded and `VALID` (`66ee9cf2-3e63-4637-a737-c3e1c7023c9a`), attached to version 1.0
(`c1fced5e-...`). `asc validate --platform MAC_OS` returns
0 errors / 0 warnings / 1 info (the known unverifiable App-Privacy advisory; privacy IS published).
**Submitted 2026-08-24**, review submission `8d0968b2-e4a6-4510-a0d8-e450015eed14`,
`MAC_OS WAITING_FOR_REVIEW`. `asc review submit` failed with *"review submission ... does not
contain target version"*, the known false negative; the submission already held 1 item in
`READY_FOR_REVIEW` (item id decodes `<uuid>|6|888885871`, the same `|6|` type mislabel), so
`asc review submissions-submit --id 8d0968b2-... --confirm` completed it. The Program License
Agreement was NOT blocking. Both platforms are now Waiting for Review.

**ITMS-90242 is cleared, and the old diagnosis in this file was wrong.** The previous note blamed
the development signing cert. It was actually the **missing `LSApplicationCategoryType`**: build 5,
uploaded 2026-08-18 with the signing already corrected, still failed 90242 with
*"The Info.plist must contain a LSApplicationCategoryType key"*, the identical message build 3 had
returned. Two independent defects, only one of which was diagnosed:

1. **Missing app category (the actual 90242 blocker).** Fixed with
   `INFOPLIST_KEY_LSApplicationCategoryType: public.app-category.reference` in `ios/project.yml`
   (matches the REFERENCE primary category on the listing). This was the real gate all along.
2. **Development signing cert (real, but not what 90242 was reporting).** The archive is still
   signed `Apple Development`, that is fine and expected. The distribution identity is applied at
   **export time only**, via `ios/.asc/MacExportOptions.plist`:
   `signingCertificate` = `3rd Party Mac Developer Application`,
   `installerSigningCertificate` = `3rd Party Mac Developer Installer`.
   Verified by expanding the exported .pkg and running `codesign -dvvv` on the app inside:
   `Authority=3rd Party Mac Developer Application: Joshua Trommel (QMM486NPYC)`.

**Do NOT use the manual-signing route this file previously suggested.** Setting
`CODE_SIGN_STYLE: Manual` + `PROVISIONING_PROFILE_SPECIFIER` fails at archive time with
*"profile is Xcode managed, but signing settings require a manually managed profile"*, the only Mac
App Store profile for `com.heyitsmejosh.etyma` is Xcode-managed. Export-side certificate pinning is
the smaller and working fix. (`asc signing fetch --profile-type MAC_APP_STORE` cannot create a
manual one either: it dies on a stale ASC profile reference, `no resource of type 'profiles' with
id '9WQ42C7UYH'`, worth cleaning up in ASC someday, not blocking.)

**Mac screenshots are no longer blocked.** 1 shot at exactly 1280x800 uploaded and `COMPLETE`
(`e252c417-...`), at `screenshots/appstore/mac/en-US/01-word-of-the-day.png`. Captured with **zero
synthetic input**, so the standing no-UI-scripting preference is respected:
- `defaults write com.heyitsmejosh.etyma "NSWindow Frame Wordroot.ContentView-1-AppWindow-1" "300 125 1280 800 0 0 1920 1050 "`
  (the key name is discoverable by launching once and running `defaults read`, a guessed
  `NSWindow Frame main` is ignored)
- `killall cfprefsd`, relaunch, resolve the window id with a small CoreGraphics script, then
  `screencapture -l<id> -o -x`. Lands at 1280x800 with no rescaling.

**The "vulgar word-of-the-day" worry was overstated.** The word is deterministic , 
`wotd[Int(Date().timeIntervalSince1970/86400) % 25]` in `WordrootApp.swift:119`. Today resolved to
**"name"**, which renders cleanly and happens to show the etymology chain (name -> nama -> *namo ->
*namo -> *h,nomn), the app's actual differentiator. No search input was needed. If a future capture
lands on "mother", just compute the index and shoot on a day that does not.

- [ ] Ship the watch app: bump to 1.1.0 once iOS 1.0.5 clears review, upload the iOS build (watch app inside), add Apple Watch screenshots, submit
- [ ] More Mac screenshots (only 1 uploaded; the listing is thin). Needs the search path driven, so
      it is the one thing here still wanting a non-synthetic input route.
      **Not a submit blocker**, confirmed 2026-08-24: the single 1280x800 shot was enough,
      macOS 1.0 submitted fine. This is a post-approval listing improvement.

## Done 2026-08-28, infrastructure finalized
- Added official App Store badge to the landing page (hero + CTA, linking to apps.apple.com/us/app/wordroot/id6794988021)
- Migrated Cloudflare Pages project from `etyma` to `wordroot` (new project, deployed dist/, moved domain via API, DNS repointed to wordroot-4kt.pages.dev, old etyma project deleted)
- Landing page fully verified at wordroot.heyitsmejosh.com

## Backlog
- [ ] Full Wiktionary dump parse still pending (v1 uses the live REST API instead), large scoped feature, needs its own session

> Resume note (2026-08-11, triaged 2026-08-17): the `wip: partial work from /work notes ingest` commit
> (`765356f`) is **landing-page only**, `landing/index.html`, `landing/icon.svg`, `scripts/build-site.sh`,
> `.gitignore`. It touches no iOS source, so it is not a ship risk and did not affect build 4. It is pushed
> (`main` == `origin/main`), contrary to the old note. Still unreviewed as web work, needs its own pass.

## 2026-08-24, both platforms in review, not live yet
iOS 1.0 Waiting for Review (submitted 2026-08-18); **macOS 1.0 Waiting for Review (submitted
2026-08-24)**. The landing page exists. No action left but waiting on both verdicts.

(Supersedes the 2026-08-23 note, which said macOS was still staged.)

## WebMCP + REST API rollout -- shipped 2026-08-27

Done. 3 read-only tools: `lookup_word`, `get_etymology`, `get_word_of_the_day`. Nothing gated -- nothing is stored or mutated.

See `docs/API.md` for the full tool table, linked from the README.

## /api + /mcp surface, SHIPPED 2026-08-31

Live at `wordroot.heyitsmejosh.com/api` and `/mcp`. Tools: `lookup_word`, `get_definitions`,
`get_etymology`, `list_languages`. Both surfaces call `callTool()` in `src/lib/tools.js`.

The D1-vs-JSON question that blocked this was the wrong question: neither. Wiktionary is the
dataset and the app already reads it live from the browser, so the Function does too, the
server just adds a real User-Agent and CORS-free access. `pipeline/wordroot.sqlite` stays a
build-time artifact. Revisit storage when a rate limit or a latency measurement asks for it.

## TUI pilot (2026-09-05)
- `wordroot-tui` SwiftPM target (SwiftTUI). `swift build && ./.build/debug/wordroot-tui etymology` fetches the live `/api/word/:word` and renders definitions + etymology chain as a terminal card. Needs a real TTY.

## Ingested 2026-10-01
- [x] Refresh App Store screenshots.
- [ ] Wordroot QA (Apple Note 2026-10-01 said only "Wordroot QA"). Which platform, full feature pass or a specific bug?

## Ingested 2026-10-05
- [ ] QA

## Ingested 2026-10-16
- [x] Stale App Store screenshots (blank icon in listing). (screenshot: notes/attachments/2026-10-16/app-store-screenshots-4.png)

## Open 2026-10-16
- [x] Fix the eight failing web-app tests in scripts/test-web.mjs (2026-10-28: the stub DOMParser had no querySelectorAll). They were failing before the 2026-10-16 landing change and that change did not touch them.

## Ingested 2026-10-25
- [ ] Needs a better name. (Probe Apple first, one name everywhere.)
  Name hunt 2026-10-28: one real single word only, never two words glued together. Probed on the 1.0.6 draft
  (Wordroot's own record while a draft is editable, else ASC_PROBE_APP=6825014407 Oohaah, all REJECTED), about 360 tried. Joshua said no to Forebear, Varro, Rootward (compound).
  Free but not picked: Nirukta, Eponym, Wherefore, Yaska, Ishtiqaq, Paronym, Sememe, Toponym, Exonym, Endonym, Anent, Erstwhile, Dictio, Purport, Denotation, Philologist, Lexicology, Lexiphile, Etymologer, Cognatus, Rooter, Etymonic, Exordium, Nascent, Tamarisk, Totara, Galangal, Chicory, Alkanet, Ordet, Sloka, Lexeis, Glottal, Primeval, Glossator, Provenience, Etymologist, Ancient, Atavism, Archaism, Relict, Cognomen, Isidore, Progenitor, Begetter, Stirps, Proles, Onomast, Rhizoid, Etymic, Juuri, Skeat.
  Taken (skip): Rhizome Etymon Taproot Cognate Radix Stemma Lexeme Etyma Provenance Banyan Acorn Racine Raiz
  Verba Lingua Lexis Origo Genus Lexicon Glossa Kernel Rhiza Arche Onoma Sema Radicle Fons Loam Linden Aspen
  Cedar Mycelium Babel Rosetta Grimm Proto Runic Ogham Rune Argot Quill Vellum Saga Idiom Lingo Scribe Cadmus
  Ogma Nabu Thoth Seshat Carmenta Bragi Calliope Gloss Rubric Genesis Origin Seed Stem Sprig Germ Fount
  Radical Vocable Locution Dictum Logion Grapheme Syllable Annals Chronicle Archive Tome Folio Canto Primal Ancestry
  Lexical Semantic Philology Heritage Pedigree Relic Fossil Amber Strata Spore Graft Scion Progeny Clade Genome
  Ord Mot Wort Slovo Sana Parola Palabra Kalima Davar Logos Verbe Woord Lexi Kotoba Parole Langue Verbatim Rhema Sprache Taal
  Mandrake Orris Madder Ginseng Mesquite Kauri Ficus Burdock Turmeric Lotus Iris Bamboo Ginger Cypress Tamarind Acacia Sassafras Parsnip Taro Cassava Yam
  Derivative Fountain Source Spring Seedling Sprout Nucleus Primus Alpha Omega Incipit Proem Prologue Preface Overture Prelude Dawn Aurora Inception
  Lexis Logophile Linguist Glossary Thesaurus Dictionary Morphology Semantics Syntax Grammar Rhetoric Eloquence Cognition Legend Fable Myth Tale Clan Tribe Dynasty
  Root Roots Mimir Urd Norn Yggdrasil Bodhi Shoresh Koren Mula Dhatu Nomen Vox Sermo Gens Spoor Sleuth Stolon Genos Archon Mythos Lexikon Littera Tabula Wortel Kindling Trace Thread Scent
  Whence Yore Olden Erst Bygone Asl Doublet Calque Neologism Beech Birch Elm Oak Ash Rowan Hence Thence Hither
  Verity Candor Lucid Clarity Gist Essence Crux Core Pith Marrow Nub Quintessence Substance Meaning Sense Notion Concept Idea Term
  Rooted Logic Verbal Mnemo Memento Muse Oracle Sibyl Augur Herald Envoy Courier Emissary Scholar Savant Sage Pundit Erudite Maven Polymath Codex Scroll Parchment Papyrus
  Philter Tincture Elixir Distill Ferment Leaven Yeast Brine Tannin Resin Sap Bark Xylem Phloem Cambium Burl Knot Ring Bole Trunk Limb Bough Twig Frond.

## 2.0.0 submitted 2026-10-28
iOS (with the watch app and widget inside) and Mac 2.0.0, build 202610281345, both WAITING_FOR_REVIEW, release on approval. New screenshots for iPhone 6.9 and 6.5, iPad 13 and 12.9, Apple Watch; the Mac listing still shows the 1.0.2 shot (fresh Mac shots are a follow-up). Name stays Wordroot.
- [ ] Fresh Mac App Store screenshots
- [ ] iOS Action extension: look up text selected in any app
- [ ] Watch word of the day uses its own list; move it to Catalog.wordsOfTheDay so phone, watch and widget agree

## Gap matrix vs the best dictionary apps (2026-10-28, /mobbin)
From the App Store screens of Etymonline, EtymologyExplorer, Merriam-Webster, Oxford, American Heritage, Terminology, WordWeb, Collins, Chambers and Wiktionary Reader. Daily use first, polish before novelty, on-device over cloud. One row is one minor version, shipped on iOS, Mac and web together. 1.1.0 stays reserved for the watch app.

| Ver | Gap | Who has it | Size | Status |
|---|---|---|---|---|
| 1.2 | Recent searches and saved words, one tap from the search field | every one of them | S | [x] 2026-10-28 |
| 1.3 | Pronunciation: IPA under the word and a speak button (on-device voice) | Merriam-Webster, Oxford, American Heritage, EtymologyExplorer | S | [x] 2026-10-28 |
| 1.4 | Suggestions while typing (Wiktionary prefix search; native search suggestions on Apple) | Oxford, American Heritage, Etymonline | M | [x] 2026-10-28 |
| 1.5 | Root tree: the chain drawn as a tree, tap any ancestor to open it (its Wiktionary entry for now) | Etymonline charts, EtymologyExplorer, American Heritage IE chart | M | [x] 2026-10-28 |
| 1.6 | Same-root words: other words that come from this word's root (Wiktionary search on the {{root}} template, else the oldest ancestor) | Etymonline related entries, EtymologyExplorer descendants | M | [x] 2026-10-28 |
| 1.7 | Random word button (bottom bar; English list grew from 25 to 192 words) | EtymologyExplorer, Terminology | S | [x] 2026-10-28 |
| 1.8 | Word of the day, with a Home Screen widget (small and medium, iPhone and Mac, opens the word via wordroot://word/) | Merriam-Webster, Oxford, EtymologyExplorer, Etymonline trending | M | [x] 2026-10-28 |
| 1.9 | Look up from other apps: App Intent for Shortcuts, Siri and Spotlight; Services menu on the Mac; ?q= links and OpenSearch on the web. An iOS Action extension for selected text is still to do | Terminology | M | [x] 2026-10-28 |
| 1.10 | Prefixes and suffixes index (-logy, bio-, anti-): 93 curated English affixes at the foot of the home screen | Etymonline | M | [x] 2026-10-28 |
| 1.11 | Offline: every word you looked up opens without a connection (web: service worker word cache, newest 600; Apple: 200 MB URLCache with a cache-only retry) | Oxford, Merriam-Webster, Terminology | M | [x] 2026-10-28 |

Skipped on purpose: quizzes and word games, paywalled extra dictionaries, AI chat, ads.
