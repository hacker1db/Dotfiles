# Cleanup routes and contracts

## Connector route

Discover Reader listing, tag addition, movement, and metadata tools by their schemas. Paginate video and RSS categories. Match the parsed source URL hostname to `youtube.com` or a subdomain, and path `/shorts/` for Shorts; do not trust a title or an arbitrary URL containing that string.

For nonarchived Shorts, add `youtube-shorts` while retaining other tags, then move to archive, in batches supported by the active schema. If tag addition succeeds but movement fails, retry only the move after reading state.

For recategorization, list RSS documents at `new`, `later`, or `feed`. Select YouTube documents and update only `category` to `video` where the schema supports it. Preserve location. Finish Shorts archival first so archived Shorts are excluded. If category writes are unsupported, select the recategorization script before attempting writes.

## Script fallback

Inspect the scripts and dependencies before use:

```
~/.dotfiles/bin/remove-shorts.sh
~/.dotfiles/bin/recategorize.sh
```

Each requires an authenticated `readwise` CLI and `jq`. Run only the script for the operation not performed through the connector. If both are needed, run Shorts first, then recategorization. These scripts scan broad categories and have no verified ID restriction; do not use them to resume a partially executed connector operation. Their URL matching is broader than the connector procedure, so inspect candidates and ensure the selected script fits the authorized scope before running it. Prefer the connector when precise scope is needed.

These wrappers suppress some errors and may convert failed page retrieval into an empty page. Treat warnings, missing results, or interrupted pagination as incomplete coverage, even if exit status is zero. Verify changed state and counts where feasible; never report all documents processed solely from the wrapper's final message.
