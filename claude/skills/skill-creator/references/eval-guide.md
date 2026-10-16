# Skill Creator — Eval Guide

## evals.json Schema

Save at `evals/evals.json` within the skill workspace.

```json
{
  "skill_name": "example-skill",
  "evals": [
    {
      "id": 1,
      "prompt": "User's realistic task prompt",
      "expected_output": "Description of expected result",
      "files": ["evals/files/sample.pdf"],
      "assertions": [
        "The output is a .docx file",
        "The document contains a table with 3 columns",
        "The heading 'Executive Summary' appears on page 1"
      ]
    }
  ]
}
```

## Writing Good Test Prompts

Test prompts should be realistic — what a real user would actually say. Include:
- File paths and names
- Personal context (job role, situation)
- Column names, company names, URLs where relevant
- Mix of lengths, some with typos or casual phrasing

**Bad:** `"Format this data"`
**Good:** `"my boss sent me quarterly_sales_v2_FINAL.xlsx and wants profit margin added as a column — revenue is col C, costs are col D"`

## Writing Good Assertions

Assertions must be **objectively verifiable** — not subjective quality judgments.

**Bad:** `"The document looks professional"`
**Good:** `"The document contains a table of contents"` or `"The output file has extension .docx"`

Good assertion names are descriptive — someone glancing at the benchmark should immediately understand what each one checks.

Subjective skills (writing style, design quality) don't need assertions — focus on qualitative human review instead.

## Running Evals

Spawn with-skill AND baseline subagents **in the same turn** (in parallel):

**With-skill prompt:**
```
Execute this task:
- Skill path: <path-to-skill>
- Task: <eval prompt>
- Input files: <files or "none">
- Save outputs to: <workspace>/iteration-N/eval-<ID>/with_skill/outputs/
- Outputs to save: <what the user cares about>
```

**Baseline prompt** (same task, no skill, save to `without_skill/outputs/`).

## grading.json Schema

```json
{
  "expectations": [
    {
      "text": "The output includes the name 'John Smith'",
      "passed": true,
      "evidence": "Found in step 3: 'Extracted names: John Smith, Sarah Johnson'"
    }
  ],
  "summary": { "passed": 2, "failed": 1, "total": 3, "pass_rate": 0.67 }
}
```

Field names must be exactly `text`, `passed`, `evidence` (not `name`/`met`/`details`).

## Aggregating Results

```bash
python -m scripts.aggregate_benchmark <workspace>/iteration-N --skill-name <name>
```

Produces `benchmark.json` and `benchmark.md` with pass_rate, time, and tokens for each configuration.

## Generating the Eval Viewer

```bash
# In Cowork (no display) — write static HTML
python eval-viewer/generate_review.py <workspace>/iteration-N \
  --skill-name "my-skill" \
  --benchmark <workspace>/iteration-N/benchmark.json \
  --static /tmp/review.html

# Iteration 2+: add previous workspace
python eval-viewer/generate_review.py <workspace>/iteration-2 \
  --previous-workspace <workspace>/iteration-1 \
  --static /tmp/review.html
```

**Always generate the viewer before making your own improvements.** Get it in front of the human first.

## Analyst Pass

After aggregating, look for:
- Assertions that always pass in both configurations (non-discriminating)
- High-variance evals (possibly flaky or model-dependent)
- Time/token tradeoffs — is the skill worth the overhead?
- Patterns in what the skill helps with vs. doesn't
