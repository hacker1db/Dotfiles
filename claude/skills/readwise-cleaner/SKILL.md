---
name: readwise-cleaner
description: "Clean YouTube items in Readwise Reader by archiving Shorts and correcting video categories, or perform either requested cleanup. Use for Reader cleanup, not general inbox triage or YouTube recommendations."
---

# Readwise Cleaner

Clean only the requested operations. General YouTube cleanup includes Shorts archival and RSS video recategorization. Read `references/cleanup.md` before execution and follow `../readwise-cli/references/access-patterns.md`.

Choose one route per operation before mutation. A supported authenticated connector is preferred; a local script is a fallback only for that operation. Do not run a script after the connector has already completed its work. After partial or unknown outcomes, inspect current state and resume only unresolved IDs through a route supporting that scope.

Process Shorts before recategorization because both operations can touch RSS documents. Preserve unrelated tags and metadata. Read all pages before claiming complete coverage.

Report documents scanned, Shorts found and confirmed archived, videos confirmed recategorized, errors, and uncertain outcomes. The bundled wrappers can return success after failed fetches; an exit code alone does not establish complete coverage.
