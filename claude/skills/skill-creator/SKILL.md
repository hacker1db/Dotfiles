---
name: skill-creator
description: "Create, improve, or evaluate skills. Triggers: build a skill, create a skill, improve this skill, test my skill."
---

# Skill Creator

Guides the full lifecycle: draft → test → review → improve → package.

## Process

1. **Capture intent** — What should the skill do? When should it trigger? What's the output format?
2. **Research & draft** — Write `SKILL.md` with YAML frontmatter. Keep body under 200 words; put details in `references/`.
3. **Write test cases** — 2–3 realistic prompts saved to `evals/evals.json`.
4. **Run evals** — Spawn with-skill and baseline subagents in parallel.
5. **Review** — Generate viewer: `python eval-viewer/generate_review.py <workspace>/iteration-N --static output.html`
6. **Improve & repeat** — Refine skill based on feedback; re-run until satisfied.
7. **Optimize description** — Run `python -m scripts.run_loop` to maximize trigger accuracy.
8. **Package** — `python -m scripts.package_skill <skill-folder>` → `.skill` file.

## References

- `references/skill-anatomy.md` — File structure, progressive disclosure, writing patterns, frontmatter fields
- `references/eval-guide.md` — Eval JSON schema, assertion writing, grading, benchmark aggregation
- `references/description-optimization.md` — Trigger eval queries, optimization loop, how triggering works
