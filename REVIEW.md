# Review guidance

Report a finding only when it identifies a concrete defect, violated requirement, or meaningful maintenance problem. Include the evidence, impact, and a realistic triggering scenario. A defect can depend on a specific input and still be worth reporting.

Skip personal naming preferences, equivalent implementations, speculative abstractions, and formatting already enforced by tooling. Do not invent a minimum number of findings or a mandatory “top risks” list.

Prioritize authorization and trust boundaries, secret handling, data integrity, safe configuration replacement and symlinking, installer idempotency, and the macOS and shell compatibility guarantees documented by the repository.

“These two paths apply different authorization checks, allowing this path to bypass the restriction” is actionable. “Extract this function” is not actionable without evidence of a defect or meaningful maintenance cost.

Read the repository instructions, compare the exact pull-request head to its verified base, inspect affected callers, and verify findings against tests or reproducible behavior. Follow-up passes should verify fixes and new regressions without reopening settled preferences. Stop when no evidence-backed findings remain.
