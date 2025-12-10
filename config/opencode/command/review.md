---
description: Structured code review
agent: reviewer
---
Analyze the staged git changes focusing on correctness, security, performance, clarity, maintainability, and style.
Provide structured findings with: severity (critical|high|medium|low|info), category, file:line, concise title, rationale, and actionable recommendation.
Highlight any potential secrets or unsafe patterns. Suggest concrete diff patches where fixes are clear.
Be concise. Acknowledge good practices briefly. Conclude with overall assessment and top 3 risks.
