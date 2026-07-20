# Benchmark Assessment Task

You are judging raw screenshot extraction outputs against the benchmark rubrics. Use the rubrics as the expected behavior, and evaluate only what each model actually wrote. Do not give credit for plausible facts that are missing from the raw output.

If the benchmark report references raw outputs as artifacts instead of embedding them inline, read those artifact files before scoring the corresponding model/target pair.

## Scoring

Use a 100-point score per model per target:

- Page identity and viewport state: 10
- Layout segmentation and region roles: 20
- OCR accuracy for important visible text: 20
- Structured reconstruction of tables/lists/cards/code: 20
- Visual element recognition and association: 10
- Uncertainty handling and screenshot-grounded discipline: 10
- JSON/schema discipline and machine usability: 10

Penalize hallucinated off-screen content, invented exact numbers, missing major regions, malformed JSON, and refusal to inspect the image. Reward clear local uncertainty and useful approximate geometry.

## Output format

Write Markdown with this exact section structure:

```markdown
# Final Performance Assessment

## Executive Ranking

| Rank | Model | Mean score | Why |
| --- | --- | ---: | --- |

## Per-Target Scores

### <target_id>

| Model | Score | Strengths | Misses |
| --- | ---: | --- | --- |

## Model Notes

### <model_id>

<One short paragraph describing consistent behavior across targets.>

## Method Caveats

<Short bullets for benchmark limitations, screenshot variability, and any outputs that could not be parsed.>
```
