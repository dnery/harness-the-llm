# Image Processing CLI Benchmark

This benchmark captures headless WebKit screenshots of three dense public websites, asks multiple coding-oriented LLM CLIs to parse each screenshot into the same JSON shape, and then asks Codex `hi` to compare the raw outputs against page-specific rubrics.

## Targets

| ID | URL | Why it is useful |
| --- | --- | --- |
| `wikipedia_us` | `https://en.wikipedia.org/wiki/United_States` | Dense article layout with side navigation, table of contents, infobox, lead text, links, citations, and small typography. |
| `github_trending` | `https://github.com/trending` | Developer-oriented listing with repository cards, filters, metadata, icons, counts, and repeated visual structure. |
| `mdn_css_grid` | `https://developer.mozilla.org/en-US/docs/Web/CSS/Guides/Grid_layout/Basic_concepts` | Documentation page with global nav, sidebars, article body, code blocks, diagrams/images, breadcrumbs, and section hierarchy. |

The rubrics intentionally emphasize screenshot-grounded extraction: visible regions, text hierarchy, table/list/card reconstruction, visual evidence, and uncertainty handling. They do not require exact values for content that changes over time.

## Run

Install the local Playwright dependency first:

```fish
pnpm install --frozen-lockfile
pnpm exec playwright install webkit
```

```fish
benchmarks/image-processing/run-image-benchmark.fish
```

Generated artifacts are written to `benchmarks/image-processing/runs/<timestamp>/` by default:

- `screenshots/*.png`
- `raw/*.md`
- `logs/*.log`
- `image-processing-report.md`
- `final-assessment.md`

Useful dry paths:

```fish
benchmarks/image-processing/run-image-benchmark.fish --skip-models
benchmarks/image-processing/run-image-benchmark.fish --skip-capture --output-dir benchmarks/image-processing/runs/latest-manual
benchmarks/image-processing/run-image-benchmark.fish --dry-run
benchmarks/image-processing/run-image-benchmark.fish --only-target github_trending --skip-models --yes
benchmarks/image-processing/run-image-benchmark.fish --only-command codex_hi --skip-capture --output-dir benchmarks/image-processing/runs/latest-manual --yes
```

## Assumptions

- `fish`, `node`, `pnpm`, `codex`, `gemini`, and `claude` are installed and authenticated.
- Codex has config profiles named `spark` and `hi`.
- Claude Opus 4.7 high-resolution image support is automatic for that model; the script uses `--model claude-opus-4-7 --effort high`.
- The default suite launches 18 independent background jobs. Because that exceeds the configured threshold of 12, use `--yes` for unattended runs or confirm interactively.

## Notes

- Headless WebKit screenshots avoid desktop focus stealing and do not include browser chrome.
- Capture settings, target URLs, ready selectors, command IDs, and the background-job confirmation threshold live at the top of `run-image-benchmark.fish`.
- The script uses CSS zoom to pack more page data into each capture deterministically.
- Capture jobs run in parallel, then model jobs run in parallel, then final assessment runs once.
- The raw extraction prompt requires JSON only. Codex additionally receives `schemas/screenshot-extraction.schema.json` through `--output-schema`.
- Per-job status files are written to `status/*.status`; failed, empty, or malformed model outputs are referenced from the report as raw artifacts instead of hidden or embedded inline.
