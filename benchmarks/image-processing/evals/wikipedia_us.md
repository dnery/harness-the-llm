# Eval: `wikipedia_us`

## Expected screenshot understanding

The output should identify a Wikipedia article page for "United States" or a close visible equivalent. It should recognize this as an encyclopedia article, not a generic search results page or news site.

## High-value regions

- Browser chrome or address area if visible.
- Wikipedia global header with logo/search/personal tools.
- Left-side table of contents or navigation rail when visible.
- Main article title and lead article body.
- Right-side country infobox with flag, emblem, map, or dense fact rows if visible.
- Top article tabs/actions such as article/talk/read/edit/view history/tools when visible.
- Inline links, citation markers, pronunciation/alternate names, and high-density typography.

## Content expectations

- Capture the page title and at least several lead facts visible in the screenshot.
- Preserve visible infobox labels and values when legible, especially items like capital, largest city, official language, government, population, area, currency, calling code, or date facts.
- Reconstruct the infobox as table-like structured data when visible.
- Recognize that the page has many language links and navigation links without treating them as the primary article content.
- Note citation superscripts and link styling as evidence of an encyclopedia article.

## Common failure modes to penalize

- Inventing facts from prior knowledge instead of visible text.
- Ignoring the infobox or flattening it into a prose summary.
- Confusing the table of contents with the article body.
- Missing the distinction between browser UI, Wikipedia site navigation, and article content.
- Claiming exact values that are too small or blurry to read.

