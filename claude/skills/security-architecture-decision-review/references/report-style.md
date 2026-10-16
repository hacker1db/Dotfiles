# Security Architecture Review Report Style

Load this reference whenever producing the final review.

## Required order
1. Title
2. Security Architecture Review Summary metadata
3. Executive Summary
4. Logical Diagram
5. Observations
6. Recommendations
7. Scope Boundaries

## Executive summary pattern
Write as a connected narrative rather than bullets. Cover:
- Approval request and production intent
- User and system interaction model
- Data access, movement, and retention
- Existing strengths
- Controls that are planned but unvalidated
- Most material current exposure
- Duplication or alternative-path considerations only when present in the input
- Explicit review scope and exclusions
- Disposition and conditions

## Visual conventions for generated documents
- Use a dark navy title/header color.
- Use compact metadata near the top of page 1.
- Put the logical diagram before the observations.
- Use a dark navy header row for tables.
- Shade observation categories consistently:
  - Acknowledged Strength: pale green
  - Planned Control: pale blue
  - Concern (Current): white or pale gray
  - Concern (Future): white or pale gray
- In recommendations, visually emphasize priority:
  - H: amber
  - M: yellow
- Repeat the document title in the page header and include page numbers in the footer when the output format supports them.
- Prefer a concise three- to five-page review. Do not add pages merely to meet a target length.

## Content discipline
- Do not treat vendor claims or planned controls as validated facts.
- Explicitly state when a classification limit or policy statement is not technically enforced.
- State whether the reviewed access model inherits existing source-system permissions and oversharing when supported by the input.
- Distinguish data that remains in the source system from results copied or retained elsewhere.
- State whether the review covers user-delegated, human-directed use, application permissions, agents, or unattended operation.
