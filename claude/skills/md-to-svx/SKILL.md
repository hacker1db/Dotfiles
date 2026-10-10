---
name: md-to-svx
description: "Convert a vault blog draft to a local hacker1db.dev mdsvex file when the user requests .svx conversion or preparation for that blog."
---

# Markdown to SVX Converter

Convert Obsidian vault blog posts (`.md`) to mdsvex-compatible `.svx` files for the hacker1db.dev SvelteKit blog.

Before converting, read `$HOME/.config/blog/hacker1db-voice.md` for the SVX frontmatter schema and blog repo layout.

## Source & Destination

- **Source**: `$HOME/notes/SecondBrain/2.Areas/Personal Home/Blog Posts 🕸/`
- **Blog repo**: `$HOME/Developer/side-code/web-hacker1db/` (bare repo with worktrees)
- **Find active worktree**: `find "$HOME/Developer/side-code/web-hacker1db" -maxdepth 2 -name "svelte.config.js"`
- **Output**: `{worktree}/content/posts/{Category}/{slug}.svx`

## Workflow

1. Locate source file (partial name match; ask if multiple)
2. Find active SvelteKit worktree
3. Transform frontmatter (Obsidian → SVX schema)
4. Convert Obsidian syntax (wikilinks, embeds, callouts, comments)
5. Determine output category from `series` frontmatter
6. Generate kebab-case slug from title
7. Write `.svx` file; show transformation summary
8. Post-conversion checklist (images to copy, stripped embeds, draft status)

The existing `--publish` flag prepares the local file by setting `draft: false`; it does not deploy or publish the site. Set this flag only when requested or already authorized, and report the local readiness state accurately. A live publishing request also needs the repository deployment workflow and its authorization. Do not claim that conversion alone made the post live.

See `references/conversion-guide.md` for frontmatter mapping and syntax conversion rules.
