# Eponym Money

How Eponym makes money. The company plan is `REVENUE.md` in the Code root; the ledger is `GTM.md`.

## Price and rail

$0.99 upfront on the App Store (ASC 6794988021). Apple keeps 15%, so each sale pays about $0.84. The web version stays free. The web is the trial and the store is the checkout.

## What is actually sold

The app: the etymology tree, saved words, the widget and the offline dictionary. The word data comes from Wiktionary under CC BY-SA. That means credit and share-alike. The risk is a license obligation on the data, not the price.

## Who pays and why

A word lover or writer who wants to see where a word came from, keep a tree of its relatives, and have the whole dictionary offline. They pay once.

## Cost to serve

No paid API found in the app or the pipeline. The pipeline is Python with only the standard library, reading Wiktionary. The REST and MCP functions run on Cloudflare. Hosting is Cloudflare, with no paid service behind it.

## Where we are

- 2026-10-28: renamed from Wordroot to Eponym. The Pages project, host and bundle ID keep the old name on purpose.
- 2026-11-01: version 2.0.1 was submitted. The store listing says Eponym from that version.
- Revenue: no verified number (the App Store Connect key cannot read sales yet).

## Role in the company plan

Catalogue. GTM.md lists it as a $0.99 app that is free on the web. It serves Stage 0 as one more proof that a dollar sells, and under Stage 2 it either earns a place on the grid or is retired.

## Next

Once 2.0.1 is live under the Eponym name, read the first month of store sales.

## Million, billion, trillion

**A million.** Eponym is the dictionary a million word lovers pay for once, with the etymology tree offline.

**A billion.** Eponym is the word reference on every Jaybulb device, the tool people open first when a word puzzles them.

**A trillion.** Eponym is the etymology layer under every reading app on the platform, and the Wiktionary credit travels with it.

## Change it

`asc pricing schedule create --app 6794988021 --price 0.99 --base-territory USA --start-date YYYY-MM-DD`. Swap `--price 0.99` for `--free` to revert. No build, no review. Only with Joshua's yes in chat.

Anyone who got Eponym while it was free keeps it free.

*ASC 6794988021. Verified 2026-11-02.*
