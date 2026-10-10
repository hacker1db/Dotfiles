# Output Format, Decision Rules, and Quality Checklist

Load this reference whenever producing the final review or when applying observation, recommendation, or diagram rules.

## Decision rules

- Prefer a constrained role plus specific assignment capability over broad Owner-style access.
- Prefer resource or workload scope over subscription, tenant, or global scope.
- Prefer multiple bounded workload identities over one high-blast-radius deployer identity when duties or resource domains differ.
- Prefer managed identity or workload identity federation over stored client secrets when supported.
- Treat authentication, minimum necessary authorization, and security-relevant audit logging as default minimum-control candidates.
- Do not equate compliance with sufficient security. Translate policy obligations into technical controls.
- Do not accept deadlines as proof that a risky design is necessary. Document the constraint and provide a minimum viable secure path.
- Do not invent standards, policies, owners, evidence, dates, or risk acceptance.
- Do not describe an individual employee's performance, intent, attitude, or competence.

## Output format

Use the structure, sequencing, and review style below. The default response is markdown. If the user requests a PDF or Word deliverable, preserve the same structure and visual hierarchy in the generated document.

```markdown
# [Solution or Product] - Security Architecture Review

## Security Architecture Review Summary

| Field | Value |
|---|---|
| **Submission** | [Solution or product name] |
| **Review Date** | [Use a date only when supplied or explicitly requested] |
| **Status** | [Approved / Conditionally Approved / Not Approved / More Information Required] |

## Executive Summary
[Write a concise narrative covering: what approval is requested; how the solution works; what data, identities, and systems are involved; the most material strengths and concerns; what remains unimplemented or unvalidated; the scope limits of the review; and the final disposition with the conditions required before enablement.]

## Logical Diagram
[When sufficient architecture information is available, include or generate a logical diagram showing users, clients, application or service, identity provider, downstream systems, trust boundaries, numbered flows, and data-retention locations. If no diagram can be produced in the requested medium, provide a Mermaid flowchart.]

> This diagram was created as a visual aid for this review. It is not part of the application or project documentation and may not be maintained regularly.

## Observations

| Obs. Type | Observation | Follow-up |
|---|---|---|
| Acknowledged Strength | [Validated positive control or architectural property] | N/A or recommendation number |
| Planned Control | [Control described but not yet implemented or validated] | Recommendation number |
| Concern (Current) | [Current material gap or inherited exposure] | Recommendation number |
| Concern (Future) | [Expansion path or future-state risk outside current approval] | Separate review required or recommendation number |

## Recommendations

| # | Priority | Assigned | Recommendation |
|---:|:---:|---|---|
| 1 | H | [Accountable team or owner] | [Finite, testable action and required evidence] |
| 2 | M | [Accountable team or owner] | [Finite, testable action and required evidence] |

## Scope Boundaries
- **In scope:** [Explicitly reviewed use cases, components, identities, and data paths]
- **Out of scope:** [Agents, unattended operation, other connectors, future applications, or functionality not evaluated]
- **Separate review triggers:** [Changes that invalidate or expand the current approval]
```

## Status mapping

Map the internal disposition to the report status as follows:
- **Approve** → **Approved**
- **Approve with conditions** → **Conditionally Approved**
- **Time-bound exception** → **Conditionally Approved**, with the exception owner, expiration, milestones, monitoring, and closure criteria stated in the executive summary and recommendations
- **Do not approve** → **Not Approved**
- **More information required** → **More Information Required**

## Observation rules

- Use only these types: **Acknowledged Strength**, **Planned Control**, **Concern (Current)**, and **Concern (Future)**.
- Record only validated positive properties as acknowledged strengths.
- Treat controls described but not implemented or evidence-tested as planned controls, not strengths.
- Give every current concern a numbered recommendation unless the concern is explicitly accepted by an accountable risk owner.
- Mark expansion paths outside the reviewed implementation as concerns for the future and require a separate review when appropriate.
- Keep each observation to one clear architectural point.

## Recommendation rules

- Number recommendations sequentially so observations can reference them.
- Use **H** for controls required before enablement or approval conditions.
- Use **M** for important follow-up controls that may be completed after approval when an acceptable interim state exists.
- Do not use **L** unless the user explicitly asks for low-priority advisory items.
- Name the accountable function or owner in **Assigned**. Use **Unassigned** when the input does not establish ownership.
- Make every recommendation finite, testable, and evidence-oriented.
- Include monitoring for changes when permissions, write capabilities, roles, integrations, or platform functionality can drift.

## Diagram rules

For a logical diagram, show only architecture supported by the supplied material. Include where applicable:
1. User sign-in or initiating actor
2. Authentication and delegated or application authorization
3. Service or connector invocation
4. Calls to downstream systems
5. Returned content or action result
6. Data retained outside the source system
7. Trust boundaries and tenant boundaries

Do not invent missing components or flows. Label uncertainty and evidence gaps outside the diagram.

## Writing style

- Lead with the decision and practical path forward.
- Use direct, business-friendly language supported by technical reasoning.
- Keep the executive summary brief; put detail in tables.
- State the security outcome, not merely the preferred implementation.
- Distinguish mandatory requirements from recommendations.
- Use "must" only for minimum requirements; use "should" for improvements.
- When evidence is uncertain, say what is known, what is missing, and how to validate it.

## Quality checklist

Before responding, confirm:
- The review is based only on supplied material.
- The central decision is explicit.
- The minimum control set is small and testable.
- Broad permissions and hidden privilege paths are called out.
- The target state and acceptable interim state are separated.
- Exceptions are time-bound and accountable.
- The output gives the delivery team a realistic path to yes.
