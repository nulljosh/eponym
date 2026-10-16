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
# Stamp the scripts with a content hash so a browser never pairs new HTML with an old bundle.
V=$(cat web/i18n.js web/webmcp.js | md5 -q | cut -c1-8)
sed -i '' "s#src=\"i18n.js\"#src=\"i18n.js?v=$V\"#; s#src=\"webmcp.js\"#src=\"webmcp.js?v=$V\"#" dist/index.html
VL=$(md5 -q landing/i18n.js | cut -c1-8)
sed -i '' "s#src=\"i18n.js\"#src=\"i18n.js?v=$VL\"#" dist/about/index.html
VF=$(cat web/fonts/*.woff2 | md5 -q | cut -c1-8)
sed -i '' -E "s#(WordrootSans-(Regular|Bold)\.woff2)\)#\1?v=$VF)#g" dist/index.html dist/about/index.html
rm -rf dist/.vercel dist/.wrangler dist/.env.local
echo "built dist/ (app at /, about at /about)"
