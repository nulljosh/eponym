#!/bin/sh
# ponytail: compose the Pages site. The web app is the root, the marketing page is /about,
# and /app stays alive as a redirect for old links.
set -e
cd "$(dirname "$0")/.."
# The i18n bundles are generated; a stale one ships strings that no longer match the catalog.
python3 scripts/gen-i18n.py --check
rm -rf dist && mkdir -p dist/about dist/app
cp -R web/. dist/
cp -R landing/. dist/about/
cp landing/robots.txt landing/sitemap.xml landing/og.png dist/
printf '<!doctype html><meta charset="utf-8"><title>Wordroot</title><link rel="canonical" href="/"><meta http-equiv="refresh" content="0;url=/">' > dist/app/index.html
rm -rf dist/.vercel dist/.wrangler dist/.env.local
echo "built dist/ (app at /, about at /about)"
