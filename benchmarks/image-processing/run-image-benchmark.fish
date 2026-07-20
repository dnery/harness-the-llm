#!/usr/bin/env fish

set -g script_dir (dirname (realpath (status --current-filename)))
set -g repo_root (realpath "$script_dir/../..")
set -g prompt_file "$script_dir/prompts/extract-screenshot.md"
set -g assessment_prompt_file "$script_dir/prompts/assess-results.md"
set -g schema_file "$script_dir/schemas/screenshot-extraction.schema.json"
set -g capture_helper "$script_dir/capture-webkit.mjs"

# All generated artifacts live below one timestamped run directory so a benchmark
# can be inspected, re-used with --skip-capture, or deleted as a unit.
set -g output_dir "$script_dir/runs/"(date -u "+%Y%m%dT%H%M%SZ")

# This benchmark intentionally launches every independent capture/model job it
# can. The threshold is a human-safety rail, not a concurrency knob: if the job
# count is surprisingly high, the script asks before spending API/browser work.
set -g max_background_jobs_without_confirmation 12

# Headless WebKit capture defaults. The viewport mirrors the previously validated
# maximized Safari viewport, while deviceScaleFactor=2 preserves retina-grade OCR
# detail. css_zoom packs more page content without relying on browser UI zoom.
set -g viewport_width 1676
set -g viewport_height 1059
set -g device_scale_factor 2
set -g css_zoom 0.8
set -g capture_timeout_ms 45000
set -g capture_settle_ms 3000

# Screenshot targets are intentionally declared as parallel arrays so adding or
# removing a page is a small top-of-file edit. ready_selectors should point at a
# stable visible element that proves the dense content area is actually present.
set -g target_ids wikipedia_us github_trending mdn_css_grid
set -g target_names "Wikipedia - United States" "GitHub Trending" "MDN CSS Grid Basic Concepts"
set -g target_urls \
    "https://en.wikipedia.org/wiki/United_States" \
    "https://github.com/trending" \
    "https://developer.mozilla.org/en-US/docs/Web/CSS/Guides/Grid_layout/Basic_concepts"
set -g target_eval_files \
    "$script_dir/evals/wikipedia_us.md" \
    "$script_dir/evals/github_trending.md" \
    "$script_dir/evals/mdn_css_grid.md"
set -g target_ready_selectors \
    "h1#firstHeading" \
    "article.Box-row" \
    "main h1"

# Model command IDs are the public benchmark dimensions. The implementation for
# each ID lives in run_model_command; keeping the IDs and labels here makes it
# obvious which tools are benchmarked and what --only-command accepts.
set -g command_ids codex_spark codex_hi gemini_flash_lite gemini_pro claude_opus_4_7
set -g command_labels \
    "Codex CLI profile spark" \
    "Codex CLI profile hi" \
    "Gemini CLI gemini-3.1-flash-lite-preview" \
    "Gemini CLI gemini-3.1-pro-preview" \
    "Claude Code opus 4.7 high effort"

set -g skip_capture 0
set -g skip_models 0
set -g dry_run 0
set -g assume_yes 0
set -g only_target ""
set -g only_command ""

function usage
    echo "Usage: "(status filename)" [options]"
    echo
    echo "Options:"
    echo "  --output-dir DIR       Write run artifacts to DIR."
    echo "  --skip-capture         Reuse screenshots already present in output-dir/screenshots."
    echo "  --skip-models          Capture screenshots and assemble a report skeleton only."
    echo "  --dry-run              Print the resolved job plan without running jobs."
    echo "  --yes                  Bypass the background-job confirmation prompt."
    echo "  --only-target ID       Run one screenshot suite."
    echo "  --only-command ID      Run one model command across selected targets."
    echo "  -h, --help             Show this help."
end

while test (count $argv) -gt 0
    switch $argv[1]
        case --output-dir
            if test (count $argv) -lt 2
                echo "Missing value for --output-dir" >&2
                exit 2
            end
            set output_dir $argv[2]
            set -e argv[1..2]
        case --skip-capture
            set skip_capture 1
            set -e argv[1]
        case --skip-models
            set skip_models 1
            set -e argv[1]
        case --dry-run
            set dry_run 1
            set -e argv[1]
        case --yes
            set assume_yes 1
            set -e argv[1]
        case --only-target
            if test (count $argv) -lt 2
                echo "Missing value for --only-target" >&2
                exit 2
            end
            set only_target $argv[2]
            set -e argv[1..2]
        case --only-command
            if test (count $argv) -lt 2
                echo "Missing value for --only-command" >&2
                exit 2
            end
            set only_command $argv[2]
            set -e argv[1..2]
        case -h --help
            usage
            exit 0
        case '*'
            echo "Unknown option: $argv[1]" >&2
            usage >&2
            exit 2
    end
end

function require_command --argument-names command_name
    if not command -q "$command_name"
        echo "Missing required command: $command_name" >&2
        return 1
    end
end

function ensure_prereqs
    set -l missing 0
    for command_name in fish node pnpm codex gemini claude
        if not require_command "$command_name"
            set missing 1
        end
    end

    if test "$missing" -ne 0
        return 1
    end

    if not test -f "$repo_root/node_modules/playwright/package.json"
        echo "Missing local Playwright install. Run: pnpm install" >&2
        return 1
    end
end

function index_of --argument-names needle
    set -l haystack $argv[2..-1]
    for idx in (seq (count $haystack))
        if test "$haystack[$idx]" = "$needle"
            echo $idx
            return 0
        end
    end
    return 1
end

function selected_target_indices
    if test -n "$only_target"
        set -l idx (index_of "$only_target" $target_ids)
        or begin
            echo "Unknown target: $only_target" >&2
            return 1
        end
        echo $idx
        return 0
    end

    seq (count $target_ids)
end

function selected_command_indices
    if test -n "$only_command"
        set -l idx (index_of "$only_command" $command_ids)
        or begin
            echo "Unknown command: $only_command" >&2
            return 1
        end
        echo $idx
        return 0
    end

    seq (count $command_ids)
end

function write_status --argument-names status_file job_status phase id exit_code detail
    printf "status=%s\nphase=%s\nid=%s\nexit_code=%s\ndetail=%s\n" "$job_status" "$phase" "$id" "$exit_code" "$detail" > "$status_file"
end

function validate_json_output --argument-names out_file
    node -e '
const fs = require("fs");
const file = process.argv[1];
let text = fs.readFileSync(file, "utf8").trim();
const fenced = text.match(/^```(?:json)?\s*([\s\S]*?)\s*```$/);
if (fenced) text = fenced[1].trim();
JSON.parse(text);
' "$out_file" >/dev/null 2>&1
end

function build_target_prompt --argument-names target_id target_name target_url eval_file out_file
    printf "# Target\n\n" > "$out_file"
    printf "target_id: %s\n" "$target_id" >> "$out_file"
    printf "target_name: %s\n" "$target_name" >> "$out_file"
    printf "target_url: %s\n\n" "$target_url" >> "$out_file"
    printf "# Extraction Instructions\n\n" >> "$out_file"
    string collect < "$prompt_file" >> "$out_file"
    printf "\n\n# Page-Specific Eval Rubric\n\n" >> "$out_file"
    string collect < "$eval_file" >> "$out_file"
end

function run_capture_job --argument-names target_id target_url ready_selector screenshot log_file status_file
    pnpm --dir "$repo_root" exec node "$capture_helper" \
        --target-id "$target_id" \
        --url "$target_url" \
        --output "$screenshot" \
        --ready-selector "$ready_selector" \
        --viewport-width "$viewport_width" \
        --viewport-height "$viewport_height" \
        --device-scale-factor "$device_scale_factor" \
        --css-zoom "$css_zoom" \
        --timeout-ms "$capture_timeout_ms" \
        --settle-ms "$capture_settle_ms" > "$log_file" 2>&1

    set -l exit_code $status
    if test "$exit_code" -eq 0; and test -s "$screenshot"
        write_status "$status_file" ok capture "$target_id" 0 "$screenshot"
    else
        write_status "$status_file" failed capture "$target_id" "$exit_code" "$log_file"
    end
end

function run_model_command --argument-names command_id target_prompt screenshot out_file log_file
    switch "$command_id"
        case codex_spark
            codex exec --profile spark --cd "$repo_root" --sandbox read-only --skip-git-repo-check --color never --output-schema "$schema_file" --output-last-message "$out_file" -i "$screenshot" - < "$target_prompt" > "$log_file" 2>&1
        case codex_hi
            codex exec --profile hi --cd "$repo_root" --sandbox read-only --skip-git-repo-check --color never --output-schema "$schema_file" --output-last-message "$out_file" -i "$screenshot" - < "$target_prompt" > "$log_file" 2>&1
        case gemini_flash_lite
            set -l prompt_text (string collect < "$target_prompt")
            set prompt_text "$prompt_text

Read the screenshot image at this exact path with the file-reading tool, then return the JSON object only:
$screenshot
"
            gemini --model gemini-3.1-flash-lite-preview --prompt "$prompt_text" --include-directories "$output_dir" --approval-mode plan --skip-trust --output-format text > "$out_file" 2> "$log_file"
        case gemini_pro
            set -l prompt_text (string collect < "$target_prompt")
            set prompt_text "$prompt_text

Read the screenshot image at this exact path with the file-reading tool, then return the JSON object only:
$screenshot
"
            gemini --model gemini-3.1-pro-preview --prompt "$prompt_text" --include-directories "$output_dir" --approval-mode plan --skip-trust --output-format text > "$out_file" 2> "$log_file"
        case claude_opus_4_7
            set -l prompt_text (string collect < "$target_prompt")
            set prompt_text "$prompt_text

Read the screenshot image at this exact path, then return the JSON object only:
$screenshot
"
            claude --print --model claude-opus-4-7 --effort high --permission-mode plan --tools Read --add-dir "$output_dir" --output-format text "$prompt_text" > "$out_file" 2> "$log_file"
        case '*'
            echo "Unknown command id: $command_id" >&2
            return 2
    end
end

function run_model_job --argument-names command_id target_id target_prompt screenshot out_file log_file status_file
    run_model_command "$command_id" "$target_prompt" "$screenshot" "$out_file" "$log_file"
    set -l exit_code $status

    if test "$exit_code" -ne 0
        write_status "$status_file" failed model "$target_id/$command_id" "$exit_code" "$log_file"
    else if not test -s "$out_file"
        write_status "$status_file" empty model "$target_id/$command_id" 0 "$out_file"
    else if validate_json_output "$out_file"
        write_status "$status_file" ok model "$target_id/$command_id" 0 "$out_file"
    else
        write_status "$status_file" malformed model "$target_id/$command_id" 0 "$out_file"
    end
end

function launch_and_wait --argument-names phase
    set -l pids $argv[2..-1]

    for pid in $pids
        wait $pid
        or true
    end

    set -l failed_statuses (rg -l '^status=(failed|empty|malformed)$' "$output_dir/status" 2>/dev/null)
    if test (count $failed_statuses) -gt 0
        echo "$phase completed with non-ok statuses:"
        for status_file in $failed_statuses
            echo "  $status_file"
        end
    end
end

function append_status_file --argument-names status_file report_path
    if test -f "$status_file"
        string collect < "$status_file" | string replace -a "|" "\\|" | string replace -r '^([^=]+)=(.*)$' '| $1 | $2 |' >> "$report_path"
    else
        printf "| missing | %s |\n" "$status_file" >> "$report_path"
    end
end

function read_job_status --argument-names status_file
    if not test -f "$status_file"
        echo missing
        return 0
    end

    set -l status_line (string match -r '^status=.*' < "$status_file" | head -n 1)
    if test -z "$status_line"
        echo unknown
    else
        string replace 'status=' '' -- "$status_line"
    end
end

function append_raw_artifact_row --argument-names command_id target_id report_path
    set -l raw_rel "raw/$target_id.$command_id.md"
    set -l log_rel "logs/$target_id.$command_id.log"
    set -l status_rel "status/$target_id.$command_id.status"
    set -l job_status (read_job_status "$output_dir/$status_rel")

    printf "| `%s` | `%s` | `%s` | `%s` | `%s` |\n" "$command_id" "$job_status" "$raw_rel" "$log_rel" "$status_rel" >> "$report_path"
end

function compose_report --argument-names report_path
    printf "# Image Processing Benchmark Report\n\n" > "$report_path"
    printf "- Generated: %s\n" (date -u "+%Y-%m-%dT%H:%M:%SZ") >> "$report_path"
    printf "- Output directory: `%s`\n" "$output_dir" >> "$report_path"
    printf "- Viewport: `%sx%s`, device scale factor `%s`, CSS zoom `%s`\n\n" "$viewport_width" "$viewport_height" "$device_scale_factor" "$css_zoom" >> "$report_path"

    printf "## Job Status\n\n" >> "$report_path"
    printf "### Capture Jobs\n\n" >> "$report_path"
    for idx in $selected_targets
        set -l target_id $target_ids[$idx]
        printf "#### %s\n\n" "$target_id" >> "$report_path"
        printf "| Key | Value |\n| --- | --- |\n" >> "$report_path"
        append_status_file "$output_dir/status/$target_id.capture.status" "$report_path"
        printf "\n" >> "$report_path"
    end

    printf "### Model Jobs\n\n" >> "$report_path"
    for idx in $selected_targets
        set -l target_id $target_ids[$idx]
        for command_idx in $selected_commands
            set -l command_id $command_ids[$command_idx]
            printf "#### %s / %s\n\n" "$target_id" "$command_id" >> "$report_path"
            printf "| Key | Value |\n| --- | --- |\n" >> "$report_path"
            append_status_file "$output_dir/status/$target_id.$command_id.status" "$report_path"
            printf "\n" >> "$report_path"
        end
    end

    printf "## Models\n\n" >> "$report_path"
    printf "| Model ID | CLI invocation |\n| --- | --- |\n" >> "$report_path"
    printf "| `codex_spark` | `codex exec --profile spark -i <screenshot>` |\n" >> "$report_path"
    printf "| `codex_hi` | `codex exec --profile hi -i <screenshot>` |\n" >> "$report_path"
    printf "| `gemini_flash_lite` | `gemini --model gemini-3.1-flash-lite-preview` |\n" >> "$report_path"
    printf "| `gemini_pro` | `gemini --model gemini-3.1-pro-preview` |\n" >> "$report_path"
    printf "| `claude_opus_4_7` | `claude --model claude-opus-4-7 --effort high` |\n\n" >> "$report_path"

    for idx in $selected_targets
        set -l target_id $target_ids[$idx]
        set -l target_name $target_names[$idx]
        set -l target_url $target_urls[$idx]
        set -l screenshot "$output_dir/screenshots/$target_id.png"
        set -l eval_file $target_eval_files[$idx]

        printf "## Target: `%s`\n\n" "$target_id" >> "$report_path"
        printf "- Name: %s\n" "$target_name" >> "$report_path"
        printf "- URL: %s\n" "$target_url" >> "$report_path"
        printf "- Screenshot: `%s`\n\n" "$screenshot" >> "$report_path"

        printf "### Rubric\n\n" >> "$report_path"
        string collect < "$eval_file" >> "$report_path"
        printf "\n\n### Raw Result Artifacts\n\n" >> "$report_path"
        printf "Raw model outputs are stored as separate artifacts so generated Markdown or fenced blocks cannot corrupt this report's structure.\n\n" >> "$report_path"
        printf "| Command | Status | Raw artifact | Log artifact | Status artifact |\n| --- | --- | --- | --- | --- |\n" >> "$report_path"

        for command_idx in $selected_commands
            set -l command_id $command_ids[$command_idx]
            append_raw_artifact_row "$command_id" "$target_id" "$report_path"
        end
    end
end

function run_final_assessment --argument-names report_path assessment_path log_file
    set -l prompt_text (string collect < "$assessment_prompt_file")
    set prompt_text "$prompt_text

Read and assess this benchmark report, including rubrics, job statuses, and the raw model output artifacts referenced in each target's Raw Result Artifacts table:
$report_path
"

    printf "%s\n" "$prompt_text" | codex exec --profile hi --cd "$repo_root" --sandbox read-only --skip-git-repo-check --color never --output-last-message "$assessment_path" - > "$log_file" 2>&1
end

set -g selected_targets (selected_target_indices); or exit 1
set -g selected_commands (selected_command_indices); or exit 1

set -l capture_job_count 0
set -l model_job_count 0
if test "$skip_capture" -eq 0
    set capture_job_count (count $selected_targets)
end
if test "$skip_models" -eq 0
    set model_job_count (math (count $selected_targets) "*" (count $selected_commands))
end
set -l total_background_jobs (math "$capture_job_count + $model_job_count")

echo "Run directory: $output_dir"
echo "Targets: "(string join ", " $target_ids[$selected_targets])
echo "Commands: "(string join ", " $command_ids[$selected_commands])
echo "Background jobs: $total_background_jobs ($capture_job_count capture, $model_job_count model)"

if test "$total_background_jobs" -gt "$max_background_jobs_without_confirmation"
    echo "This exceeds max_background_jobs_without_confirmation=$max_background_jobs_without_confirmation"
end

if test "$dry_run" -eq 1
    echo "Dry run only; no files were created and no jobs were launched."
    exit 0
end

if test "$total_background_jobs" -gt "$max_background_jobs_without_confirmation"; and test "$assume_yes" -eq 0
    if not isatty stdin
        echo "Refusing to launch $total_background_jobs background jobs without --yes because stdin is not interactive." >&2
        exit 2
    end

    read -l answer -P "Launch $total_background_jobs background jobs? Type yes to continue: "
    if test "$answer" != yes
        echo "Cancelled."
        exit 2
    end
end

ensure_prereqs; or exit 1

mkdir -p "$output_dir/screenshots" "$output_dir/raw" "$output_dir/logs" "$output_dir/prompts" "$output_dir/status"

for idx in $selected_targets
    set -l target_id $target_ids[$idx]
    set -l target_name $target_names[$idx]
    set -l target_url $target_urls[$idx]
    set -l eval_file $target_eval_files[$idx]
    set -l target_prompt "$output_dir/prompts/$target_id.prompt.md"

    if not test -f "$eval_file"
        echo "Missing eval file: $eval_file" >&2
        exit 1
    end

    build_target_prompt "$target_id" "$target_name" "$target_url" "$eval_file" "$target_prompt"
end

set -l capture_pids
if test "$skip_capture" -eq 0
    echo "Launching capture jobs"
    for idx in $selected_targets
        set -l target_id $target_ids[$idx]
        run_capture_job "$target_id" "$target_urls[$idx]" "$target_ready_selectors[$idx]" "$output_dir/screenshots/$target_id.png" "$output_dir/logs/$target_id.capture.log" "$output_dir/status/$target_id.capture.status" &
        set -a capture_pids $last_pid
    end
    launch_and_wait capture $capture_pids
else
    for idx in $selected_targets
        set -l target_id $target_ids[$idx]
        set -l screenshot "$output_dir/screenshots/$target_id.png"
        if not test -s "$screenshot"
            echo "Missing reusable screenshot for --skip-capture: $screenshot" >&2
            exit 1
        end
        write_status "$output_dir/status/$target_id.capture.status" ok capture "$target_id" 0 "$screenshot"
    end
end

if test "$skip_models" -eq 0
    for idx in $selected_targets
        set -l target_id $target_ids[$idx]
        if not rg -q '^status=ok$' "$output_dir/status/$target_id.capture.status"
            echo "Skipping model jobs for $target_id because capture did not succeed." >&2
            continue
        end
    end

    echo "Launching model jobs"
    set -l model_pids
    for idx in $selected_targets
        set -l target_id $target_ids[$idx]
        if not rg -q '^status=ok$' "$output_dir/status/$target_id.capture.status"
            continue
        end
        for command_idx in $selected_commands
            set -l command_id $command_ids[$command_idx]
            run_model_job "$command_id" "$target_id" "$output_dir/prompts/$target_id.prompt.md" "$output_dir/screenshots/$target_id.png" "$output_dir/raw/$target_id.$command_id.md" "$output_dir/logs/$target_id.$command_id.log" "$output_dir/status/$target_id.$command_id.status" &
            set -a model_pids $last_pid
        end
    end
    launch_and_wait model $model_pids
else
    for idx in $selected_targets
        set -l target_id $target_ids[$idx]
        for command_idx in $selected_commands
            set -l command_id $command_ids[$command_idx]
            write_status "$output_dir/status/$target_id.$command_id.status" skipped model "$target_id/$command_id" 0 "--skip-models"
        end
    end
end

set -l report_path "$output_dir/image-processing-report.md"
compose_report "$report_path"

if test "$skip_models" -eq 0
    set -l assessment_path "$output_dir/final-assessment.md"
    echo "Running final Codex hi assessment"
    if run_final_assessment "$report_path" "$assessment_path" "$output_dir/logs/final-assessment.codex_hi.log"
        printf "\n" >> "$report_path"
        string collect < "$assessment_path" >> "$report_path"
    else
        printf "\n# Final Performance Assessment\n\nCodex hi assessment failed. See `%s`.\n" "$output_dir/logs/final-assessment.codex_hi.log" >> "$report_path"
        echo "Final assessment failed; see logs" >&2
    end
else
    printf "\n# Final Performance Assessment\n\nSkipped because --skip-models was set.\n" >> "$report_path"
end

echo "Report: $report_path"
