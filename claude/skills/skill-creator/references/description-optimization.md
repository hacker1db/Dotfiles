# Skill Creator — Description Optimization

The description field is the primary mechanism that determines whether Claude invokes a skill. Optimize it after the skill is working well.

## How Triggering Works

Skills appear in Claude's `available_skills` list with name + description. Claude decides whether to consult a skill based on that description alone.

**Key insight:** Claude only consults skills for tasks it can't easily handle itself. Simple one-step queries ("read this PDF") may not trigger even with a perfect description. Complex, multi-step, or specialized queries reliably trigger when description matches.

## Step 1: Generate Trigger Eval Queries

Create 20 queries — mix of should-trigger and should-not-trigger. Save to `trigger-eval.json`:

```json
[
  { "query": "the user prompt", "should_trigger": true },
  { "query": "another prompt", "should_trigger": false }
]
```

**Should-trigger (8–10 queries):** Different phrasings of the same intent — formal and casual. Include cases where the user doesn't name the skill but clearly needs it. Include uncommon use cases.

**Should-not-trigger (8–10 queries):** Near-misses that share keywords but need something different. Adjacent domains, ambiguous phrasing where a naive keyword match would trigger but shouldn't.

**Make them realistic and detailed** — include file paths, job context, column names:

Bad: `"Extract text from PDF"`
Good: `"ok so i have this scanned lease agreement my landlord sent (lease_scan_final.pdf) and i need to pull out all the dates and dollar amounts — can you help"`

Avoid obviously irrelevant negative examples — they don't test anything.

## Step 2: Review Eval Set with User

1. Read the HTML template from `assets/eval_review.html`
2. Replace `__EVAL_DATA_PLACEHOLDER__` with the JSON array
3. Replace `__SKILL_NAME_PLACEHOLDER__` and `__SKILL_DESCRIPTION_PLACEHOLDER__`
4. Write to `/tmp/eval_review_<skill-name>.html` and open it
5. User edits queries, toggles should-trigger, clicks "Export Eval Set"
6. Check `~/Downloads/` for `eval_set.json` (may be `eval_set (1).json`)

## Step 3: Run the Optimization Loop

```bash
python -m scripts.run_loop \
  --eval-set <path-to-trigger-eval.json> \
  --skill-path <path-to-skill> \
  --model <model-id-from-system-prompt> \
  --max-iterations 5 \
  --verbose
```

Use the model ID from your system prompt — triggering must be tested against what the user actually runs.

The loop:
1. Splits eval set 60% train / 40% held-out test
2. Evaluates current description (3 runs each for reliability)
3. Proposes improved descriptions based on failures
4. Re-evaluates on both train and test
5. Repeats up to 5 iterations
6. Returns `best_description` selected by **test score** (not train) to avoid overfitting

Periodically `tail` the output to report progress to the user.

## Step 4: Apply the Result

Take `best_description` from the JSON output. Update the skill's `SKILL.md` frontmatter. Show the user before/after and report the scores.
