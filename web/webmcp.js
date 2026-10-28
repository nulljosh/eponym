// WebMCP tool registration for Eponym. Exposes read-only lookup tools to any
// agent that supports the WebMCP `document.modelContext` API, so an agent can
// look up words in any of the supported languages, pull etymology chains, or read
// the word of the day without scraping the page. All logic lives in the inline <script> in index.html —
// this file only wires window.* accessors from that script into tool calls.
//
// ponytail: no new fetch/parse logic here — every tool is a thin wrapper
// around functions the page already runs for its own UI.
(function () {
  const mc = document.modelContext;
  if (!mc?.registerTool) return;

  /** Validate an optional language code, defaulting to whatever the page is showing. */
  function resolveLanguage(code) {
    if (!code) return { code: window.eponymWordLanguage() };
    const hit = window.eponymWordLanguages().filter(l => l.code === code)[0];
    if (hit) return { code: hit.code };
    return { error: `Unknown language "${code}". Call list_languages for the supported codes.` };
  }

  const tools = [
    {
      name: 'lookup_word',
      description: 'Look up a word in Eponym: returns its definitions and etymology (ancestor chain), and also updates the on-page results so the user sees the same lookup. '
        + 'Definitions come from the reader\'s own Wiktionary edition where it has the word, otherwise the English one; definitionsLanguage says which.',
      inputSchema: {
        type: 'object',
        properties: {
          word: { type: 'string', description: 'The word to look up, e.g. "mother".' },
          language: {
            type: 'string',
            description: 'Language the word is in, as a code from list_languages (e.g. "fr"). '
              + 'Defaults to the language the page is currently set to.',
          },
        },
        required: ['word'],
      },
      execute: async ({ word, language }) => {
        if (!word || !word.trim()) return { error: 'No word given.' };
        const lang = resolveLanguage(language);
        if (lang.error) return lang;
        const w = word.trim().toLowerCase();
        const [defs, chain] = await Promise.all([
          window.eponymDefinitions(w, lang.code),
          window.eponymEtymology(w, lang.code),
        ]);
        if (!defs && !chain.length) return { error: `Nothing found for "${w}" in ${lang.code}.` };
        // Only drive the page when the agent is asking about the language it is already
        // showing; otherwise the visible results would not match what was returned.
        if (lang.code === window.eponymWordLanguage()) window.eponymLookup(w);
        return {
          word: w,
          language: lang.code,
          definitions: defs ? defs.groups : [],
          // Which Wiktionary edition wrote the glosses, and so what language they are in.
          definitionsLanguage: defs ? defs.edition : null,
          etymology: chain,
        };
      },
    },
    {
      name: 'get_etymology',
      description: 'Get just the etymology (ancestor word chain, e.g. Old English, Proto-Germanic, Proto-Indo-European) for a word, without definitions.',
      inputSchema: {
        type: 'object',
        properties: {
          word: { type: 'string', description: 'The word to trace, e.g. "water".' },
          language: {
            type: 'string',
            description: 'Language the word is in, as a code from list_languages (e.g. "la"). '
              + 'Defaults to the language the page is currently set to.',
          },
        },
        required: ['word'],
      },
      execute: async ({ word, language }) => {
        if (!word || !word.trim()) return { error: 'No word given.' };
        const lang = resolveLanguage(language);
        if (lang.error) return lang;
        const w = word.trim().toLowerCase();
        const chain = await window.eponymEtymology(w, lang.code);
        if (!chain.length) return { error: `No etymology found for "${w}" in ${lang.code}.` };
        return { word: w, language: lang.code, etymology: chain };
      },
    },
    {
      name: 'get_word_of_the_day',
      description: 'Get today\'s Eponym word of the day (stable per calendar day, no arguments needed). It is a word in the language the page is currently set to.',
      inputSchema: { type: 'object', properties: {} },
      execute: async () => {
        const word = window.eponymOfTheDay();
        const language = window.eponymWordLanguage();
        if (!word) return { error: `No word of the day for ${language}.` };
        return { word, language };
      },
    },
    {
      name: 'list_languages',
      description: 'List the languages Eponym can look words up in, and which one the page '
        + 'is currently set to. Call this before passing a language to the other tools.',
      inputSchema: { type: 'object', properties: {} },
      execute: async () => ({
        current: window.eponymWordLanguage(),
        languages: window.eponymWordLanguages().map(l => ({ code: l.code, name: l.english })),
      }),
    },
  ];

  for (const tool of tools) {
    try {
      mc.registerTool(tool);
    } catch (err) {
      console.warn(`webmcp: failed to register tool "${tool.name}"`, err);
    }
  }
})();
