---
name: md-to-svx
description: "Convert Obsidian markdown blog posts to .svx files for the hacker1db.dev SvelteKit blog. Use this skill when the user wants to convert markdown to svx, publish a blog post from Obsidian, move content from the vault to the blog, or convert .md to .svx. Triggers on 'publish post', 'convert post', 'svx', 'push to blog', 'convert to svx', 'publish to blog'."
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

Add `--publish` flag to set `draft: false` and show `git diff --stat`.

See `references/conversion-guide.md` for frontmatter mapping and syntax conversion rules.
