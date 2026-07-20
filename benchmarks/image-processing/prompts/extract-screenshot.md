# Screenshot Extraction Task

You are parsing a screenshot for an image-processing benchmark. Inspect only the provided screenshot and do not use outside knowledge to fill gaps. If the screenshot is partially occluded, cropped, still loading, or too small to read, report that explicitly.

Return exactly one JSON object. Do not wrap it in Markdown. Do not include commentary outside the JSON.

## Required behavior

- Be deterministic and conservative.
- Prefer visible evidence over inference.
- Preserve exact visible text when legible; use `null` when unreadable.
- Use approximate percentage bounding boxes where helpful: `[x, y, width, height]`, each from `0` to `100`.
- Rank content by visual prominence and practical importance, not by DOM order.
- Distinguish navigation, repeated cards/lists, tables, article content, media, ads, dialogs, and browser chrome if visible.
- Mark uncertainty locally instead of burying it in a generic caveat.

## Output shape

```json
{
  "schema_version": "image-processing-benchmark/v1",
  "target_id": "string",
  "page_identity": {
    "site": "string|null",
    "page_title": "string|null",
    "visible_url_or_domain": "string|null",
    "confidence": 0.0
  },
  "viewport": {
    "browser_chrome_visible": true,
    "apparent_scroll_position": "top|middle|bottom|unknown",
    "major_occlusions": ["string"],
    "legibility": "excellent|good|mixed|poor"
  },
  "layout_regions": [
    {
      "id": "string",
      "label": "string",
      "role": "navigation|sidebar|article|infobox|table|card_list|code|media|ad|dialog|footer|other",
      "bbox_pct": [0, 0, 0, 0],
      "summary": "string",
      "visible_text_fragments": ["string"],
      "confidence": 0.0
    }
  ],
  "navigation": {
    "primary_items": ["string"],
    "secondary_items": ["string"],
    "search_or_filter_controls": ["string"]
  },
  "content_items": [
    {
      "rank": 1,
      "region_id": "string|null",
      "type": "heading|paragraph|card|repository|article_link|fact|stat|control|image|code|other",
      "text": "string|null",
      "numeric_values": ["string"],
      "visual_evidence": "string",
      "confidence": 0.0
    }
  ],
  "structured_data": {
    "tables": [
      {
        "title": "string|null",
        "headers": ["string"],
        "visible_rows": [
          {
            "cells": ["string"],
            "confidence": 0.0
          }
        ]
      }
    ],
    "repeated_lists": [
      {
        "title": "string|null",
        "item_type": "string",
        "items": [
          {
            "label": "string|null",
            "metadata": ["string"],
            "confidence": 0.0
          }
        ]
      }
    ]
  },
  "visual_elements": [
    {
      "type": "logo|icon|photo|illustration|diagram|chart|map|avatar|other",
      "location": "string",
      "description": "string",
      "associated_text": "string|null",
      "confidence": 0.0
    }
  ],
  "quality_flags": [
    {
      "severity": "low|medium|high",
      "issue": "string",
      "affected_regions": ["string"]
    }
  ],
  "one_sentence_summary": "string"
}
```

