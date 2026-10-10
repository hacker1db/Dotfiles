# Optional Reader publication

Publish only when the user has authorized saving this review to Reader in the current conversation. Prior authorization is sufficient. If it is absent, deliver the complete local draft before requesting a publishing decision.

1. Preserve the complete Markdown draft at the requested or project appropriate local destination before publication.
2. Use the authenticated Reader capability selected by the access router. Check its current schema and search for an existing review to avoid duplicates.
3. Convert the draft to supported HTML when required. Set a clear review draft title, use accurate authorship metadata, and summarize the highlight count and related sources. Preserve source links and personal TODOs.
4. Use a genuine document URL or a supported content upload mechanism. Never fabricate an internal hostname or source URL to satisfy a required field. If the connector cannot save local content without such a URL, report that limitation and retain the local draft.
5. Verify the returned document and give the user its actual Reader URL. On failure, report what failed and link the intact local draft.
