# Eval: `github_trending`

## Expected screenshot understanding

The output should identify GitHub Trending or a GitHub Explore/Trending repositories page. It should recognize repeated repository listing cards and developer metadata rather than treating the page as a generic article or dashboard.

## High-value regions

- GitHub global header with logo, navigation, search box, sign-in/sign-up controls, or account controls.
- Explore/Trending page heading and short explanation.
- Repository/developer toggle tabs.
- Language and spoken-language filters.
- Repeated repository cards/list rows, each with owner/name, description, language color, star/fork counts, stars today, and sponsor/avatar icons when visible.
- Any modal, menu, cookie banner, or loading overlay that blocks content.

## Content expectations

- Extract the visible top repositories in order, preserving owner/name pairs when legible.
- Capture metadata as structured repeated-list items, not freeform prose only.
- Separate filter controls from repository results.
- Identify icons and color chips as metadata indicators, not as standalone content.
- If GitHub shows a signed-in state, feedback dialog, search overlay, or menu instead of the normal trending list, the output should report that viewport state and evaluate what is actually visible.

## Common failure modes to penalize

- Hallucinating currently trending repositories that are not visible.
- Missing counts or merging stars/forks/stars-today into one ambiguous number.
- Treating the navigation mega-menu as the main content if it is merely open in the screenshot.
- Omitting filter controls and tabs.
- Returning an unstructured summary instead of ordered repository items.

